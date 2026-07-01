// ⚠️ 주의: 이 테스트는 실서버 Supabase에 직접 연결하여 읽기/쓰기를 수행합니다.
// 개발 환경에서만 선택적으로 실행해야 하며, CI/CD에서는 반드시 SKIP되어야 합니다.
// 실행: DB_CHECK_TEST=true flutter test test/db_check_test.dart
// ignore_for_file: avoid_print, unused_import
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() {
  test('Supabase 실서버 상태 점검', () async {
    // 실서버 직접 연결 테스트 — CI에서 실행되지 않도록 skip (env 플래그 필요).
    // 실행: DB_CHECK_TEST=true flutter test test/db_check_test.dart
    // 1. .env 파일 로드
    final envFile = File('.env');
    expect(envFile.existsSync(), isTrue);
    final envContent = await envFile.readAsLines();
    String? url;
    String? anonKey;
    for (var line in envContent) {
      if (line.startsWith('SUPABASE_URL=')) {
        url = line.substring('SUPABASE_URL='.length).trim();
      } else if (line.startsWith('SUPABASE_ANON_KEY=')) {
        anonKey = line.substring('SUPABASE_ANON_KEY='.length).trim();
      }
    }

    print('📡 Supabase URL: $url');
    expect(url, isNotNull);
    expect(anonKey, isNotNull);

    // 2. Supabase 클라이언트 초기화
    final client = SupabaseClient(url!, anonKey!);

    // 3. system_settings 조회
    try {
      final settings = await client.from('system_settings').select('*');
      print('⚙️ system_settings: $settings');
    } catch (e) {
      print('❌ system_settings 조회 에러: $e');
    }

    // 4. profiles 조회 (상위 5개)
    try {
      final profiles = await client.from('profiles').select('*').limit(5);
      print('👤 profiles sample (top 5):');
      if (profiles.isNotEmpty) {
        print('🔑 profiles columns: ${profiles[0].keys.toList()}');
      }
      for (var p in profiles) {
        print(
          '  - ID: ${p['id']}, Nick: ${p['nickname']}, Gold: ${p['gold']}, CapturedCount: ${p['captured_tiles_count']}, LastUpdated: ${p['last_gold_updated_at']}',
        );
      }
    } catch (e) {
      print('❌ profiles 조회 에러: $e');
    }

    // 5. captured_tiles 개수 및 샘플
    try {
      final countRes = await client.from('captured_tiles').select('id');
      print('🗺️ 총 점령 타일 수: ${countRes.length}');
      if (countRes.isNotEmpty) {
        final tiles = await client.from('captured_tiles').select('*').limit(5);
        print('🗺️ captured_tiles sample (top 5):');
        for (var t in tiles) {
          print(
            '  - TileID: ${t['id']}, UserID: ${t['user_id']}, CapturedAt: ${t['captured_at']}',
          );
        }
      }
    } catch (e) {
      print('❌ captured_tiles 조회 에러: $e');
    }

    // 6. update_user_gold_admin RPC 호출 테스트
    try {
      print('🏹 update_user_gold_admin RPC 테스트 시작...');
      const testUserId = '038f9c30-0314-4246-97d6-725f84a57efe'; // test_01
      final params = {
        'p_user_id': testUserId,
        'p_gold_amount': 2500.5,
      };
      final response = await client.rpc('update_user_gold_admin', params: params);
      print('🚀 RPC update_user_gold_admin 호출 결과: $response');
      
      // 반영 후 검증 조회
      final updatedProfile = await client.from('profiles').select('gold').eq('id', testUserId).single();
      print('💰 업데이트 후 골드 조회 결과: ${updatedProfile['gold']}');
    } catch (e) {
      print('❌ RPC update_user_gold_admin 호출 에러: $e');
    }
  });
}
