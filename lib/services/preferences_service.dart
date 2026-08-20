import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 직접 접근을 캡슐화하여 모든 키와 입출력을 중앙 관리하는 서비스 클래스.
///
/// 뷰/프로바이더/컨트롤러에서 SharedPreferences.getInstance()를 직접 호출하지 않고
/// 이 서비스를 통해 접근함으로써 레이어 분리를 유지합니다.
class PreferencesService {
  PreferencesService._();

  // --- 위치 권한 안내 상태 (geo_service) ---
  // 시스템 권한 다이얼로그는 1회만, 설정 화면 유도는 1회만 하여
  // 매 실행마다 팝업이 반복되는 것을 방지합니다.

  static const _locationPermissionAskedKey = 'location_permission_asked';
  static const _locationSettingsGuidedKey = 'location_settings_guided';

  static Future<bool> isLocationPermissionAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationPermissionAskedKey) ?? false;
  }

  static Future<void> setLocationPermissionAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationPermissionAskedKey, true);
  }

  static Future<bool> isLocationSettingsGuided() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationSettingsGuidedKey) ?? false;
  }

  static Future<void> setLocationSettingsGuided() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationSettingsGuidedKey, true);
  }

  // --- 걸음 수 권한 안내 상태 (main) ---
  // Health Connect 권한 요청은 앱 시작 시 1회만 하여
  // 매 실행마다 권한 화면/설치 리다이렉트가 반복되는 것을 방지합니다.

  static const _stepPermissionAskedKey = 'step_permission_asked';

  static Future<bool> isStepPermissionAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_stepPermissionAskedKey) ?? false;
  }

  static Future<void> setStepPermissionAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_stepPermissionAskedKey, true);
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

  // --- 편법 방지 방문 타일 기록 (game_provider) ---

  static const _lastTileIdKey = 'conquest_last_visited_tile_id';
  static const _secondLastTileIdKey = 'conquest_second_last_visited_tile_id';

  static Future<String?> getLastVisitedTileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastTileIdKey);
  }

  static Future<void> setLastVisitedTileId(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastTileIdKey, v);
  }

  static Future<String?> getSecondLastVisitedTileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_secondLastTileIdKey);
  }

  static Future<void> setSecondLastVisitedTileId(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_secondLastTileIdKey, v);
  }

  // --- 동전 생성 날짜 (game_provider) ---
  static const _lastCoinGeneratedDateKey = 'conquest_last_coin_generated_date';

  static Future<String?> getLastCoinGeneratedDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastCoinGeneratedDateKey);
  }

  static Future<void> setLastCoinGeneratedDate(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCoinGeneratedDateKey, v);
  }

  // --- 최초 로그인 온보딩 튜토리얼 노출 플래그 ---
  static const _hasSeenOnboardingKey = 'conquest_has_seen_onboarding';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingKey) ?? false;
  }

  static Future<void> setSeenOnboarding([bool v = true]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, v);
  }

  // --- GPS 정확도 레벨 설정 (SharedPreferences 저장) ---
  static const _gpsAccuracyKey = 'conquest_gps_accuracy_level';

  static Future<String> getGpsAccuracyLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_gpsAccuracyKey) ?? 'high';
  }

  static Future<void> setGpsAccuracyLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gpsAccuracyKey, level);
  }
}
