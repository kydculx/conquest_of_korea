import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:health/health.dart';
import 'package:url_launcher/url_launcher.dart';

/// Apple Health 및 Google Health Connect로부터 실시간 걸음수 데이터를 조회하는 싱글톤 서비스.
class HealthService {
  HealthService._privateConstructor();
  static final HealthService instance = HealthService._privateConstructor();

  final Health _health = Health();
  static const MethodChannel _healthChannel =
      MethodChannel('com.watercherry.conquest_mobile/health');

  /// 플랫폼별 건강 앱 연동 설정 화면으로 이동합니다.
  /// - Android: Health Connect 앱 권한 설정 -> Health Connect 메인 설정 -> 앱 설정 폴백
  /// - iOS: Apple 건강 앱(x-apple-health://) -> 앱 설정(Geolocator.openAppSettings()) 폴백
  Future<bool> openHealthSettings() async {
    // 테스트 환경인 경우 스킵
    if (kDebugMode && Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }

    try {
      if (Platform.isAndroid) {
        final bool? success =
            await _healthChannel.invokeMethod<bool>('openHealthSettings');
        if (success == true) return true;
        return await Geolocator.openAppSettings();
      } else if (Platform.isIOS) {
        final healthUri = Uri.parse('x-apple-health://');
        if (await canLaunchUrl(healthUri)) {
          return await launchUrl(healthUri, mode: LaunchMode.externalApplication);
        }
        return await Geolocator.openAppSettings();
      } else {
        return await Geolocator.openAppSettings();
      }
    } catch (e) {
      debugPrint('⚠️ HealthService.openHealthSettings 에러: $e');
      try {
        return await Geolocator.openAppSettings();
      } catch (_) {
        return false;
      }
    }
  }

  /// 걸음수 조회를 위해 요구되는 건강 데이터 타입 정의
  final List<HealthDataType> _types = [HealthDataType.STEPS];

  /// 걸음수 조회를 위한 권한 권장 목록 (읽기 전용)
  List<HealthDataAccess> get _permissions => [HealthDataAccess.READ];

  /// 거부 확정 플래그. 한 번 거부되면 다음 시작/명시 요청까지 네이티브 호출 생략.
  /// 네이티브 hasPermissions는 try/catch 없이 RemoteException으로 프로세스 종료 가능.
  bool _denied = false;

  /// 거부 확정 상태 조회 (UI 연동 안내 표시용, 네이티브 호출 없음)
  bool get isDenied => _denied;

  /// 거부 확정 해제 (설정 화면 복귀 등 명시 재확인 시점에만 호출)
  void resetDenial() {
    _denied = false;
    _lastCheckTime = null;
  }

  /// 마지막 네이티브 권한 확인 시각 및 결과 캐시 (호출 빈도 제한용)
  DateTime? _lastCheckTime;
  bool _lastCheckResult = false;

  /// 현재 걸음수 조회 권한을 획득했는지 여부를 반환합니다.
  Future<bool> hasStepPermissions() async {
    // 테스트 환경인 경우 플러그인 호출 없이 즉시 true 반환
    if (kDebugMode && Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }
    // 거부 확정 상태면 네이티브 호출 없이 즉시 false
    if (_denied) return false;

    try {
      // 5분 이내 확인 결과 재사용 (네이티브 호출 빈도 제한)
      final now = DateTime.now();
      if (_lastCheckTime != null &&
          now.difference(_lastCheckTime!).inMinutes < 5) {
        return _lastCheckResult;
      }

      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        if (status != HealthConnectSdkStatus.sdkAvailable) {
          debugPrint('⚠️ Health Connect Sdk is not available: status = $status');
          _lastCheckTime = now;
          _lastCheckResult = false;
          return false;
        }
      }
      final bool? hasPermission = await _health.hasPermissions(_types, permissions: _permissions);
      _lastCheckTime = now;
      _lastCheckResult = hasPermission ?? false;
      // 네이티브 확정 false면 거부 플래그 세팅 (UI 연동 안내용, resume에서 해제)
      if (!_lastCheckResult) _denied = true;
      return _lastCheckResult;
    } catch (e) {
      debugPrint('⚠️ HealthService.hasStepPermissions 중 에러 발생: $e');
      return false;
    }
  }

  /// 건강 정보 조회 권한 동의 팝업을 요청합니다.
  Future<bool> requestStepPermissions() async {
    // 테스트 환경인 경우 플러그인 호출 없이 즉시 true 반환
    if (kDebugMode && Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }
    try {
      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        if (status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
          debugPrint('⚠️ Health Connect Provider (Update) required. Launching install redirect.');
          await _health.installHealthConnect();
          return false;
        } else if (status == HealthConnectSdkStatus.sdkUnavailable) {
          debugPrint('⚠️ Health Connect completely unavailable.');
          return false;
        }
      }
      final bool requested = await _health.requestAuthorization(_types, permissions: _permissions);
      // 명시 요청 결과를 캐시에 반영 (거부 시 이후 네이티브 호출 생략)
      _denied = !requested;
      _lastCheckTime = DateTime.now();
      _lastCheckResult = requested;
      return requested;
    } catch (e) {
      debugPrint('⚠️ HealthService.requestStepPermissions 중 에러 발생: $e');
      return false;
    }
  }

  /// 오늘 자정(로컬 시각 기준)부터 현재 시각까지의 누적 걸음수를 조회하여 반환합니다.
  /// 권한이 없거나 조회에 실패하면 0을 반환합니다.
  /// 읽기 전용: 권한 요청은 하지 않습니다. 권한 요청은 앱 시작 시 1회(main) 또는
  /// 사용자 명시 동작에서만 수행해야 반복 팝업·네이티브 충돌을 피할 수 있습니다.
  Future<int> getTodaySteps() async {
    // 테스트 환경인 경우 플러그인 호출 없이 즉시 0 반환
    if (kDebugMode && Platform.environment.containsKey('FLUTTER_TEST')) {
      return 0;
    }
    try {
      final bool hasPermission = await hasStepPermissions();
      if (!hasPermission) {
        return 0;
      }

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final int? steps = await _health.getTotalStepsInInterval(midnight, now);
      return steps ?? 0;
    } catch (e) {
      debugPrint('⚠️ HealthService.getTodaySteps 중 에러 발생: $e');
      return 0;
    }
  }
}
