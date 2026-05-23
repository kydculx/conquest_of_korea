import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// 디바이스의 물리적 가속도 센서(UserAccelerometer) 데이터를 구독하여
/// 사용자 보행 및 스마트폰의 실제 움직임 여부를 판정해주는 서비스 클래스
class SensorService {
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;

  /// 마지막으로 유의미한 모션(흔들림)이 감지된 일시
  DateTime _lastMovementTime = DateTime.now().subtract(const Duration(days: 1));

  /// 물리적 흔들림(보행 등)을 판정하기 위한 가속도 임계값 (m/s²)
  /// 중력가속도를 배제한 x, y, z축 벡터의 절대값 합 크기를 기준으로 설정
  static const double _motionThreshold = 0.25;

  /// 모션이 발생한 직후 정지 상태로 간주하기 전까지의 유예 시각 간격 (초 단위)
  static const int _motionGracePeriodSeconds = 5;

  /// 마지막 흔들림이 감지된 시간 게터
  DateTime get lastMovementTime => _lastMovementTime;

  // 테스트 모킹용 제어 변수
  bool? _mockMoving;
  @visibleForTesting
  set mockMoving(bool? value) => _mockMoving = value;

  /// 디바이스가 물리적으로 움직이고 있는지 판정하는 여부
  /// 마지막 유의미한 흔들림이 감지된 후 5초 유예시간 이내이면 움직임 진행 중으로 판정
  bool get isPhysicallyMoving {
    if (_mockMoving != null) return _mockMoving!;
    final now = DateTime.now();
    return now.difference(_lastMovementTime).inSeconds < _motionGracePeriodSeconds;
  }

  /// 가속도 센서 모니터링 구독을 시작합니다.
  void startListening() {
    // 테스트 모킹이 주입되어 있거나 Flutter Test 환경일 때는 실제 네이티브 스트림 연결을 스킵하여 MissingPluginException을 예방합니다.
    if (_mockMoving != null || Platform.environment.containsKey('FLUTTER_TEST')) return;
    
    _accelerometerSubscription?.cancel();
    
    try {
      // 중력 가속도가 제외된 디바이스 순수 동작 가속도 데이터를 수신
      _accelerometerSubscription = userAccelerometerEventStream().listen(
        (UserAccelerometerEvent event) {
          // x, y, z 가속도 벡터합 계산
          final double magnitude = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );

          // 정지 떨림 이상의 유의미한 동작이 발생했을 때 시각 업데이트
          if (magnitude >= _motionThreshold) {
            _lastMovementTime = DateTime.now();
          }
        },
        onError: (error) {
          debugPrint('✕ [SensorService] 가속도 센서 구독 오류: $error');
        },
      );
    } catch (e) {
      debugPrint('⚠️ [SensorService] 가속도 센서 구독 실패 (테스트 또는 미지원 플랫폼): $e');
    }
  }

  /// 가속도 센서 모니터링 구독을 정지합니다.
  void stopListening() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  /// 자원을 해제합니다.
  void dispose() {
    stopListening();
  }
}
