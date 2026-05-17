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
import '../core/constants/strings.dart';

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

  // --- 위치 변경 감지 시 서버 부하 방지용 3초 딜레이 타이머 ---
  DateTime? _lastServerCheckTime;

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
            title: GameStrings.notificationCaptureSuccessTitle,
            body: GameStrings.notificationCaptureSuccessBody,
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
        title: GameStrings.notificationInvasionTitle,
        body: GameStrings.notificationInvasionBody,
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

    // 2. 오직 순수하게 지정된 간격(딜레이)으로만 현재 위치 타일 상태를 서버에 확인하여 진행
    final now = DateTime.now();
    if (_lastServerCheckTime == null ||
        now.difference(_lastServerCheckTime!) >=
            GameConstants.serverCheckDelay) {
      _lastServerCheckTime = now;

      checkCurrentLocationTileStatusFromServer().then((status) {
        _processCaptureDecision(tileId, status);
      });
    }
  }

  /// 서버의 점령 상태 결과(0: 내타일, 1: 빈타일, 2: 상대방타일)에 따라 점령 진행 여부를 판별하는 내부 로직
  void _processCaptureDecision(String tileId, int status) {
    final loc = _locationProvider;
    final auth = _authProvider;
    if (loc == null ||
        auth == null ||
        auth.user == null ||
        auth.profile == null)
      return;

    // status: 0(내 타일) -> 점령 중단
    // status: 1(빈 타일) 또는 2(상대방 타일) -> 점령 대상이므로 진행!
    if (status == 1 || status == 2) {
      if (_isAutoCapture && !_captureController.isCapturing) {
        _captureController.startCapture(
          tileId: tileId,
          location: loc.currentLocation!,
          userId: auth.user!.id,
          colorHex: auth.profile!.colorHex,
          duration: status == 1
              ? GameConstants.emptyTileDuration
              : GameConstants.enemyTileDuration,
        );
      }
    } else {
      // 내 타일(0)인 경우 기존 진행 중인 점령 취소
      if (_captureController.capturingTileId == tileId) {
        _captureController.cancelCapture();
      }
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
      duration: tile == null
          ? GameConstants.emptyTileDuration
          : GameConstants.enemyTileDuration,
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

  /// 현재 위치의 헥사곤 타일 점령 상태를 서버 기준으로 실시간 확인하는 함수
  /// - 1: 아직 아무도 점령하지 않은 빈 타일 (중립)
  /// - 2: 상대방이 점령한 타일
  /// - 0: 내가 점령한 타일
  Future<int> checkCurrentLocationTileStatusFromServer() async {
    final loc = _locationProvider;
    final auth = _authProvider;

    if (loc?.currentLocation == null || auth?.user == null) {
      return 1; // 위치나 로그인 정보 부재 시 기본적으로 1(빈 타일) 반환
    }

    final hex = HexService.latLngToHex(loc!.currentLocation!);
    final tileId = 'hex_${hex['q']}_${hex['r']}';

    final status = await _supabase.checkTileStatusFromServer(
      tileId,
      auth!.user!.id,
    );

    // 1. 상대방 점령 지역(status == 2)이면 최신 타일 정보(상대 점령색 포함)로 즉시 갱신
    if (status == 2) {
      final serverTile = await _supabase.fetchTile(tileId);
      if (serverTile != null) {
        _capturedTiles[tileId] = serverTile;
        notifyListeners();
        debugPrint(
          '🎨 [상대방 영토 갱신] 타일($tileId)을 상대방 점령색(${serverTile.colorHex})으로 실시간 갱신 완료.',
        );
      }
    }
    // 2. 만약 아무도 점령하지 않은 빈 지역(status == 1)인데 로컬에 잔재가 있으면 제거하여 동기화
    else if (status == 1) {
      if (_capturedTiles.containsKey(tileId)) {
        _capturedTiles.remove(tileId);
        notifyListeners();
        debugPrint('🎨 [중립 영토 갱신] 타일($tileId)이 빈 상태이므로 로컬에서 제거 완료.');
      }
    }

    return status;
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
