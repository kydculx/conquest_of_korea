import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants/strings.dart';

class GeoService {
  static const MethodChannel _batteryChannel =
      MethodChannel('com.watercherry.conquest_mobile/battery');

  StreamSubscription<Position>? _positionStreamSubscription;
  final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();

  /// 안드로이드 배터리 최적화 대상 제외 여부 확인
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final bool isIgnoring =
          await _batteryChannel.invokeMethod('isIgnoringBatteryOptimizations');
      return isIgnoring;
    } on PlatformException catch (e) {
      debugPrint('배터리 최적화 여부 확인 실패: $e');
      return true;
    }
  }

  /// 안드로이드 배터리 최적화 대상 제외 설정 창 요청
  Future<void> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _batteryChannel.invokeMethod('requestIgnoreBatteryOptimizations');
    } on PlatformException catch (e) {
      debugPrint('배터리 최적화 제외 설정 요청 실패: $e');
    }
  }

  Stream<Position> get locationStream => _locationController.stream;

  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 직접 켤 수는 없으나, 설정 화면으로 유도
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

  Future<void> startTracking() async {
    LocationSettings locationSettings;

    // iOS 하드웨어 GPS 강제 점유를 위한 내비게이션 프로필 적용
    if (!kIsWeb && Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.otherNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else if (!kIsWeb && Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        forceLocationManager: true, // 구글 서비스를 거치지 않고 하드웨어 직접 제어 (핵심)
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
        distanceFilter: 0,
      );
    }

    // 1. 하드웨어 예열 (Priming): 스트림 시작 전 강제로 최고 정밀도 위치를 요청하여 GPS 칩을 깨움
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

  void stopTracking() {
    _positionStreamSubscription?.cancel();
  }

  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
