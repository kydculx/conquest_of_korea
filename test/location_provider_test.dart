import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:conquest_mobile/providers/location_provider.dart';
import 'package:conquest_mobile/services/geo_service.dart';

// 테스트용 MockGeoService 구현
class MockGeoService extends GeoService {
  final StreamController<Position> _controller = StreamController<Position>.broadcast();

  @override
  Stream<Position> get locationStream => _controller.stream;

  void emitPosition(Position pos) {
    _controller.add(pos);
  }

  @override
  Future<void> startTracking() async {}
  @override
  void stopTracking() {}
  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

void main() {
  // 테스트용 WidgetsFlutterBinding 및 SharedPreferences 모킹 이니셜라이즈
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('LocationProvider 센서 융합 거리 측정 단위 테스트', () {
    late LocationProvider locationProvider;
    late MockGeoService mockGeoService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockGeoService = MockGeoService();
      locationProvider = LocationProvider();
      locationProvider.setGeoService(mockGeoService);
    });

    tearDown(() {
      mockGeoService.dispose();
    });

    // 헬퍼: 가상 GPS 위치 객체 생성
    Position createPosition({
      required double latitude,
      required double longitude,
      required double accuracy,
      required double speed,
      DateTime? timestamp,
    }) {
      return Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: timestamp ?? DateTime.now(),
        accuracy: accuracy,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: speed,
        speedAccuracy: 0.0,
      );
    }

    test('1. 포그라운드 정지 시: GPS가 3m~5m 튀더라도(드리프트) 가속도 센서 정지 시 거리 누적 100% 락(차단) 검증', () async {
      // 포그라운드 강제 설정 및 동작 정지 모킹
      locationProvider.didChangeAppLifecycleState(AppLifecycleState.resumed);
      locationProvider.sensorService.mockMoving = false;

      // 최초 기준 좌표 (기준점)
      final pos1 = createPosition(
        latitude: 37.5665,
        longitude: 126.9780,
        accuracy: 10.0,
        speed: 0.0,
        timestamp: DateTime.now().subtract(const Duration(seconds: 5)),
      );
      mockGeoService.emitPosition(pos1);
      await Future.delayed(const Duration(milliseconds: 10));

      // 5초 뒤 드리프트로 약 6m 떨어진 위도의 좌표가 유입됨
      final pos2 = createPosition(
        latitude: 37.566555,
        longitude: 126.9780,
        accuracy: 10.0,
        speed: 0.0, // 정지해 있으므로 속도는 0
        timestamp: DateTime.now(),
      );
      mockGeoService.emitPosition(pos2);
      await Future.delayed(const Duration(milliseconds: 10));

      // 정지 상태이므로 거리 누적은 무조건 0.0m이어야 함
      expect(locationProvider.dailyDistance, 0.0);
      expect(locationProvider.totalDistance, 0.0);
    });

    test('2. 포그라운드 실제 보행 시: 가속도 센서 활성화 및 정상 도보 속도에서 거리 정밀 누적 검증', () async {
      locationProvider.didChangeAppLifecycleState(AppLifecycleState.resumed);
      locationProvider.sensorService.mockMoving = true; // 실제 보행 중 흔들림 감지

      // 최초 기준 좌표 (8초 전 타임스탬프 부여, accuracy 5m로 양호하게 설정)
      final pos1 = createPosition(
        latitude: 37.5665,
        longitude: 126.9780,
        accuracy: 5.0,
        speed: 1.2,
        timestamp: DateTime.now().subtract(const Duration(seconds: 8)),
      );
      mockGeoService.emitPosition(pos1);
      await Future.delayed(const Duration(milliseconds: 10));

      // 약 10m 보행 이동 좌표 유입 (속도 1.25 m/s)
      final pos2 = createPosition(
        latitude: 37.56659,
        longitude: 126.9780,
        accuracy: 5.0, // 보행 수신 정확도 5m
        speed: 1.2, // 보행 속도
        timestamp: DateTime.now(),
      );
      mockGeoService.emitPosition(pos2);
      await Future.delayed(const Duration(milliseconds: 10));

      // 가속도 센서 보행 및 정상 속도 조건 충족으로 거리가 정상 누적되어야 함 (약 10m)
      expect(locationProvider.dailyDistance, greaterThan(9.0));
      expect(locationProvider.dailyDistance, lessThan(11.0));
    });

    test('3. 백그라운드 보행 시: 모션 센서 구독 차단 상태에서도 GPS 도보 조건(speed 1.2m/s)으로 100% 정상 누적 검증', () async {
      // 백그라운드(Paused) 모드 전환
      locationProvider.didChangeAppLifecycleState(AppLifecycleState.paused);
      locationProvider.sensorService.mockMoving = false; // 동작 센서 구독 해제되어 무조건 false 상태

      // 최초 기준 좌표 (10초 전 타임스탬프 부여)
      final pos1 = createPosition(
        latitude: 37.5665,
        longitude: 126.9780,
        accuracy: 10.0,
        speed: 0.0,
        timestamp: DateTime.now().subtract(const Duration(seconds: 10)),
      );
      mockGeoService.emitPosition(pos1);
      await Future.delayed(const Duration(milliseconds: 10));

      // 10초 후 약 12m 걸어간 좌표 유입 (속도 1.2 m/s, latitude 37.5665 -> 37.56661은 약 12.2m)
      final pos2 = createPosition(
        latitude: 37.56661,
        longitude: 126.9780,
        accuracy: 10.0,
        speed: 1.2, // 도보 속도 유지
        timestamp: DateTime.now(),
      );
      mockGeoService.emitPosition(pos2);
      await Future.delayed(const Duration(milliseconds: 10));

      // 백그라운드에서는 동작 센서가 꺼지더라도 GPS 속도에 신뢰를 갖고 거리가 누락 없이 정상 누적되어야 함
      expect(locationProvider.dailyDistance, greaterThan(11.0));
      expect(locationProvider.dailyDistance, lessThan(13.5));
    });

    test('4. 지터 필터 작동 검증: 비현실적인 순간 이동(1초 만에 200m) 감지 시 노이즈로 100% 배제', () async {
      locationProvider.didChangeAppLifecycleState(AppLifecycleState.resumed);
      locationProvider.sensorService.mockMoving = true;

      // 최초 기준 좌표
      final pos1 = createPosition(
        latitude: 37.5665,
        longitude: 126.9780,
        accuracy: 5.0,
        speed: 1.2,
        timestamp: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      mockGeoService.emitPosition(pos1);
      await Future.delayed(const Duration(milliseconds: 10));

      // 1초 뒤 갑자기 200m 도약한 기지국 튐 좌표 유입
      final pos2 = createPosition(
        latitude: 37.5683,
        longitude: 126.9780,
        accuracy: 5.0,
        speed: 200.0, // 비현실적인 초고속 도약
        timestamp: DateTime.now(),
      );
      mockGeoService.emitPosition(pos2);
      await Future.delayed(const Duration(milliseconds: 10));

      // 순간 지터 도약이므로 거리는 전혀 증가하지 않고 0.0m이어야 함
      expect(locationProvider.dailyDistance, 0.0);
    });
  });
}
