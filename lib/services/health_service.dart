import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:health/health.dart';
import 'package:url_launcher/url_launcher.dart';

import 'preferences_service.dart';

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
        // LSApplicationQueriesSchemes에 x-apple-health 등록 필요 (Info.plist).
        // canLaunchUrl이 false여도 launch 시도 후 실패 시 앱 설정으로 폴백한다.
        try {
          final healthUri = Uri.parse('x-apple-health://');
          if (await canLaunchUrl(healthUri)) {
            final launched = await launchUrl(healthUri,
                mode: LaunchMode.externalApplication);
            if (launched) return true;
          }
        } catch (_) {
          // 아래 앱 설정 폴백으로 진행
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

  /// iOS 전용 추론 플래그. 연동은 끝났으나 오늘 걸음이 0이고 과거 nonzero
  /// 수신 이력도 없으면 거부로 간주한다. 하드 거부(_denied)와 달리 매 조회마다
  /// 재계산되므로 걸음이 들어오는 즉시 자동 해제되고, 조회 게이트를 막지 않는다.
  bool _iosNeedsLink = false;

  /// 거부 확정 상태 조회 (UI 연동 안내 표시용, 네이티브 호출 없음)
  bool get isDenied => _denied || (Platform.isIOS && _iosNeedsLink);

  /// 거부 확정 해제 (설정 화면 복귀 등 명시 재확인 시점에만 호출)
  void resetDenial() {
    _denied = false;
    _lastCheckTime = null;
  }

  /// iOS 최초 연동(시스템 허용 화면 1회 정상 표시) 여부.
  /// Android는 항상 true를 반환한다.
  Future<bool> isIosLinked() async {
    if (!Platform.isIOS) return true;
    return PreferencesService.isIosStepLinked();
  }

  /// 마지막 네이티브 권한 확인 시각 및 결과 캐시 (호출 빈도 제한용)
  DateTime? _lastCheckTime;
  bool _lastCheckResult = false;

  /// 현재 걸음수 조회 권한을 획득했는지 여부를 반환합니다.
  ///
  /// iOS 주의: Apple HealthKit은 개인정보 보호 정책상 READ 권한 여부를
  /// 앱에 알려주지 않습니다. `hasPermissions`는 iOS에서 항상 null을
  /// 반환하므로(health 패키지 문서 명시), iOS에서는 자체 연동 플래그로
  /// 판단합니다. 최초 연동 전에는 false를 반환하여 "걸음수 연결" 버튼이
  /// 노출되도록 합니다 (Android 거부 상태와 동일한 흐름).
  Future<bool> hasStepPermissions() async {
    // 테스트 환경인 경우 플러그인 호출 없이 즉시 true 반환
    if (kDebugMode && Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }
    // 거부 확정 상태면 네이티브 호출 없이 즉시 false
    if (_denied) return false;

    // iOS: 최초 연동 전이면 미연동(false)으로 판단하여 버튼 노출.
    if (Platform.isIOS) {
      final linked = await PreferencesService.isIosStepLinked();
      if (!linked) {
        _denied = true;
        _lastCheckTime = DateTime.now();
        _lastCheckResult = false;
        return false;
      }
      return true;
    }

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
  ///
  /// iOS 주의: HealthKit은 실제 허용 여부를 알려주지 않고 팝업 표시
  /// 성공 여부만 반환합니다. 거부해도 true가 올 수 있으므로, 거부 검출은
  /// `hasPermissions`가 아닌 실제 조회 결과로 판단해야 합니다.
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
      // iOS: 시스템 허용 화면이 정상 표시되면 연동 완료로 기록한다.
      // (거부해도 true가 반환될 수 있어 이후 "0걸음"이면 설정 안내로 복구한다.)
      if (Platform.isIOS && requested) {
        await PreferencesService.setIosStepLinked();
      }
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
      // iOS 포함 전 플랫폼 공통 게이트. iOS는 hasPermissions 대신
      // 자체 연동 플래그로 판단한다. 0걸음 단독으로는 거부로 단정하지 않고,
      // 아래 조회 결과와 nonzero 이력을 함께 보고 버튼 노출 여부를 정한다.
      final bool hasPermission = await hasStepPermissions();
      if (!hasPermission) {
        return 0;
      }

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final int? steps = await _health.getTotalStepsInInterval(midnight, now);
      final int count = steps ?? 0;
      if (Platform.isIOS) {
        if (count > 0) {
          _iosNeedsLink = false;
          await PreferencesService.setIosStepSeenNonzero();
        } else {
          // 연동 완료 + 0걸음 + nonzero 이력 없음 → 거부로 간주하여 버튼 노출.
          // 허용 직후 아직 걷기 전에도 버튼이 뜰 수 있으나, 걸음이 한 번이라도
          // 들어오면 이후부터는 정상 표시된다.
          _iosNeedsLink = !(await PreferencesService.isIosStepSeenNonzero());
        }
      }
      return count;
    } catch (e) {
      debugPrint('⚠️ HealthService.getTodaySteps 중 에러 발생: $e');
      return 0;
    }
  }
}
