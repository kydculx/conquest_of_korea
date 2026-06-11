import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 직접 접근을 캡슐화하여 모든 키와 입출력을 중앙 관리하는 서비스 클래스.
///
/// 뷰/프로바이더/컨트롤러에서 SharedPreferences.getInstance()를 직접 호출하지 않고
/// 이 서비스를 통해 접근함으로써 레이어 분리를 유지합니다.
class PreferencesService {
  PreferencesService._();

  // --- GPS 프롬프트 Dismiss 상태 (game_screen) ---

  static const _bgLocationKey = 'bg_location_prompt_dismissed';
  static const _bgBatteryKey = 'bg_battery_prompt_dismissed';

  static Future<bool> isBgLocationDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bgLocationKey) ?? false;
  }

  static Future<void> setBgLocationDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bgLocationKey, true);
  }

  static Future<bool> isBgBatteryDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bgBatteryKey) ?? false;
  }

  static Future<void> setBgBatteryDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bgBatteryKey, true);
  }

  // --- 알림 설정 (game_provider) ---

  static const _notifKey = 'conquest_notifications_enabled';
  static const _notifTerritoryAttackKey = 'conquest_notif_territory_attack';
  static const _notifSatelliteCompleteKey = 'conquest_notif_satellite_complete';
  static const _notifSystemNoticeKey = 'conquest_notif_system_notice';

  static Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifKey) ?? true;
  }

  static Future<void> setNotificationEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifKey, v);
  }

  static Future<bool> isNotifTerritoryAttackEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifTerritoryAttackKey) ?? true;
  }

  static Future<void> setNotifTerritoryAttackEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifTerritoryAttackKey, v);
  }

  static Future<bool> isNotifSatelliteCompleteEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifSatelliteCompleteKey) ?? true;
  }

  static Future<void> setNotifSatelliteCompleteEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifSatelliteCompleteKey, v);
  }

  static Future<bool> isNotifSystemNoticeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifSystemNoticeKey) ?? true;
  }

  static Future<void> setNotifSystemNoticeEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifSystemNoticeKey, v);
  }

  // --- 지도 회전 모드 (game_provider) ---

  static const _rotationModeKey = 'conquest_map_rotation_enabled';

  static Future<bool> isMapRotationMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rotationModeKey) ?? false;
  }

  static Future<void> setMapRotationMode(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rotationModeKey, v);
  }

  // --- 위성 점령 쿨타임 저장 (satellite_capture_controller) ---

  static const _lastSatelliteCaptureTimeKey = 'hq_last_satellite_capture_time';

  static Future<String?> getLastSatelliteCaptureTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSatelliteCaptureTimeKey);
  }

  static Future<void> setLastSatelliteCaptureTime(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSatelliteCaptureTimeKey, v);
  }
}
