// ⚠️ 실서버 검증용 임시 테스트: safe_capture_tile RPC 배포 상태 확인
// 실행: flutter test test/db_rpc_verify_test.dart
// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('safe_capture_tile RPC 실서버 배포 및 시그니처 검증', () async {
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
    expect(url, isNotNull);
    expect(anonKey, isNotNull);

    final client = SupabaseClient(
      url!,
      anonKey!,
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );

    // 1. 임시 테스트 계정 생성
    final tempEmail = 'rpc_verify_${DateTime.now().millisecondsSinceEpoch}@gmail.com';
    const tempPassword = 'testPassword123!';
    final authRes = await client.auth.signUp(
      email: tempEmail,
      password: tempPassword,
    );
    final testUser = authRes.user;
    if (testUser == null) {
      fail('회원가입 실패');
    }
    final testUserId = testUser.id;
    print('👤 테스트 계정 생성: $testUserId');

    final testTileId = 'hex_rpc_verify_999_999';

    try {
      // 2. 클라이언트가 실제로 보내는 것과 동일한 파라미터로 RPC 호출
      final params = {
        'p_tile_id': testTileId,
        'p_q': 999,
        'p_r': 999,
        'p_user_id': testUserId,
        'p_color_hex': '#00FFCC',
        'p_target_capture_count': 1,
        'p_shield_duration_seconds': 0,
      };
      print('🏹 safe_capture_tile RPC 호출 시도...');
      final response = await client.rpc('safe_capture_tile', params: params);
      print('🚀 RPC 응답: $response');

      // 3. 저장 검증
      final saved = await client
          .from('captured_tiles')
          .select('*')
          .eq('id', testTileId)
          .maybeSingle();
      print('🗺️ 저장된 타일: $saved');
      expect(saved, isNotNull, reason: 'safe_capture_tile 호출 후 captured_tiles에 저장되어야 함');
      expect(saved!['user_id'], testUserId);
    } on PostgrestException catch (e) {
      print('❌ PostgrestException: code=${e.code}, message=${e.message}, details=${e.details}, hint=${e.hint}');
      rethrow;
    } finally {
      // 4. 클린업
      try {
        await client.from('captured_tiles').delete().eq('id', testTileId);
        await client.from('profiles').delete().eq('id', testUserId);
        print('🧹 클린업 완료');
      } catch (e) {
        print('⚠️ 클린업 실패 (무시): $e');
      }
    }
  });
}
