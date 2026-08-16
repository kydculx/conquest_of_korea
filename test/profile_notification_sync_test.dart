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
        onSyncToRemote: ({
          required bool isMasterEnabled,
          required bool territoryAttack,
          required bool satelliteComplete,
          required bool systemNotice,
        }) async {},
      );

      // 1. 사용자 A의 설정 (알림 모두 OFF 상태)
      final profileA = UserProfile(
        id: 'user-a-uuid',
        nickname: '사용자A',
        colorHex: '#FFFFFF',
        teamId: 'none',
        createdAt: DateTime.now(),
        isNotificationsEnabled: false,
        notifTerritoryAttack: false,
        notifSatelliteComplete: false,
        notifSystemNotice: false,
      );

      await controller.syncFromProfile(profileA);
      expect(controller.isNotificationEnabled, isFalse);
      expect(controller.isNotifTerritoryAttack, isFalse);
      expect(controller.isNotifSatelliteComplete, isFalse);
      expect(controller.isNotifSystemNotice, isFalse);

      // 2. A 로그아웃 (기본값으로 리셋)
      await controller.resetToDefault();
      expect(controller.isNotificationEnabled, isTrue);

      // 3. 사용자 B 로그인 (B의 프로필 설정: 마스터 ON, 영토변경 ON, 위성점령 OFF, 공지 ON)
      final profileB = UserProfile(
        id: 'user-b-uuid',
        nickname: '사용자B',
        colorHex: '#00FFCC',
        teamId: 'none',
        createdAt: DateTime.now(),
        isNotificationsEnabled: true,
        notifTerritoryAttack: true,
        notifSatelliteComplete: false,
        notifSystemNotice: true,
      );

      await controller.syncFromProfile(profileB);

      // B의 고유 설정값으로 정확히 동기화되었는지 검증
      expect(controller.isNotificationEnabled, isTrue);
      expect(controller.isNotifTerritoryAttack, isTrue);
      expect(controller.isNotifSatelliteComplete, isFalse);
      expect(controller.isNotifSystemNotice, isTrue);
      expect(stateChangeCount, greaterThanOrEqualTo(3));
    });
  });
}
