import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants/game_config.dart';
import '../core/constants/strings.dart';
import 'preferences_service.dart';

/// 디바이스의 물리 GPS 하드웨어를 직접 제어하고, 실시간 위치 스트림 데이터 수신 및 백그라운드 배터리 최적화 설정을 관리하는 서비스 클래스
class GeoService {
  // 싱글톤 패턴 적용
  static final GeoService _instance = GeoService._internal();
  factory GeoService() => _instance;
  GeoService._internal();

  static const MethodChannel _batteryChannel = MethodChannel(
    'com.watercherry.conquest_mobile/battery',
  );

  StreamSubscription<Position>? _positionStreamSubscription;
  final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();

  /// 안드로이드 OS 디바이스에서 본 앱이 배터리 최적화(Doze 모드) 대상에서 제외되었는지 여부를 확인합니다.
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final bool isIgnoring = await _batteryChannel.invokeMethod(
        'isIgnoringBatteryOptimizations',
      );
      return isIgnoring;
    } on PlatformException catch (e) {
      debugPrint('배터리 최적화 여부 확인 실패: $e');
      return true;
    }
  }

  /// 안드로이드 시스템의 배터리 최적화 제외 대상 설정 화면 표시를 네이티브에 요청합니다.
  Future<void> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _batteryChannel.invokeMethod('requestIgnoreBatteryOptimizations');
    } on PlatformException catch (e) {
      debugPrint('배터리 최적화 제외 설정 요청 실패: $e');
    }
  }

  /// 실시간 GPS 위치 갱신 스트림 게터
  Stream<Position> get locationStream => _locationController.stream;

  /// 시스템 GPS 기능 활성화 상태 및 앱의 위치 정보 접근 권한을 확인하고 필요한 경우 권한을 요청합니다.
  ///
  /// 매 호출마다 실제 상태를 확인하고 요청합니다. (1회 가드 없음:
  /// GameScreen 재시도 버튼이 항상 동작해야 무한 대기가 발생하지 않음)
  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  /// 하드웨어 GPS 칩을 깨워 예열(Priming)을 시도하고 설정된 주기/정확도 옵션에 따라 백그라운드 포그라운드 위치 추적을 시작합니다.
  Future<void> startTracking() async {
    final accuracyLevel = await PreferencesService.getGpsAccuracyLevel();
    LocationAccuracy selectedAccuracy;
    switch (accuracyLevel) {
      case 'bestForNavigation':
        selectedAccuracy = LocationAccuracy.bestForNavigation;
        break;
      case 'best':
        selectedAccuracy = LocationAccuracy.best;
        break;
      case 'medium':
        selectedAccuracy = LocationAccuracy.medium;
        break;
      case 'high':
      default:
        selectedAccuracy = LocationAccuracy.high;
        break;
    }

    LocationSettings locationSettings;

    if (!kIsWeb && Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: selectedAccuracy,
        activityType: ActivityType.otherNavigation,
        distanceFilter: 3,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else if (!kIsWeb && Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: selectedAccuracy,
        distanceFilter: GameConfig.gpsDistanceFilterMeters,
        // FusedLocationProvider 사용: 실내/도심에서 네트워크 보정으로 첫 fix를 빠르게 수신
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: GameConfig.gpsUpdateIntervalSeconds),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationText: GameStrings.gpsServiceNotificationText,
          notificationTitle: GameStrings.gpsServiceNotificationTitle,
          notificationIcon: const AndroidResource(
            name: 'launcher_icon',
            defType: 'mipmap',
          ),
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: selectedAccuracy,
        distanceFilter: GameConfig.gpsDistanceFilterMeters,
      );
    }

    // 중복 시작 시 기존 스트림을 먼저 정리 (구독 누수 방지)
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    try {
      // 0단계: 마지막으로 알려진 위치를 즉시 전파하여 대기 화면을 먼저 해제
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && !_locationController.isClosed) {
        _locationController.add(lastKnown);
      }
    } catch (e) {
      debugPrint('마지막 위치 조회 실패 (무시하고 계속): $e');
    }

    try {
      await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(const Duration(seconds: GameConfig.gpsWarmupTimeoutSeconds));
    } catch (e) {
      debugPrint('GPS 예열 실패 (무시하고 스트림 시작): $e');
    }

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          _locationController.add,
          onError: (e) => debugPrint('⚠️ GPS 위치 스트림 에러: $e'),
        );
  }

  /// GPS 설정 변경 시 스트림을 재시작하여 새로운 오차 정확도를 하드웨어 칩에 주입합니다.
  Future<void> updateTrackingAccuracy() async {
    if (_positionStreamSubscription != null) {
      stopTracking();
      await startTracking();
    }
  }

  /// 진행 중인 실시간 GPS 추적 스트림을 취소하여 위치 트래킹을 중단합니다.
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// 추적을 중지하고 활성화된 위치 스트림 컨트롤러를 해제합니다.
  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
