import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants/strings.dart';

/// 디바이스의 물리 GPS 하드웨어를 직접 제어하고, 실시간 위치 스트림 데이터 수신 및 백그라운드 배터리 최적화 설정을 관리하는 서비스 클래스
class GeoService {
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

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// 하드웨어 GPS 칩을 깨워 예열(Priming)을 시도하고 설정된 주기/정확도 옵션에 따라 백그라운드 포그라운드 위치 추적을 시작합니다.
  Future<void> startTracking() async {
    LocationSettings locationSettings;

    if (!kIsWeb && Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.otherNavigation,
        distanceFilter: 3,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else if (!kIsWeb && Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
        forceLocationManager: true, // 구글 서비스를 거치지 않고 하드웨어 직접 제어
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationText: GameStrings.gpsServiceNotificationText,
          notificationTitle: GameStrings.gpsServiceNotificationTitle,
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
      );
    }

    try {
      await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('GPS 예열 실패 (무시하고 스트림 시작): $e');
    }

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _locationController.add(position);
          },
        );
  }

  /// 진행 중인 실시간 GPS 추적 스트림을 취소하여 위치 트래킹을 중단합니다.
  void stopTracking() {
    _positionStreamSubscription?.cancel();
  }

  /// 추적을 중지하고 활성화된 위치 스트림 컨트롤러를 해제합니다.
  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
