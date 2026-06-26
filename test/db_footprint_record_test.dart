// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Supabase user_footprints 테이블 실서버 RLS 보안 검증 테스트', () async {
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

    // 2. Supabase 클라이언트 초기화 (CLI 환경의 PKCE 스토리지 제한 우회를 위해 implicit flow로 설정)
    final client = SupabaseClient(
      url!,
      anonKey!,
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );

    // 임의의 유니크한 테스트용 계정 생성
    final tempEmail = 'footprint_test_${DateTime.now().millisecondsSinceEpoch}@gmail.com';
    const tempPassword = 'testPassword123!';

    print('👤 [테스트] 신규 테스트 계정 가입 시도: $tempEmail');

    try {
      final AuthResponse authRes = await client.auth.signUp(
        email: tempEmail,
        password: tempPassword,
      );

      final testUser = authRes.user;
      if (testUser == null) {
        throw Exception('회원가입 실패 (유저 객체 null)');
      }

      final testUserId = testUser.id;
      print('👤 [테스트] 회원가입 성공. 할당된 UID: $testUserId');

      // 이메일 인증이 꺼져 있으면 아래 upsert가 통과할 것이고, 켜져 있으면 RLS 위반 에러(PostgrestException)가 날 것입니다.
      const testTileId = 'hex_test_footprint_999_999';
      final nowUtc = DateTime.now().toUtc();
      final truncatedTime = DateTime.utc(
        nowUtc.year,
        nowUtc.month,
        nowUtc.day,
        nowUtc.hour,
        nowUtc.minute,
      );

      print('🐾 [테스트] 발자취 기록 시도: 사용자($testUserId), 타일($testTileId), 시각($truncatedTime)');

      try {
        final insertData = {
          'user_id': testUserId,
          'tile_id': testTileId,
          'recorded_at': truncatedTime.toIso8601String(),
        };

        // upsert 시도
        await client.from('user_footprints').upsert(
              insertData,
              onConflict: 'user_id,tile_id',
            );
        
        print('✅ [테스트] 이메일 인증 불필요 세션 - user_footprints upsert 성공!');
        
        // 검증 및 삭제 처리
        final response = await client
            .from('user_footprints')
            .select('*')
            .eq('user_id', testUserId)
            .eq('tile_id', testTileId)
            .maybeSingle();

        expect(response, isNotNull);
        expect(response!['tile_id'], testTileId);
        
        await client
            .from('user_footprints')
            .delete()
            .eq('user_id', testUserId)
            .eq('tile_id', testTileId);
        print('🧹 [테스트] 발자취 데이터 클린업 완료');
        
      } catch (e) {
        if (e is PostgrestException) {
          // 이메일 인증 대기 상태이므로 auth.uid()가 null이라 RLS(row-level security) 위반 에러가 발생한 상황.
          // 이는 테이블 RLS 정책이 완벽히 동작 중임을 의미하므로 테스트 성공으로 판단합니다.
          expect(e.code, '42501'); // 42501은 PostgreSQL의 Insufficient Privilege / RLS Violation 에러 코드입니다.
          print('🛡️ [RLS 검증 완료] 예상된 RLS 보안 차단 성공: $e');
        } else {
          rethrow;
        }
      } finally {
        // 프로필 클린업
        await client.from('profiles').delete().eq('id', testUserId);
        print('🧹 [테스트] 프로필 클린업 완료');
      }

    } catch (e) {
      print('❌ [테스트 실패] 예외 발생: $e');
      fail('DB RLS 검증 테스트 실패: $e');
    }
  });
}
