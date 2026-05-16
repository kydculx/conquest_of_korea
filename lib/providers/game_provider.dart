import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/capture_controller.dart';
import '../models/alert_model.dart';
import '../models/tile_model.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart';
import '../services/hex_service.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../core/constants.dart';

/// 게임 핵심 상태 관리 Provider
class GameProvider extends ChangeNotifier {
  static const String _notifKey = 'conquest_notifications_enabled';

  final SupabaseService _supabase;
  late final CaptureController _captureController;
  StreamSubscription<List<HexTile>>? _tilesStreamSub;
  Timer? _backgroundPollingTimer; // 추가: 백그라운드 감시 타이머
  final Completer<void> _initCompleter = Completer<void>();

  // --- 상태 ---
  final Map<String, HexTile> _capturedTiles = {};
  final List<GameAlert> _alerts = [];
  bool _isInitialized = false;
  bool _isAutoCapture = false;
  bool _showBoundaries = true;
  int _currentMapStyleIndex = 0;
  bool _isNotificationEnabled = true;

  // 관련 Provider 참조
  LocationProvider? _locationProvider;
  AuthProvider? _authProvider;

  // --- Getters ---
  Map<String, HexTile> get capturedTiles => Map.unmodifiable(_capturedTiles);
  List<GameAlert> get alerts => List.unmodifiable(_alerts);
  bool get isInitialized => _isInitialized;
  bool get isAutoCapture => _isAutoCapture;
  bool get showBoundaries => _showBoundaries;
  int get currentMapStyleIndex => _currentMapStyleIndex;
  bool get isNotificationEnabled => _isNotificationEnabled;
  MapStyle get currentMapStyle =>
      GameConstants.mapStyles[_currentMapStyleIndex];
  bool get showMap => currentMapStyle.url.isNotEmpty;
  int get myCapturedCount => _authProvider?.user?.id == null
      ? 0
      : _capturedTiles.values
            .where((t) => t.userId == _authProvider!.user!.id)
            .length;

  String? get capturingTileId => _captureController.capturingTileId;
  String? get capturingColorHex => _captureController.capturingColorHex;
  double get captureProgress => _captureController.captureProgress;
  bool get isCapturing => _captureController.isCapturing;

  bool get canCapture {
    final loc = _locationProvider;
    final auth = _authProvider;

    if (loc == null || !loc.isGpsActive || loc.currentLocation == null) {
      return false;
    }

    // GPS 오차가 너무 크면 점령 불가
    if (loc.currentAccuracy > GameConstants.captureAccuracyThreshold) {
      return false;
    }

    if (auth == null || !auth.isAuthenticated) {
      return false;
    }

    // 이미 본인이 점령한 타일이면 점령 불가
    return !isAlreadyCapturedByMe;
  }

  bool get isAlreadyCapturedByMe {
    final loc = _locationProvider;
    final auth = _authProvider;
    if (loc?.currentLocation == null || auth?.user == null) return false;

    final hex = HexService.latLngToHex(loc!.currentLocation!);
    final tileId = 'hex_${hex['q']}_${hex['r']}';
    return _capturedTiles[tileId]?.userId == auth!.user!.id;
  }

  GameProvider({required SupabaseService supabase}) : _supabase = supabase {
    _captureController = CaptureController(
      supabase: supabase,
      onAlert: addAlert,
      onTileCaptured: (id, tile) {
        _capturedTiles[id] = tile;
        if (_isNotificationEnabled) {
          NotificationService().showLocalNotification(
            id: id.hashCode,
            title: '🚩 영토 점령 성공!',
            body: '새로운 지역을 당신의 영토로 만들었습니다!',
          );
        }
        notifyListeners();
      },
      onStateChanged: notifyListeners,
    );
    _init();
  }

  void setLocationProvider(LocationProvider loc) {
    if (_locationProvider != loc) {
      // 기존 리스너 제거
      _locationProvider?.removeListener(onLocationUpdated);
      
      _locationProvider = loc;
      
      // 새 리스너 등록 (UI 리빌드와 상관없이 실행됨)
      _locationProvider?.addListener(onLocationUpdated);
      
      notifyListeners();
    }
  }

  void setAuthProvider(AuthProvider auth) {
    if (_authProvider != auth) {
      _authProvider = auth;
      notifyListeners();
    }
  }

  Future<void> get initializationFuture => _initCompleter.future;

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isNotificationEnabled = prefs.getBool(_notifKey) ?? true;

      final tiles = await _supabase.fetchAllCapturedTiles();
      for (final tile in tiles) {
        _capturedTiles[tile.id] = tile;
      }
    } catch (e) {
      debugPrint('초기 데이터 로드 실패: $e');
    } finally {
      _isInitialized = true;
      if (!_initCompleter.isCompleted) _initCompleter.complete();
      notifyListeners();
    }
    _tilesStreamSub = _supabase.capturedTilesStream.listen(_onTilesUpdated);
    _startBackgroundPolling(); // 추가: 주기적 감시 시작
  }

  /// 백그라운드에서도 정해진 주기마다 서버 데이터를 강제로 갱신하는 로직
  void _startBackgroundPolling() {
    _backgroundPollingTimer?.cancel();
    _backgroundPollingTimer = Timer.periodic(
      GameConstants.backgroundCheckInterval,
      (_) => _refreshTilesAndCheckInvasion(),
    );
  }

  /// 서버에서 최신 타일 정보를 가져와 침공 여부를 강제 체크
  Future<void> _refreshTilesAndCheckInvasion() async {
    if (!_isInitialized) return;
    try {
      debugPrint('🔍 백그라운드 정기 정밀 점검 중...');
      
      // 추가: 가만히 서 있는 상태에서도 점령이 완료되었는지 체크
      _captureController.checkCaptureStatus();

      final tiles = await _supabase.fetchAllCapturedTiles();
      _onTilesUpdated(tiles);
    } catch (e) {
      debugPrint('❌ 백그라운드 동기화 실패: $e');
    }
  }

  void _onTilesUpdated(List<HexTile> tiles) {
    final auth = _authProvider;
    if (auth?.user == null) return;

    bool changed = false;
    bool invasionDetected = false;

    for (final tile in tiles) {
      // 1. 침공 감지: 기존에 내 땅이었는데 주인이 바뀐 경우
      final oldTile = _capturedTiles[tile.id];
      if (oldTile != null &&
          oldTile.userId == auth!.user!.id &&
          tile.userId != auth.user!.id) {
        invasionDetected = true;
      }

      _capturedTiles[tile.id] = tile;
      changed = true;
    }

    if (invasionDetected) {
      // 침공 알림 발송
      NotificationService().showLocalNotification(
        id: 999,
        title: '⚠️ 영토 상실 경보!',
        body: '다른 유저가 당신의 영토를 빼앗았습니다! 즉시 탈환하세요!',
      );

      // 만약 내가 그 자리에 있다면 즉시 반격 시작
      if (_isAutoCapture) {
        onLocationUpdated();
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  void onLocationUpdated() {
    if (!_isInitialized) return;
    final loc = _locationProvider;
    final auth = _authProvider;
    if (loc == null || !loc.isGpsActive || loc.currentLocation == null) return;
    if (auth == null || !auth.isAuthenticated || auth.profile == null) return;

    final hex = HexService.latLngToHex(loc.currentLocation!);
    final tileId = 'hex_${hex['q']}_${hex['r']}';

    // 1. 상태 체크 (백그라운드 타이머 보정)
    _captureController.checkCaptureStatus();

    // 내 땅이 아니면 무조건 점령 시도
    final tile = _capturedTiles[tileId];
    if (tile?.userId != auth.user?.id) {
      if (_isAutoCapture) {
        _captureController.startCapture(
          tileId: tileId,
          location: loc.currentLocation!,
          userId: auth.user!.id,
          colorHex: auth.profile!.colorHex,
          duration: tile == null ? GameConstants.emptyTileDuration : GameConstants.enemyTileDuration,
        );
      }
    } else {
      _captureController.cancelCapture();
    }
  }

  void startManualCapture() {
    final loc = _locationProvider;
    final auth = _authProvider;
    if (!canCapture ||
        loc?.currentLocation == null ||
        auth?.user == null ||
        auth?.profile == null) {
      return;
    }

    final hex = HexService.latLngToHex(loc!.currentLocation!);
    final tileId = 'hex_${hex['q']}_${hex['r']}';
    final tile = _capturedTiles[tileId];
    _captureController.startCapture(
      tileId: tileId,
      location: loc.currentLocation!,
      userId: auth!.user!.id,
      colorHex: auth.profile!.colorHex,
      duration: tile == null ? GameConstants.emptyTileDuration : GameConstants.enemyTileDuration,
    );
  }

  void toggleAutoCapture() {
    _isAutoCapture = !_isAutoCapture;
    notifyListeners();
  }

  void cycleMapStyle() {
    _currentMapStyleIndex =
        (_currentMapStyleIndex + 1) % GameConstants.mapStyles.length;
    notifyListeners();
  }

  void toggleBoundaries() {
    _showBoundaries = !_showBoundaries;
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _isNotificationEnabled = !_isNotificationEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifKey, _isNotificationEnabled);
    notifyListeners();
  }

  void addAlert(String message, AlertType type) {
    final alert = GameAlert.create(message: message, type: type);
    _alerts.insert(0, alert);
    if (_alerts.length > 5) _alerts.removeLast();
    notifyListeners();
    Timer(const Duration(seconds: 3), () => _removeAlert(alert.id));
  }

  void _removeAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    _tilesStreamSub?.cancel();
    _backgroundPollingTimer?.cancel(); // 타이머 해제
    _locationProvider?.removeListener(onLocationUpdated); // 리스너 해제 추가
    _captureController.dispose();
    super.dispose();
  }
}
