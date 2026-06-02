import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/geo_service.dart';

/// 사용자 GPS 위치 좌표와 디바이스 컴파스 나침반 센서 데이터를 관리하는 프로바이더 클래스
class LocationProvider extends ChangeNotifier with WidgetsBindingObserver {
  /// GPS 기반 로케이션 수신 처리를 수행하는 내부 위치 서비스 객체
  GeoService? _geoService;

  /// 물리 위치 데이터 스트림 구독 객체
  StreamSubscription<Position>? _locationSubscription;

  /// 나침반 각도(헤딩) 센서 스트림 구독 객체
  StreamSubscription<CompassEvent>? _compassSubscription;

  /// GPS 신호 끊김을 판단하기 위한 모니터링 타이머
  Timer? _gpsSignalTimer;

  /// 위도, 경도 좌표 정보를 담은 현재 획득 위치
  LatLng? _currentLocation;

  /// 현재 수신 중인 GPS 신호의 오차 정확도 반경 (미터 단위)
  double _currentAccuracy = 999.0;

  /// 디바이스가 바라보는 북쪽 기준의 회전 각도 (0.0 ~ 360.0 도)
  double _heading = 0.0;

  /// [최적화] 이전 갱신하여 전파한 나침반 각도값 캐시
  double _lastNotifiedHeading = -999.0;

  /// [최적화] 이전 갱신하여 전파한 나침반 갱신 타임스탬프
  DateTime _lastCompassUpdatedTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// GPS 신호 수신이 실시간으로 원활하게 활성화되어 있는지 여부
  bool _isGpsActive = false;

  /// 현재 획득한 요원의 지도상 좌표 정보 (LatLng)
  LatLng? get currentLocation => _currentLocation;

  /// 현재 GPS 수신의 오차 정확도 범위 값 (미터)
  double get currentAccuracy => _currentAccuracy;

  /// 디바이스의 나침반 방향 각도 값
  double get heading => _heading;

  /// GPS 하드웨어 및 데이터 수신이 정상 활성화 상태인지 확인
  bool get isGpsActive => _isGpsActive;

  /// LocationProvider 생성자로 Lifecycle Observer 등록 및 나침반 센서 가동을 시작합니다.
  LocationProvider() {
    WidgetsBinding.instance.addObserver(this);
    _startCompass();
  }

  /// GeoService 연결 (ProxyProvider에서 호출)
  void setGeoService(GeoService geo) {
    if (_geoService == geo) return;
    _geoService = geo;
    _locationSubscription?.cancel();
    _locationSubscription = geo.locationStream.listen(_onPositionUpdate);
  }

  /// 최초 1회 GPS 좌표를 안정적으로 획득했음을 탐지하기 위한 Completer
  final Completer<void> _firstLocationCompleter = Completer<void>();

  /// 최초 1회 GPS 좌표 수신이 완료될 때까지 대기할 수 있는 Future 객체
  Future<void> get firstLocationFuture => _firstLocationCompleter.future;

  /// GPS 하드웨어로부터 위치 갱신 이벤트를 수신받아 실시간 상태를 업데이트합니다.
  void _onPositionUpdate(Position position) {
    _currentLocation = LatLng(position.latitude, position.longitude);
    _currentAccuracy = position.accuracy;
    _isGpsActive = true;

    // 최초 위치 획득 완료
    if (!_firstLocationCompleter.isCompleted) {
      _firstLocationCompleter.complete();
    }

    // 10초간 업데이트 없으면 GPS 신호 유실로 판단
    _gpsSignalTimer?.cancel();
    _gpsSignalTimer = Timer(const Duration(seconds: 10), () {
      _isGpsActive = false;
      notifyListeners();
    });

    notifyListeners();
  }

  /// 나침반 센서 업데이트 수신을 시작하고 실시간으로 회전 각도(방향) 상태를 전파합니다.
  /// [최적화] 미세 진동(Jittering) 노이즈 필터링 및 100ms 시간 스로틀링(Throttling)을 도입하여,
  /// 초당 수십 회씩 발생하던 불필요한 notifyListeners() 및 맵/나침반 재연산 랙을 원천 차단합니다.
  void _startCompass() {
    _compassSubscription?.cancel();
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        final double currentHeading = event.heading!;
        final now = DateTime.now();

        // 1. 시간 기반 스로틀링 (16ms 주기 갭을 두어 초당 최대 60회 60fps에 완벽 정렬 갱신)
        final elapsedMs = now.difference(_lastCompassUpdatedTime).inMilliseconds;
        if (elapsedMs < 16) return;

        // 2. 최초 수신 시에는 평활화 필터를 건너뛰고 즉시 초기화하여 부팅 지연 방지
        if (_lastNotifiedHeading == -999.0) {
          _heading = currentHeading;
          _lastNotifiedHeading = currentHeading;
          _lastCompassUpdatedTime = now;
          notifyListeners();
          return;
        }

        // 3. [초근본 개선] 360도 경계선 회전 Wrap-around를 방지하는 최단 경로 변위 산출
        double diff = currentHeading - _heading;
        diff = diff % 360;
        if (diff > 180) {
          diff -= 360;
        } else if (diff < -180) {
          diff += 360;
        }

        // 4. 지수 평활화(EMA) 필터 가동 (0.18의 정밀 가중치를 가미해 딜레이 없는 극한의 자연스러운 스무딩 수렴)
        final double nextHeading = (_heading + diff * 0.18) % 360;

        _heading = nextHeading;
        _lastNotifiedHeading = currentHeading;
        _lastCompassUpdatedTime = now;
        notifyListeners();
      }
    });
  }

  /// GPS 하드웨어 재시작 (고착 현상 해결)
  Future<void> resetGps() async {
    if (_geoService == null) return;
    _locationSubscription?.cancel();
    _geoService!.stopTracking();
    await Future.delayed(const Duration(milliseconds: 500));
    await _geoService!.startTracking();
    _locationSubscription = _geoService!.locationStream.listen(
      _onPositionUpdate,
    );
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startCompass();
      debugPrint('📱 [Lifecycle] App Resumed - 컴파스 나침반 센서 가동');
    } else if (state == AppLifecycleState.paused) {
      _compassSubscription?.cancel();
      debugPrint('📱 [Lifecycle] App Paused - 백그라운드 전환');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationSubscription?.cancel();
    _compassSubscription?.cancel();
    _gpsSignalTimer?.cancel();
    super.dispose();
  }
}
