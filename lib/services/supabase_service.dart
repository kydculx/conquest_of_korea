import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // TODO: .env 파일로 이동하여 하드코딩 방지
  static const String _url = 'https://aojbgfdwqlcveffsushg.supabase.co';
  static const String _anonKey = 'sb_publishable_L3mPqH_ppkHkPf93dennYQ_EuALXjnG';

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: _url,
        anonKey: _anonKey,
      );
      print('✅ Supabase 초기화 성공');
    } catch (e) {
      print('❌ Supabase 초기화 실패: $e');
      rethrow;
    }
  }

  SupabaseClient get client => Supabase.instance.client;

  /// 초기 점령 타일 데이터를 모두 가져옴
  Future<List<Map<String, dynamic>>> fetchAllCapturedTiles() async {
    print('🛰️ 모든 점령 타일 데이터 요청 중...');
    final response = await client.from('captured_tiles').select('*');
    final data = List<Map<String, dynamic>>.from(response);
    print('📦 서버 데이터 수신 완료: ${data.length}개의 타일 로드됨');
    return data;
  }

  /// 타일 점령 현황 실시간 스트림
  Stream<List<Map<String, dynamic>>> get capturedTilesStream {
    return client
        .from('captured_tiles')
        .stream(primaryKey: ['id']);
  }

  /// 특정 타일의 점령 정보를 DB에 저장 (Upsert)
  Future<bool> captureTile(Map<String, dynamic> tileData) async {
    try {
      print('🏹 서버에 점령 데이터 전송 중: ${tileData['id']}');
      await client.from('captured_tiles').upsert(tileData);
      print('🚀 서버 업데이트 완료!');
      return true;
    } catch (e) {
      if (e is PostgrestException) {
        print('❌ 서버 업데이트 실패: ${e.message}');
      } else {
        print('❌ 알 수 없는 에러 발생: $e');
      }
      return false;
    }
  }
}
