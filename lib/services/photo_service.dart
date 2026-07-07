import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 타일별 사진 촬영 및 갤러리 업로드/조회 트랜잭션을 전담 처리하는 서비스 클래스
class PhotoService {
  final SupabaseClient _client = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// 카메라를 가동하여 현장 사진을 촬영하고, 용량 절감을 위해 즉각 최적화 압축 가공을 실행합니다.
  Future<File?> captureCompressedPhoto() async {
    try {
      // imageQuality: 50(50% 압축), maxWidth: 1080(해상도 경량화)
      // 모바일 화면 렌더링에 차고 넘치며 원본 대비 용량이 1/10 수준(100~200KB 내외)으로 격감합니다.
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        imageQuality: 50,
      );

      if (photo != null) {
        return File(photo.path);
      }
    } catch (e) {
      debugPrint('❌ 사진 촬영 및 압축 가공 중 실패: $e');
    }
    return null;
  }

  /// 앨범(갤러리)에서 이미지를 불러오고, 동일한 규격으로 압축합니다.
  Future<File?> pickCompressedPhotoFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        imageQuality: 50,
      );

      if (photo != null) {
        return File(photo.path);
      }
    } catch (e) {
      debugPrint('❌ 갤러리 이미지 선택 및 압축 중 실패: $e');
    }
    return null;
  }

  /// Supabase Storage 버킷('tile-photos')에 이미지를 물리 업로드하고,
  /// 획득한 URL을 메타데이터와 결합하여 'tile_photos' 테이블에 최종 삽입합니다.
  Future<Map<String, dynamic>?> uploadTilePhoto({
    required String tileId,
    required File file,
    required String userId,
    required String userNickname,
  }) async {
    try {
      // 1. Storage 버킷에 저장할 유니크 파일 경로 이름 연산 (안전한 확장자 가드 적용)
      final String rawPath = file.path;
      final String fileExtension = rawPath.contains('.') && rawPath.split('.').last.length < 6
          ? rawPath.split('.').last.toLowerCase()
          : 'jpg';
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String storagePath = '$tileId/${userId}_$timestamp.$fileExtension';

      // 2. Storage 업로드 실행
      try {
        await _client.storage.from('tile-photos').upload(
              storagePath,
              file,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
      } catch (storageErr, stack) {
        debugPrint('❌ [PhotoService] Supabase Storage 물리 업로드 실패: $storageErr');
        debugPrint('$stack');
        if (storageErr.toString().contains('404')) {
          throw 'Supabase Storage에 \'tile-photos\' 버킷이 존재하지 않습니다. 대시보드 ➔ Storage에서 \'tile-photos\' 버킷을 생성해 주세요.';
        }
        rethrow;
      }

      // 3. 업로드 완료된 사진의 Public URL 획득
      final String photoUrl =
          _client.storage.from('tile-photos').getPublicUrl(storagePath);

      // 4. DB 테이블('tile_photos')에 행 삽입
      final Map<String, dynamic> insertData = {
        'tile_id': tileId,
        'user_id': userId,
        'user_nickname': userNickname,
        'photo_url': photoUrl,
      };

      try {
        final List<Map<String, dynamic>> response = await _client
            .from('tile_photos')
            .insert(insertData)
            .select();

        if (response.isNotEmpty) {
          debugPrint('📡 타일 사진 DB 등록 성공 (Tile: $tileId)');
          return response.first;
        }
      } catch (dbErr, stack) {
        debugPrint('❌ [PhotoService] DB 타일 사진 메타데이터 등록 실패: $dbErr');
        debugPrint('$stack');
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ [PhotoService] uploadTilePhoto 전체 예외 트래킹: $e');
      rethrow;
    }
    return null;
  }

  /// 특정 타일 ID에 등록된 모든 갤러리 사진 목록을 최신순으로 정렬해 읽어옵니다.
  Future<List<Map<String, dynamic>>> fetchPhotosForTile(String tileId) async {
    try {
      final List<Map<String, dynamic>> data = await _client
          .from('tile_photos')
          .select('id, tile_id, user_id, user_nickname, photo_url, created_at')
          .eq('tile_id', tileId)
          .order('created_at', ascending: false);

      return data;
    } catch (e) {
      debugPrint('❌ 타일 사진 목록 조회 실패 ($tileId): $e');
      return [];
    }
  }
}
