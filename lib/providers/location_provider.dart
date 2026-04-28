import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/geo_service.dart';

/// GPS 위치 및 나침반 상태 전담 Provider
class LocationProvider extends ChangeNotifier with WidgetsBindingObserver {
  GeoService? _geoService;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;
  Timer? _gpsSignalTimer;

  LatLng? _currentLocation;
  double _currentAccuracy = 999.0;
  double _heading = 0.0;
  bool _isGpsActive = false;

  LatLng? get currentLocation => _currentLocation;
  double get currentAccuracy => _currentAccuracy;
  double get heading => _heading;
  bool get isGpsActive => _isGpsActive;

  LocationProvider() {
    WidgetsBinding.instance.addObserver(this);
    _startCompass();
  }

  /// GeoService 연결 (ProxyProvider에서 호출)
  void setGeoService(GeoService geo) {
    _geoService = geo;
    _locationSubscription?.cancel();
    _locationSubscription = geo.locationStream.listen(_onPositionUpdate);
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
      if (distance < 1.0 && _currentAccuracy == position.accuracy) return;
    }

    _currentLocation = newLocation;
    _currentAccuracy = position.accuracy;
    _isGpsActive = true;

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
    } else if (state == AppLifecycleState.paused) {
      _compassSubscription?.cancel();
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
