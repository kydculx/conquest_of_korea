import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_config.dart';
import '../models/tile_model.dart';

/// Supabase 외부 통신 전담 서비스 (순수 I/O 레이어)
class SupabaseService {
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        debug: kDebugMode,
      );
      debugPrint('✅ Supabase 초기화 성공');
    } catch (e) {
      debugPrint('❌ Supabase 초기화 실패: $e');
      rethrow;
    }
  }

  SupabaseClient get _client => Supabase.instance.client;

  /// 모든 점령 타일 조회
  Future<List<HexTile>> fetchAllCapturedTiles() async {
    debugPrint('🛰️ 점령 타일 데이터 요청 중...');
    final response = await _client.from('captured_tiles').select('*');
    final tiles = (response as List)
        .map((e) => HexTile.fromJson(e as Map<String, dynamic>))
        .toList();
    debugPrint('📦 ${tiles.length}개 타일 수신 완료');
    return tiles;
  }

  /// 점령 타일 실시간 스트림
  Stream<List<HexTile>> get capturedTilesStream {
    return _client
        .from('captured_tiles')
        .stream(primaryKey: ['id'])
        .map((list) => list.map(HexTile.fromJson).toList());
  }

  /// 타일 점령 정보 저장 (Upsert)
  Future<bool> captureTile(HexTile tile) async {
    try {
      debugPrint('🏹 점령 데이터 전송 중: ${tile.id}');
      await _client.from('captured_tiles').upsert(tile.toJson());
      debugPrint('🚀 서버 업데이트 완료');
      return true;
    } catch (e) {
      debugPrint('❌ 점령 전송 실패: $e');
      return false;
    }
  }

  /// 특정 타일이 누구에게 점령되어 있는지 상태를 정수로 반환하는 함수
  /// - 1: 아직 아무도 점령하지 않은 빈 타일 (중립)
  /// - 2: 상대방이 점령한 타일
  /// - 0: 내가 점령한 타일
  Future<int> checkTileStatusFromServer(
    String tileId,
    String currentUserId,
  ) async {
    try {
      final response = await _client
          .from('captured_tiles')
          .select('user_id')
          .eq('id', tileId)
          .maybeSingle();

      if (response == null) {
        return 1; // 아무도 점령하지 않은 빈 타일
      }

      final String? ownerId = response['user_id'];
      if (ownerId == currentUserId) {
        return 0; // 내 타일
      }

      return 2; // 상대방이 점령한 타일
    } catch (e) {
      debugPrint('❌ 타일 상태 서버 조회 실패: $e');
      return 1; // 오류 시 기본값 1 반환
    }
  }
}
