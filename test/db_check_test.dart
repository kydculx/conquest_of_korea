// ignore_for_file: avoid_print, unused_import
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() {
  test('Supabase 실서버 상태 점검', () async {
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
        print('  - ID: ${p['id']}, Nick: ${p['nickname']}, Gold: ${p['gold']}, CapturedCount: ${p['captured_tiles_count']}, LastUpdated: ${p['last_gold_updated_at']}');
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
          print('  - TileID: ${t['id']}, UserID: ${t['user_id']}, CapturedAt: ${t['captured_at']}');
        }
      }
    } catch (e) {
      print('❌ captured_tiles 조회 에러: $e');
    }

    // 6. safe_capture_tile RPC 호출 테스트
    try {
      print('🏹 safe_capture_tile RPC 테스트 시작...');
      final testUserId = 'de0a3e9e-c6d1-41d4-9f17-f1796b5f5df9'; // profiles에 존재하는 실서버 사용자 ID
      final params = {
        'p_tile_id': 'test_rpc_tile_id_123',
        'p_q': 999,
        'p_r': 999,
        'p_user_id': testUserId,
        'p_color_hex': '#FF0000',
        'p_bounds': [],
        'p_target_capture_count': 1,
        'p_shield_duration_seconds': 60,
      };
      final response = await client.rpc('safe_capture_tile', params: params);
      print('🚀 RPC safe_capture_tile 호출 결과: $response');
    } catch (e) {
      print('❌ RPC safe_capture_tile 호출 에러: $e');
    }
  });
}
