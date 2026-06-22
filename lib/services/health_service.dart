import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Apple Health 및 Google Health Connect로부터 실시간 걸음수 데이터를 조회하는 싱글톤 서비스.
class HealthService {
  HealthService._privateConstructor();
  static final HealthService instance = HealthService._privateConstructor();

  final Health _health = Health();

  /// 걸음수 조회를 위해 요구되는 건강 데이터 타입 정의
  final List<HealthDataType> _types = [HealthDataType.STEPS];

  /// 걸음수 조회를 위한 권한 권장 목록 (읽기 전용)
  List<HealthDataAccess> get _permissions => [HealthDataAccess.READ];

  /// 현재 걸음수 조회 권한을 획득했는지 여부를 반환합니다.
  Future<bool> hasStepPermissions() async {
    // 테스트 환경인 경우 플러그인 호출 없이 즉시 true 반환
    if (kDebugMode && Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }
    try {
      final bool? hasPermission = await _health.hasPermissions(_types, permissions: _permissions);
      return hasPermission ?? false;
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
      final bool requested = await _health.requestAuthorization(_types, permissions: _permissions);
      return requested;
    } catch (e) {
      debugPrint('⚠️ HealthService.requestStepPermissions 중 에러 발생: $e');
      return false;
    }
  }

  /// 오늘 자정(로컬 시각 기준)부터 현재 시각까지의 누적 걸음수를 조회하여 반환합니다.
  /// 권한이 없거나 조회에 실패하면 0을 반환합니다.
  Future<int> getTodaySteps() async {
    // 테스트 환경인 경우 플러그인 호출 없이 즉시 0 반환
    if (kDebugMode && Platform.environment.containsKey('FLUTTER_TEST')) {
      return 0;
    }
    try {
      // 먼저 권한이 있는지 가볍게 검사하고, 없으면 권한 요청 시도
      bool hasPermission = await hasStepPermissions();
      if (!hasPermission) {
        hasPermission = await requestStepPermissions();
        if (!hasPermission) {
          debugPrint('⚠️ HealthService.getTodaySteps: 건강 데이터 읽기 권한이 거부되었습니다.');
          return 0;
        }
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
