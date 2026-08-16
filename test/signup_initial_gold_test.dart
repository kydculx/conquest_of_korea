import 'package:flutter_test/flutter_test.dart';
import 'package:conquest_mobile/models/user_profile.dart';
import 'package:conquest_mobile/core/constants/game_config.dart';

void main() {
  group('회원가입 초기 골드 설정 단위 테스트', () {
    test('신규 유저 프로필 생성 시 defaultSignupGold(50.0)가 적용되어 toInsertJson에 포함되어야 함', () {
      final now = DateTime.now();
      final profile = UserProfile(
        id: 'test-user-uuid',
        nickname: '테스터',
        colorHex: '#00FFCC',
        teamId: 'none',
        createdAt: now,
        gold: GameConfig.defaultSignupGold,
        termsAgreedAt: now,
        privacyAgreedAt: now,
        locationAgreedAt: now,
      );

      // 1. 객체의 gold 필드 검증
      expect(profile.gold, equals(50.0));
      expect(profile.gold, equals(GameConfig.defaultSignupGold));

      // 2. toInsertJson에 gold가 정확히 포함되는지 검증 (최초 가입용)
      final insertJson = profile.toInsertJson();
      expect(insertJson['gold'], equals(50.0));
      expect(insertJson['nickname'], equals('테스터'));
      expect(insertJson['id'], equals('test-user-uuid'));

      // 3. toUpdateJson에는 기존 골드 덮어쓰기 방지를 위해 gold가 제외되어 있어야 함
      final updateJson = profile.toUpdateJson();
      expect(updateJson.containsKey('gold'), isFalse);
    });
  });
}
