import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../services/supabase_service.dart';
import '../services/hex_service.dart';
import '../services/geo_service.dart';
import '../core/constants.dart';

class GameProvider with ChangeNotifier, WidgetsBindingObserver {
  final SupabaseService _supabase = SupabaseService();
  static const String _teamKey = 'conquest_selected_team';

  // 상태 관리
  String? _selectedTeam;
  final Map<String, Map<String, dynamic>> _capturedTiles = {};
  final List<Map<String, dynamic>> _alerts = [];
  bool _isInitialized = false;
  bool _isAutoCapture = false;
  LatLng? _currentLocation;
  double _currentAccuracy = 999.0;
  double _heading = 0.0; // 기기 방향 (0~360도)
  bool _isGpsActive = false;
  int _currentMapStyleIndex = 0;
  Timer? _gpsSignalTimer;
  StreamSubscription<CompassEvent>? _compassSubscription;

  // Getters
  String? get selectedTeam => _selectedTeam;
  Map<String, Map<String, dynamic>> get capturedTiles => _capturedTiles;
  List<Map<String, dynamic>> get alerts => _alerts;
  bool get isInitialized => _isInitialized;
  bool get isAutoCapture => _isAutoCapture;
  LatLng? get currentLocation => _currentLocation;
  double get heading => _heading;
  bool get isGpsActive => _isGpsActive;
  int get currentMapStyleIndex => _currentMapStyleIndex;
  MapStyle get currentMapStyle => GameConstants.mapStyles[_currentMapStyleIndex];
  bool get showMap => currentMapStyle.url.isNotEmpty;
  double get currentAccuracy => _currentAccuracy;

  /// 현재 위치한 타일을 점령할 수 있는지 여부
  bool get canCapture {
    if (!_isGpsActive || _currentLocation == null || _selectedTeam == null)
      return false;

    // if (_currentAccuracy > GameConstants.captureAccuracyThreshold) return false;

    final hex = HexService.latLngToHex(_currentLocation!);
    final tileId = 'hex_${hex['q']}_${hex['r']}';
    return _capturedTiles[tileId]?['owner'] != _selectedTeam;
  }

  // 실시간 점수 계산
  Map<String, int> get score {
    int blue = 0;
    int red = 0;
    for (var tile in _capturedTiles.values) {
      if (tile['owner'] == GameConstants.teamBlueId) blue++;
      if (tile['owner'] == GameConstants.teamRedId) red++;
    }
    return {'blue': blue, 'red': red};
  }

  // 서비스 참조
  GeoService? _geoService;
  StreamSubscription<Position>? _locationSubscription;

  GameProvider() {
    WidgetsBinding.instance.addObserver(this); // 생명주기 감시 시작
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _handleLifecycleChange(state);
  }

  /// 서버에서 최신 점령 정보를 강제로 다시 가져옴
  void _startCompass() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        _heading = event.heading!;
        notifyListeners();
      }
    });
  }

  void _handleLifecycleChange(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshServerData();
      _startCompass(); // 백그라운드 복귀 시 나침반 재시작
    } else if (state == AppLifecycleState.paused) {
      _compassSubscription?.cancel(); // 리소스 절약을 위해 중단
    }
  }

  Future<void> _refreshServerData() async {
    try {
      final tiles = await _supabase.fetchAllCapturedTiles();
      for (var tile in tiles) {
        _capturedTiles[tile['id']] = tile;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('데이터 갱신 실패: $e');
    }
  }

  void _init() async {
    _selectedTeam = null;
    _startCompass();
    notifyListeners();

    try {
      final initialData = await _supabase.fetchAllCapturedTiles();
      for (var tile in initialData) {
        _capturedTiles[tile['id']] = tile;
      }
    } catch (e) {
      debugPrint('초기 데이터 로드 실패: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }

    _supabase.capturedTilesStream.listen((List<Map<String, dynamic>> data) {
      bool stateChanged = false;
      for (var tile in data) {
        final String tileId = tile['id'];
        final String? oldOwner = _capturedTiles[tileId]?['owner'];
        final String newOwner = tile['owner'];

        // 실시간 알림 로직 (초기화 완료 및 팀 선택 후)
        if (_isInitialized && _selectedTeam != null && oldOwner != newOwner) {
          if (oldOwner == _selectedTeam) {
            // 아군 구역 소실
            addAlert('경보! 아군 구역이 적군에게 점령당했습니다!', 'error');
            Vibration.vibrate(pattern: [0, 200, 100, 200]);
          } else if (newOwner != _selectedTeam) {
            // 적군 세력 확장
            addAlert('적군이 새로운 구역을 확보했습니다.', 'warn');
          }
        }

        _capturedTiles[tileId] = tile;
        stateChanged = true;
      }
      if (stateChanged) notifyListeners();
    });
  }

  void setGeoService(GeoService geo) {
    _geoService = geo;
    _locationSubscription?.cancel();
    _locationSubscription = _geoService!.locationStream.listen((position) {
      updateLocation(position);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 앱 상태 감시 종료
    _locationSubscription?.cancel(); // 위치 알림 구독 취소
    _gpsSignalTimer?.cancel(); // GPS 신호 타이머 취소
    _captureTimer?.cancel(); // 점령 타이머 취소
    _compassSubscription?.cancel(); // 나침반 구독 취소
    super.dispose();
  }

  // 점령 진행 상태
  String? _capturingTileId;
  double _captureProgress = 0.0;
  Timer? _captureTimer;

  String? get capturingTileId => _capturingTileId;
  double get captureProgress => _captureProgress;
  bool get isCapturing => _capturingTileId != null;

  void toggleAutoCapture() {
    _isAutoCapture = !_isAutoCapture;
    addAlert(_isAutoCapture ? '자동 점령 모드 활성화' : '수동 점령 모드 활성화', 'info');
    notifyListeners();
  }

  /// 지도 스타일 순환 (다크 -> 라이트 -> 위성 -> 숨김)
  void cycleMapStyle() {
    _currentMapStyleIndex = (_currentMapStyleIndex + 1) % GameConstants.mapStyles.length;
    addAlert('지도 변경: ${currentMapStyle.name}', 'info');
    notifyListeners();
  }

  /// GPS 하드웨어 강제 재시작 (와이파이 고착 현상 해결용)
  void resetGps() async {
    if (_geoService == null) return;

    addAlert('GPS 하드웨어를 재시작합니다...', 'warn');
    _locationSubscription?.cancel();
    _geoService!.stopTracking();

    // 짧은 대기 후 다시 시작하여 하드웨어 리셋 유도
    await Future.delayed(const Duration(milliseconds: 500));

    await _geoService!.startTracking();
    _locationSubscription = _geoService!.locationStream.listen((position) {
      updateLocation(position);
    });

    addAlert('GPS 캘리브레이션 완료', 'success');
    notifyListeners();
  }

  void startManualCapture() {
    if (!canCapture) {
      if (!_isGpsActive) addAlert('GPS 신호가 없습니다.', 'error');
      // else if (_currentAccuracy > GameConstants.captureAccuracyThreshold) addAlert('GPS 정확도가 너무 낮습니다.', 'warn');
      return;
    }

    final hex = HexService.latLngToHex(_currentLocation!);
    final tileId = 'hex_${hex['q']}_${hex['r']}';
    _startCapture(tileId, _currentLocation!);
  }

  /// 현재 위치 정보를 받아 점령 로직 수행
  void updateLocation(Position position) {
    final newLocation = LatLng(position.latitude, position.longitude);

    // 이전 위치와 차이가 거의 없으면 (약 1m 미만) 리빌드 생략하여 발열 억제
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

    // GPS 신호 유효성 타이머 (10초간 업데이트 없으면 신호 유실로 판단)
    _gpsSignalTimer?.cancel();
    _gpsSignalTimer = Timer(const Duration(seconds: 10), () {
      _isGpsActive = false;
      notifyListeners();
    });

    notifyListeners();

    if (!_isInitialized || _selectedTeam == null) return;

    // 정확도가 낮아도 자동 점령 수행하도록 주석 처리
    /*
    if (_currentAccuracy > GameConstants.captureAccuracyThreshold) {
      _cancelCapture();
      return;
    }
    */

    final hex = HexService.latLngToHex(_currentLocation!);
    final tileId = 'hex_${hex['q']}_${hex['r']}';

    if (_capturedTiles[tileId]?['owner'] == _selectedTeam) {
      _cancelCapture();
      return;
    }

    if (_isAutoCapture && _capturingTileId != tileId) {
      _startCapture(tileId, _currentLocation!);
    }
  }

  void _startCapture(String tileId, LatLng location) {
    _cancelCapture();
    _capturingTileId = tileId;
    _captureProgress = 0.0;

    Vibration.vibrate(pattern: [0, 50, 30, 50]);

    final isEnemyTile = _capturedTiles[tileId] != null;
    final duration = isEnemyTile
        ? GameConstants.enemyTileDuration
        : GameConstants.emptyTileDuration;
    final totalSteps = duration.inMilliseconds / GameConstants.updateIntervalMs;
    final stepIncrement = 1.0 / totalSteps;

    _captureTimer = Timer.periodic(
      const Duration(milliseconds: GameConstants.updateIntervalMs),
      (timer) {
        _captureProgress += stepIncrement;
        if (_captureProgress >= 1.0) {
          _captureProgress = 1.0;
          _finishCapture(tileId, location);
          timer.cancel();
        }
        notifyListeners();
      },
    );
  }

  void _cancelCapture() {
    if (_capturingTileId != null) {
      _captureTimer?.cancel();
      _capturingTileId = null;
      _captureProgress = 0.0;
      notifyListeners();
    }
  }

  Future<void> _finishCapture(String tileId, LatLng location) async {
    Vibration.vibrate(duration: 500);

    final hex = HexService.latLngToHex(location);
    final corners = HexService.getHexCorners(hex['q']!, hex['r']!);
    final bounds = corners
        .map((latLng) => [latLng.latitude, latLng.longitude])
        .toList();

    final tileData = {
      'id': tileId,
      'q': hex['q'],
      'r': hex['r'],
      'owner': _selectedTeam,
      'bounds': bounds,
      'captured_at': DateTime.now().toIso8601String(),
      'capture_status': 'captured',
    };

    try {
      final success = await _supabase.captureTile(tileData);
      
      if (success) {
        _capturedTiles[tileId] = tileData;
        addAlert('구역을 점령했습니다!', 'success');
      } else {
        addAlert('점령 실패: 이미 다른 팀이 점령 중일 수 있습니다.', 'error');
      }
    } catch (e) {
      debugPrint('점령 서버 전송 실패: $e');
      addAlert('통신 오류: 점령 정보 전송에 실패했습니다.', 'error');
    } finally {
      // 어떤 상황에서도 점령 상태는 초기화하여 다음 점령이 가능하게 함
      _capturingTileId = null;
      _captureProgress = 0.0;
      notifyListeners();
    }
  }

  void setSelectedTeam(String teamId) async {
    _selectedTeam = teamId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_teamKey, teamId);
    notifyListeners();
  }

  void addAlert(String message, String type) {
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final alert = {'id': id, 'message': message, 'type': type};
    _alerts.insert(0, alert);
    if (_alerts.length > 5) _alerts.removeLast();
    notifyListeners();
    Timer(const Duration(seconds: 3), () => removeAlert(id));
  }

  void removeAlert(String id) {
    _alerts.removeWhere((a) => a['id'] == id);
    notifyListeners();
  }
}
