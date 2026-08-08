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

  // --- 발자취 로컬 백업 (game_tile_provider) ---
  static const _footprintsKey = 'conquest_local_footprints';

  static Future<Map<String, String>> getLocalFootprints() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_footprintsKey) ?? [];
    final Map<String, String> map = {};
    for (final item in list) {
      final parts = item.split('|');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      }
    }
    return map;
  }

  static Future<void> saveLocalFootprints(Map<String, String> footprints) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = footprints.entries.map((e) => '${e.key}|${e.value}').toList();
    await prefs.setStringList(_footprintsKey, list);
  }

  // --- 미동기화 발자취 대기열 (conquest_pending_footprints) ---
  static const _pendingFootprintsKey = 'conquest_pending_footprints';

  static Future<List<String>> getPendingFootprints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_pendingFootprintsKey) ?? [];
  }

  static Future<void> savePendingFootprints(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_pendingFootprintsKey, list);
  }

  static Future<void> addPendingFootprint(String tileId, DateTime time) async {
    final list = await getPendingFootprints();
    final String timeStr = time.toUtc().toIso8601String();
    final String entry = '$tileId|$timeStr';
    if (!list.any((item) => item.startsWith('$tileId|'))) {
      list.add(entry);
      await savePendingFootprints(list);
    }
  }

  static Future<void> removePendingFootprint(String tileId) async {
    final list = await getPendingFootprints();
    list.removeWhere((item) => item.startsWith('$tileId|'));
    await savePendingFootprints(list);
  }
}
