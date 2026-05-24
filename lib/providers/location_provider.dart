import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/geo_service.dart';
import '../services/sensor_service.dart';
import 'auth_provider.dart';

/// 사용자 GPS 위치 좌표와 디바이스 컴파스 나침반 센서 데이터를 관리하고 이동거리를 계산해주는 프로바이더 클래스
class LocationProvider extends ChangeNotifier with WidgetsBindingObserver {
  /// GPS 기반 로케이션 수신 처리를 수행하는 내부 위치 서비스 객체
  GeoService? _geoService;
  /// 사용자 이동거리를 서버로 갱신하기 위해 참조하는 인증 프로바이더 객체
  AuthProvider? _authProvider;
  /// 물리 위치 데이터 스트림 구독 객체
  StreamSubscription<Position>? _locationSubscription;
  /// 나침반 각도(헤딩) 센서 스트림 구독 객체
  StreamSubscription<CompassEvent>? _compassSubscription;
  /// GPS 신호 끊김을 판단하기 위한 모니터링 타이머
  Timer? _gpsSignalTimer;
  /// 물리적 디바이스 흔들림을 판별하여 위치 오차를 감쇠하기 위한 센서 서비스
  final SensorService _sensorService = SensorService();

  @visibleForTesting
  SensorService get sensorService => _sensorService;

  /// 위도, 경도 좌표 정보를 담은 현재 획득 위치
  LatLng? _currentLocation;
  /// 현재 수신 중인 GPS 신호의 오차 정확도 반경 (미터 단위)
  double _currentAccuracy = 999.0;
  /// 디바이스가 바라보는 북쪽 기준의 회전 각도 (0.0 ~ 360.0 도)
  double _heading = 0.0;
  /// GPS 신호 수신이 실시간으로 원활하게 활성화되어 있는지 여부
  bool _isGpsActive = false;

  // 이동거리 관련 필드 (단위: 미터)
  /// 요원이 게임 가입 이후 현재까지 기록한 총 누적 이동 거리 (미터)
  double _totalDistance = 0.0;
  /// 요원의 오늘 하루 동안 누적 이동 거리 (미터)
  double _dailyDistance = 0.0;
  /// 일일 누적 이동거리 초기화(Reset) 시점을 파악하기 위해 보관하는 마지막 갱신 날짜 데이터 (예: 'YYYY-MM-DD')
  String _lastUpdateDate = '';

  // 포그라운드/백그라운드 제어 및 지터 필터링 변수
  bool _isForeground = true;
  DateTime? _lastPositionTime;

  // 서버 동기화 제어 변수
  /// 가장 최근에 Supabase 서버에 정상 동기화 처리된 누적 이동거리 데이터 (미터)
  double _lastSyncedTotalDistance = 0.0;
  /// 마지막으로 서버 동기화 API를 송신한 일시
  DateTime _lastSyncTime = DateTime.now().subtract(const Duration(minutes: 1));

  /// 현재 획득한 요원의 지도상 좌표 정보 (LatLng)
  LatLng? get currentLocation => _currentLocation;
  /// 현재 GPS 수신의 오차 정확도 범위 값 (미터)
  double get currentAccuracy => _currentAccuracy;
  /// 디바이스의 나침반 방향 각도 값
  double get heading => _heading;
  /// GPS 하드웨어 및 데이터 수신이 정상 활성화 상태인지 확인
  bool get isGpsActive => _isGpsActive;
  /// 요원의 총 누적 이동거리 (미터)
  double get totalDistance => _totalDistance;
  /// 요원의 금일 누적 이동거리 (미터)
  double get dailyDistance => _dailyDistance;

  /// LocationProvider 생성자로 Lifecycle Observer 등록 및 나침반 센서 가동과 로컬 데이터 동기화를 유도합니다.
  LocationProvider() {
    WidgetsBinding.instance.addObserver(this);
    _startCompass();
    _loadDistanceData();
    _sensorService.startListening();
  }

  /// AuthProvider 주입 (ProxyProvider에서 호출)
  void setAuthProvider(AuthProvider auth) {
    if (_authProvider == auth) return;
    _authProvider = auth;

    // 인증된 계정이 있고 서버 측 거리 데이터가 0보다 크면 초기 동기화 보정
    final serverProfile = auth.profile;
    if (serverProfile != null) {
      // 로컬 거리가 0인 최초 실행 등의 상태일 때는 서버 데이터를 우선 동기화
      if (_totalDistance == 0.0 && serverProfile.totalDistance > 0.0) {
        _totalDistance = serverProfile.totalDistance;
        _dailyDistance = serverProfile.dailyDistance;
        _saveDistanceData();
      }
      _lastSyncedTotalDistance = _totalDistance;
    }
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

  /// 로컬 저장소(SharedPreferences)로부터 누적 이동 거리 및 일일 이동 거리 데이터를 로드합니다.
  Future<void> _loadDistanceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _totalDistance = prefs.getDouble('total_distance') ?? 0.0;
      _dailyDistance = prefs.getDouble('daily_distance') ?? 0.0;
      _lastUpdateDate = prefs.getString('last_update_date') ?? '';

      _lastSyncedTotalDistance = _totalDistance;

      _checkDateReset();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load distance data: $e');
    }
  }

  /// 현재 날짜(KST 기준)가 마지막 갱신 날짜와 비교해 변경되었는지 확인하고, 날짜가 바뀌었을 시 당일 일일 이동거리를 0.0으로 초기화합니다.
  void _checkDateReset() {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    if (_lastUpdateDate != todayStr) {
      _dailyDistance = 0.0;
      _lastUpdateDate = todayStr;
      _saveDistanceData();
    }
  }

  /// 이동거리 및 최종 동기화 날짜 상태를 로컬 SharedPreferences 디렉토리에 직렬화하여 저장합니다.
  Future<void> _saveDistanceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('total_distance', _totalDistance);
      await prefs.setDouble('daily_distance', _dailyDistance);
      await prefs.setString('last_update_date', _lastUpdateDate);
    } catch (e) {
      debugPrint('Failed to save distance data: $e');
    }
  }

  /// Supabase 서버로 이동거리 데이터 동기화 전송
  Future<void> syncDistanceToServer({bool force = false}) async {
    final auth = _authProvider;
    if (auth == null || !auth.isAuthenticated || auth.profile == null) return;

    final now = DateTime.now();
    final timeDiff = now.difference(_lastSyncTime);
    final distDiff = (_totalDistance - _lastSyncedTotalDistance).abs();

    // 강제 동기화이거나 (30초 경과하고 50m 이상 이동한 경우) 전송 실행
    if (force || (timeDiff >= const Duration(seconds: 30) && distDiff >= 50.0)) {
      final double total = _totalDistance;
      final double daily = _dailyDistance;

      _lastSyncedTotalDistance = total;
      _lastSyncTime = now;

      try {
        await auth.updateProfileDistance(total, daily);
        debugPrint('📡 [서버 동기화] 이동거리 전송 완료 (Total: ${total.toStringAsFixed(1)}m, Daily: ${daily.toStringAsFixed(1)}m)');
      } catch (e) {
        debugPrint('✕ [서버 동기화] 전송 오류: $e');
      }
    }
  }

  /// GPS 하드웨어로부터 위치 갱신 이벤트를 수신받아 이전 위치와 거리를 계산하고, 정확도가 안정권일 시 이동 거리를 누적 연동합니다.
  void _onPositionUpdate(Position position) {
    final newLocation = LatLng(position.latitude, position.longitude);

    if (_currentLocation != null) {
      final distance = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        newLocation.latitude,
        newLocation.longitude,
      );

      final double timeDiffSec = _lastPositionTime != null
          ? position.timestamp.difference(_lastPositionTime!).inMilliseconds / 1000.0
          : 0.0;

      // --- 동적 속도 감응형 임계값 설정 (Dynamic Speed-Responsive Thresholds) ---
      // 하드웨어 도플러 칩셋이 보증하는 절대 속도가 0.5 m/s (시속 1.8km/h) 이상인 실질 이동 중일 경우, 
      // 보행 누락을 막기 위해 1차 거리 임계값을 2.5m로 정밀 완화하고 Drift Gate를 동적으로 해제합니다.
      // 반면 정지/제자리 흔들기 상태(속도 0.5 m/s 미만)일 때는 최소 거리를 8.0m로 올리고 1.5x Drift Gate로 틀어막습니다.
      final bool isActuallyTravelling = position.speed >= 0.5;
      
      final double distanceThreshold = isActuallyTravelling ? 2.5 : 8.0;
      final double driftGateMultiplier = isActuallyTravelling ? 0.0 : 1.5;

      // 1. 공통 정확도 신뢰성 필터링: 동적 거리 임계치(이동 중 2.5m / 정지 중 8.0m) 적용
      if (position.accuracy <= 20.0 && distance >= distanceThreshold) {
        bool isMoving = false;
        
        // 순간 계산 속도 계산 (GPS 속도가 유실되었거나 부정확할 때 신뢰할 수 있는 백업 수단)
        final double calculatedSpeed = timeDiffSec > 0.0 ? (distance / timeDiffSec) : position.speed;

        if (_isForeground) {
          // --- 포그라운드 상태 3중 극강 동적 필터링 ---
          // 가속도 흔들림 센서가 감지되더라도, 실제 물리적 이동 속도가 현실적인 도보/달리기 속도 윈도우 내에 있어야 실제 이동 중으로 판단합니다.
          // 제자리에서 격렬히 흔들거나 휙 돌려 1초 만에 7~8m 이상 점프하는 비현실적인 순간 튐 속도를 완벽하게 차단합니다.
          final bool hasMotion = _sensorService.isPhysicallyMoving;
          
          // [1단계] 보행 유효 속도 검증 (동적으로 범위 대응)
          // 걷고 있을 때는 현실적인 속도(0.5 ~ 5.0 m/s)를, 흔들 때는 엄격한 하한(0.75 m/s)을 둡니다.
          final double minSpeedLimit = isActuallyTravelling ? 0.4 : 0.75;
          final bool hasMinimumSpeed = (position.speed >= minSpeedLimit && position.speed <= 5.0) || 
                                       (calculatedSpeed >= minSpeedLimit && calculatedSpeed <= 5.0);
          
          // [2단계] 센서 감지 여부와 무관하게 하드웨어 칩셋이 보증하는 명확한 등속/고속 이동 조건 (물리 속도 speed >= 1.0 m/s)
          // 수학적으로 튀는 calculatedSpeed는 여기에 포함하지 않아 정지 상태의 GPS 뜀(Drift)을 철저히 차단합니다.
          final bool hasClearSpeed = position.speed >= 1.0;

          // [3단계] 1.5배 오차 범위 신뢰 타원 드리프트 게이트 (이동 보증 시 비활성화 / 정지 시 1.5x 적용)
          final bool isWithinErrorBound = driftGateMultiplier > 0.0 && (distance < position.accuracy * driftGateMultiplier);

          if (((hasMotion && hasMinimumSpeed) || hasClearSpeed) && !isWithinErrorBound) {
            isMoving = true;
          } else {
            debugPrint('📡 [포그라운드 극강 필터] 제자리 회전/흔들기 차단 - Motion: $hasMotion, Speed: ${position.speed.toStringAsFixed(2)} m/s, CalcSpeed: ${calculatedSpeed.toStringAsFixed(2)} m/s, ErrorBound: $isWithinErrorBound');
          }
        } else {
          // --- 백그라운드 상태 이동 필터링 ---
          // 백그라운드에서는 가속도 동작 센서가 차단되므로 GPS 속도 및 시간당 이동 거리 비율로 실제 유효한 이동(도보/차량) 여부를 판정
          // KTX 고속철도 이동(시속 300km/h)까지 정상 측정되도록 상한 임계치를 시속 330km/h(91.6 m/s)로 대폭 확장
          final double actualSpeed = position.speed > 0 ? position.speed : calculatedSpeed;

          if (actualSpeed >= 0.5 && actualSpeed <= 91.6) {
            isMoving = true;
          } else {
            debugPrint('📡 [백그라운드 필터] 속도 범위 이탈 스킵 - ActualSpeed: ${actualSpeed.toStringAsFixed(2)} m/s');
          }
        }

        // 지터 노이즈 보정: 순간적인 위치 도약 등 비현실적인 순간 속도(시속 330km/h 초과) 차단
        if (timeDiffSec > 0.0 && (distance / timeDiffSec) > 91.6) {
          isMoving = false;
          debugPrint('📡 [지터 필터] 비현실적 위치 도약 차단 (속도: ${(distance / timeDiffSec * 3.6).toStringAsFixed(1)} km/h)');
        }

        if (isMoving) {
          _checkDateReset();
          _totalDistance += distance;
          _dailyDistance += distance;
          _saveDistanceData();
          syncDistanceToServer(); // 주기적 서버 동기화 시도
          debugPrint('📡 [거리 누적] 이동 반영 완료: +${distance.toStringAsFixed(1)}m (누적: ${_dailyDistance.toStringAsFixed(1)}m, 포그라운드: $_isForeground)');
        }
      }

      if (distance < 1.0 && _currentAccuracy == position.accuracy) return;
    }

    _currentLocation = newLocation;
    _currentAccuracy = position.accuracy;
    _lastPositionTime = position.timestamp;
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
  void _startCompass() {
    _compassSubscription?.cancel();
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        _heading = event.heading!;
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
    _locationSubscription = _geoService!.locationStream.listen(_onPositionUpdate);
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isForeground = true;
      _startCompass();
      _sensorService.startListening();
      syncDistanceToServer(force: true); // 앱 다시 켜질 때 최신화 동기화
      debugPrint('📱 [Lifecycle] App Resumed - 포그라운드 센서 융합 모드 가동');
    } else if (state == AppLifecycleState.paused) {
      _isForeground = false;
      _compassSubscription?.cancel();
      _sensorService.stopListening(); // 백그라운드 배터리 자원 낭비 최소화
      syncDistanceToServer(force: true); // 백그라운드로 숨을 때 즉시 전송
      debugPrint('📱 [Lifecycle] App Paused - 백그라운드 GPS 전용 측위 모드 가동');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationSubscription?.cancel();
    _compassSubscription?.cancel();
    _gpsSignalTimer?.cancel();
    _sensorService.dispose();
    super.dispose();
  }
}
