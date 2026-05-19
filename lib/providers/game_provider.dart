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
  static const String _rotationModeKey = 'conquest_map_rotation_enabled';

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
  int _currentMapStyleIndex = 0;
  bool _isNotificationEnabled = true;
  bool _isMapRotationMode = false; // 추가: 맵 회전(북쪽 고정) 여부

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
  int get currentMapStyleIndex => _currentMapStyleIndex;
  bool get isNotificationEnabled => _isNotificationEnabled;
  bool get isMapRotationMode => _isMapRotationMode; // 추가: 맵 회전 여부 getter
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
    if (isAlreadyCapturedByMe) {
      return false;
    }

    // [신규] 쉴드(보호) 시간 검증 추가
    final tile = currentTile;
    if (tile != null && tile.isShieldActive) {
      return false; // 아직 쉴드 시간이 경과하지 않았으므로 점령 불가!
    }

    return true;
  }

  /// 현재 내 GPS 위치에 대응하는 점령 타일 정보(HexTile)를 반환 (아직 점령되지 않았거나 GPS 미수신 상태이면 null 반환)
  HexTile? get currentTile {
    final loc = _locationProvider;
    if (loc?.currentLocation == null) return null;

    final hex = HexService.latLngToHex(loc!.currentLocation!);
    final tileId = 'hex_${hex['q']}_${hex['r']}';
    return _capturedTiles[tileId];
  }

  bool get isAlreadyCapturedByMe {
    final auth = _authProvider;
    if (auth?.user == null) return false;
    return currentTile?.userId == auth!.user!.id;
  }

  GameProvider({required SupabaseService supabase}) : _supabase = supabase {
    _captureController = CaptureController(
      supabase: supabase,
      onAlert: addAlert,
      onTileCaptured: (id, tile, {required bool wasEnemyTile}) {
        _capturedTiles[id] = tile;
        if (_isNotificationEnabled) {
          // 점령 유형에 따라 알림 문구 분기
          NotificationService().showLocalNotification(
            id: id.hashCode,
            title: wasEnemyTile
                ? GameStrings.notificationCaptureEnemyTitle
                : GameStrings.notificationCaptureEmptyTitle,
            body: wasEnemyTile
                ? GameStrings.notificationCaptureEnemyBody
                : GameStrings.notificationCaptureEmptyBody,
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
      _isMapRotationMode = prefs.getBool(_rotationModeKey) ?? false;

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

      // GPS가 정지 상태일 때도 점령 진입 로직이 실행되도록 강제 호출
      // (onLocationUpdated 내부의 3초 딜레이 스로틀로 서버 과부하 방지됨)
      onLocationUpdated();

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

    // 1. 상태 체크 (백그라운드 타이머 보정 + 실시간 구역 이탈 체크)
    _captureController.checkCaptureStatus(loc.currentLocation);

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

  /// 서버의 점령 상태 결과에 따라 점령 진행 여부를 판별하는 내부 로직
  Future<void> _processCaptureDecision(String tileId, TileStatus status) async {
    final loc = _locationProvider;
    final auth = _authProvider;
    if (loc == null ||
        auth == null ||
        auth.user == null ||
        auth.profile == null) {
      return;
    }

    // mine: 내 타일 → 점령 중단
    // empty/enemy: 점령 대상이므로 진행
    if (status == TileStatus.empty || status == TileStatus.enemy) {
      // 상대방 타일(enemy)일 때 쉴드 시간 검증
      if (status == TileStatus.enemy) {
        final tile = _capturedTiles[tileId];
        if (tile != null && tile.isShieldActive) {
          if (_captureController.capturingTileId == tileId) {
            _captureController.cancelCapture();
          }
          return;
        }
      }

      if (_isAutoCapture && !_captureController.isCapturing) {
        // 자동 점령 개시 직전, DB 서버에서 해당 타일의 실시간 최신 정보 강제 패치
        try {
          final serverTile = await _supabase.fetchTile(tileId);
          if (serverTile != null) {
            _capturedTiles[tileId] = serverTile;
          } else {
            _capturedTiles.remove(tileId);
          }
          notifyListeners();
        } catch (e) {
          debugPrint('자동 점령 전 서버 타일 정보 패치 실패: $e');
        }

        final int currentCaptureCount =
            _capturedTiles[tileId]?.captureCount ?? 0;
        final int targetCaptureCount = currentCaptureCount + 1;
        final int durationSeconds =
            GameConstants.initialCaptureDurationSeconds * targetCaptureCount;
        final Duration captureDuration = Duration(seconds: durationSeconds);

        _captureController.startCapture(
          tileId: tileId,
          location: loc.currentLocation!,
          userId: auth.user!.id,
          colorHex: auth.profile!.colorHex,
          duration: captureDuration,
          targetCaptureCount: targetCaptureCount,
          wasEnemyTile: status == TileStatus.enemy,
        );
      }
    } else {
      // 내 타일(mine)인 경우 기존 진행 중인 점령 취소
      if (_captureController.capturingTileId == tileId) {
        _captureController.cancelCapture();
      }
    }
  }

  /// 특정 타일의 남은 쉴드 보호 시간(초)을 반환 (0 이하이면 보호 만료)
  int getRemainingShieldSeconds(String tileId) {
    final tile = _capturedTiles[tileId];
    if (tile == null) return 0;

    final remaining = tile.shieldExpiration
        .difference(DateTime.now().toUtc())
        .inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  Future<void> startManualCapture() async {
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

    // 점령 시작 직전, DB 서버에서 해당 타일의 실시간 최신 정보 강제 패치
    try {
      final serverTile = await _supabase.fetchTile(tileId);
      if (serverTile != null) {
        _capturedTiles[tileId] = serverTile;
      } else {
        _capturedTiles.remove(tileId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('점령 시작 전 서버 타일 정보 패치 실패 (로컬 데이터로 대체 진행): $e');
    }

    final int currentCaptureCount = currentTile?.captureCount ?? 0;
    final int targetCaptureCount = currentCaptureCount + 1;
    final int durationSeconds =
        GameConstants.initialCaptureDurationSeconds * targetCaptureCount;
    final Duration captureDuration = Duration(seconds: durationSeconds);

    _captureController.startCapture(
      tileId: tileId,
      location: loc.currentLocation!,
      userId: auth!.user!.id,
      colorHex: auth.profile!.colorHex,
      duration: captureDuration,
      targetCaptureCount: targetCaptureCount,
      wasEnemyTile: currentTile != null, // 점령 전 타일이 존재하면 상대방 구역
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

  Future<void> toggleMapRotationMode() async {
    _isMapRotationMode = !_isMapRotationMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rotationModeKey, _isMapRotationMode);
    notifyListeners();
  }

  /// 현재 위치의 헥사곤 타일 점령 상태를 서버 기준으로 실시간 확인하는 함수
  Future<TileStatus> checkCurrentLocationTileStatusFromServer() async {
    final loc = _locationProvider;
    final auth = _authProvider;

    if (loc?.currentLocation == null || auth?.user == null) {
      return TileStatus.empty;
    }

    final hex = HexService.latLngToHex(loc!.currentLocation!);
    final tileId = 'hex_${hex['q']}_${hex['r']}';

    final status = await _supabase.checkTileStatusFromServer(
      tileId,
      auth!.user!.id,
    );

    // 상대방 구역(enemy)이면 최신 타일 정보로 즉시 갱신
    if (status == TileStatus.enemy) {
      final serverTile = await _supabase.fetchTile(tileId);
      if (serverTile != null) {
        _capturedTiles[tileId] = serverTile;
        notifyListeners();
        debugPrint(
          '🎨 [상대방 구역 갱신] 타일($tileId)을 상대방 점령색(${serverTile.colorHex})으로 실시간 갱신 완료.',
        );
      }
    }
    // 빈 구역(empty)인데 로컬에 잔재가 있으면 제거하여 동기화
    else if (status == TileStatus.empty) {
      if (_capturedTiles.containsKey(tileId)) {
        _capturedTiles.remove(tileId);
        notifyListeners();
        debugPrint('🎨 [중립 구역 갱신] 타일($tileId)이 빈 상태이므로 로컬에서 제거 완료.');
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
