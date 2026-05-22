import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/geo_service.dart';
import 'auth_provider.dart';

/// GPS 위치 및 나침반 상태 전담 Provider
class LocationProvider extends ChangeNotifier with WidgetsBindingObserver {
  GeoService? _geoService;
  AuthProvider? _authProvider;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;
  Timer? _gpsSignalTimer;

  LatLng? _currentLocation;
  double _currentAccuracy = 999.0;
  double _heading = 0.0;
  bool _isGpsActive = false;

  // 이동거리 관련 필드 (단위: 미터)
  double _totalDistance = 0.0;
  double _dailyDistance = 0.0;
  String _lastUpdateDate = '';

  // 서버 동기화 제어 변수
  double _lastSyncedTotalDistance = 0.0;
  DateTime _lastSyncTime = DateTime.now().subtract(const Duration(minutes: 1));

  LatLng? get currentLocation => _currentLocation;
  double get currentAccuracy => _currentAccuracy;
  double get heading => _heading;
  bool get isGpsActive => _isGpsActive;
  double get totalDistance => _totalDistance;
  double get dailyDistance => _dailyDistance;

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

  final Completer<void> _firstLocationCompleter = Completer<void>();
  Future<void> get firstLocationFuture => _firstLocationCompleter.future;

  /// 로컬 저장소에서 이동거리 데이터 불러오기
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

  /// 날짜가 변경되었을 시 당일 이동거리 초기화
  void _checkDateReset() {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    if (_lastUpdateDate != todayStr) {
      _dailyDistance = 0.0;
      _lastUpdateDate = todayStr;
      _saveDistanceData();
    }
  }

  /// 이동거리 데이터 로컬 저장
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
