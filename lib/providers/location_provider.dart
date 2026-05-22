import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/geo_service.dart';
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

    // 1m 미만 이동 및 정확도 동일 시 리빌드 생략 (배터리 절약)
    if (_currentLocation != null) {
      final distance = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        newLocation.latitude,
        newLocation.longitude,
      );

      // 정확도가 15m 이내이고, 2m 이상 유의미하게 이동했을 때만 거리 누적
      if (position.accuracy <= 15.0 && distance >= 2.0) {
        _checkDateReset();
        _totalDistance += distance;
        _dailyDistance += distance;
        _saveDistanceData();
        syncDistanceToServer(); // 주기적 서버 동기화 시도
      }

      if (distance < 1.0 && _currentAccuracy == position.accuracy) return;
    }

    _currentLocation = newLocation;
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
      _startCompass();
      syncDistanceToServer(force: true); // 앱 다시 켜질 때 최신화 동기화
    } else if (state == AppLifecycleState.paused) {
      _compassSubscription?.cancel();
      syncDistanceToServer(force: true); // 백그라운드로 숨을 때 즉시 전송
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
