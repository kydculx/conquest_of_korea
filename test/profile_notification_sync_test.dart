import 'package:flutter_test/flutter_test.dart';
import 'package:conquest_mobile/models/user_profile.dart';
import 'package:conquest_mobile/controllers/notification_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('계정 전환 시 프로필 알림 설정 동기화 테스트', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('A 사용자가 알림을 끈 후 B 사용자로 로그인하면 B의 프로필 알림 설정값으로 동기화되어야 함', () async {
      int stateChangeCount = 0;
      final controller = NotificationController(
        onStateChanged: () => stateChangeCount++,
        getUserId: () => 'user-b-uuid',
        onSyncToRemote: ({required bool isMasterEnabled}) async {},
      );

      // 1. 사용자 A의 설정 (알림 OFF 상태)
      final profileA = UserProfile(
        id: 'user-a-uuid',
        nickname: '사용자A',
        colorHex: '#FFFFFF',
        teamId: 'none',
        createdAt: DateTime.now(),
        isNotificationsEnabled: false,
      );

      await controller.syncFromProfile(profileA);
      expect(controller.isNotificationEnabled, isFalse);

      // 2. A 로그아웃 (기본값으로 리셋)
      await controller.resetToDefault();
      expect(controller.isNotificationEnabled, isTrue);

      // 3. 사용자 B 로그인 (B의 프로필 설정: 알림 ON)
      final profileB = UserProfile(
        id: 'user-b-uuid',
        nickname: '사용자B',
        colorHex: '#00FFCC',
        teamId: 'none',
        createdAt: DateTime.now(),
        isNotificationsEnabled: true,
      );

      await controller.syncFromProfile(profileB);

      // B의 설정값으로 정확히 동기화되었는지 검증
      expect(controller.isNotificationEnabled, isTrue);
      expect(stateChangeCount, greaterThanOrEqualTo(3));
    });

    test('알림이 켜진 상태에서 toggleNotifications 호출 시 정상적으로 꺼지고 true를 반환해야 함', () async {
      final controller = NotificationController(
        onStateChanged: () {},
        getUserId: () => 'test-user',
        onSyncToRemote: ({required bool isMasterEnabled}) async {},
      );

      // 초기 상태는 true
      expect(controller.isNotificationEnabled, isTrue);

      // 토글하여 끄기 시도
      final result = await controller.toggleNotifications();
      expect(result, isTrue);
      expect(controller.isNotificationEnabled, isFalse);

      // 다시 켜기 시도 (테스트 환경에서는 권한 통과)
      final turnOnResult = await controller.toggleNotifications();
      expect(turnOnResult, isTrue);
      expect(controller.isNotificationEnabled, isTrue);
    });
  });
}
