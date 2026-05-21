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

  // --- 위성 스캔 상태 ---
  bool _isScanMode = false;
  String? _selectedScanTileId;

  // --- 위성 점령 상태 변수 ---
  String? _satelliteCapturingTileId;
  double _satelliteCaptureProgress = 0.0;
  Timer? _satelliteCaptureTimer;
  DateTime? _satelliteCaptureStartTime;
  Duration? _satelliteCaptureDuration;
  DateTime? _lastSatelliteCaptureTime;
  bool _isSavingSatellite = false;

  // --- 위치 변경 감지 시 서버 부하 방지용 3초 딜레이 타이머 ---
  DateTime? _lastServerCheckTime;

  // 관련 Provider 참조
  LocationProvider? _locationProvider;
  AuthProvider? _authProvider;

  // --- Getters ---
  Map<String, HexTile> get capturedTiles {
    return Map.unmodifiable(_capturedTiles);
  }

  bool get isScanMode => _isScanMode;
  String? get selectedScanTileId => _selectedScanTileId;

  String? get satelliteCapturingTileId => _satelliteCapturingTileId;
  double get satelliteCaptureProgress => _satelliteCaptureProgress;
  bool get isSatelliteCapturing => _satelliteCapturingTileId != null;
  DateTime? get lastSatelliteCaptureTime => _lastSatelliteCaptureTime;

  int get remainingSatelliteCaptureSeconds {
    if (_satelliteCapturingTileId == null || _satelliteCaptureStartTime == null || _satelliteCaptureDuration == null) {
      return 0;
    }
    final elapsed = DateTime.now().difference(_satelliteCaptureStartTime!);
    final remaining = _satelliteCaptureDuration!.inSeconds - elapsed.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  int get remainingSatelliteCaptureCoolSeconds {
    if (_lastSatelliteCaptureTime == null) return 0;
    final diff = DateTime.now().difference(_lastSatelliteCaptureTime!);
    final remaining = GameConstants.satelliteCaptureCooltime.inSeconds - diff.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

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

      final lastSatCapTimeStr = prefs.getString('hq_last_satellite_capture_time');
      if (lastSatCapTimeStr != null) {
        _lastSatelliteCaptureTime = DateTime.parse(lastSatCapTimeStr);
      }

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
    bool hqInvasionDetected = false;

    for (final tile in tiles) {
      // 1. 침공 감지: 기존에 내 땅이었는데 주인이 바뀐 경우
      final oldTile = _capturedTiles[tile.id];
      if (oldTile != null &&
          oldTile.userId == auth!.user!.id &&
          tile.userId != auth.user!.id) {
        if (auth.profile?.mainBaseTileId == tile.id) {
          hqInvasionDetected = true;
        } else {
          invasionDetected = true;
        }
      }

      _capturedTiles[tile.id] = tile;
      changed = true;
    }

    if (hqInvasionDetected) {
      // 메인 기지 침공 알림 발송
      NotificationService().showLocalNotification(
        id: 9999,
        title: GameStrings.hqInvasionNotifTitle,
        body: GameStrings.hqInvasionNotifBody,
      );
      addAlert(GameStrings.hqInvasionAlert, AlertType.error);
    } else if (invasionDetected) {
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
      // 위성 점령 진행 중일 때, 기지 침공이나 영토 분실 등으로 연결성이 끊어졌는지 실시간 체크
      if (isSatelliteCapturing) {
        final stillConnected = checkSatelliteCaptureConnectivity(_satelliteCapturingTileId!);
        if (!stillConnected) {
          cancelSatelliteCapture();
          addAlert(GameStrings.satelliteDisconnectedAlert, AlertType.error);
        }
      }
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

        // 물리 점령 개시 시점에 진행 중인 위성 점령이 있으면 중단
        cancelSatelliteCapture();

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

    // 물리 점령 개시 시점에 진행 중인 위성 점령이 있으면 중단
    cancelSatelliteCapture();

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
    _satelliteCaptureTimer?.cancel();
    _locationProvider?.removeListener(onLocationUpdated); // 리스너 해제 추가
    _captureController.dispose();
    super.dispose();
  }



  bool isHQOr1Ring(String tileId) {
    final mainBaseId = _authProvider?.profile?.mainBaseTileId;
    if (mainBaseId == null || mainBaseId.isEmpty) return false;

    final partsTarget = tileId.split('_');
    if (partsTarget.length != 3 || partsTarget[0] != 'hex') return false;
    final tq = int.tryParse(partsTarget[1]);
    final tr = int.tryParse(partsTarget[2]);

    final partsBase = mainBaseId.split('_');
    if (partsBase.length != 3 || partsBase[0] != 'hex') return false;
    final bq = int.tryParse(partsBase[1]);
    final br = int.tryParse(partsBase[2]);

    if (tq == null || tr == null || bq == null || br == null) return false;

    final dist = HexService.hexDistance(tq, tr, bq, br);
    return dist <= 1;
  }

  void toggleScanMode() {
    _isScanMode = !_isScanMode;
    _selectedScanTileId = null;
    notifyListeners();
  }

  void selectScanTile(String tileId) {
    if (!_isScanMode) return;
    _selectedScanTileId = tileId;
    notifyListeners();
  }

  /// 메인 기지로부터 내 점령지들을 타고 이웃하여 대상 빈 타일에 연결되는지 검사
  bool checkSatelliteCaptureConnectivity(String targetTileId) {
    final mainBaseId = _authProvider?.profile?.mainBaseTileId;
    final myId = _authProvider?.user?.id;
    if (mainBaseId == null || mainBaseId.isEmpty || myId == null) {
      return false;
    }

    // 대상 타일이 이미 내 소유라면 연결 검사 무의미
    final existingTile = _capturedTiles[targetTileId];
    if (existingTile != null && existingTile.userId == myId) {
      return false;
    }

    // 내 점령지 타일 ID 셋 구성
    final myTiles = _capturedTiles.values
        .where((t) => t.userId == myId)
        .map((t) => t.id)
        .toSet();

    // 메인 기지가 내 소유가 아니라면 출발 불가
    if (!myTiles.contains(mainBaseId)) {
      return false;
    }

    // BFS 탐색을 통한 연결성 검증
    final queue = <String>[mainBaseId];
    final visited = <String>{mainBaseId};

    const directions = [
      [1, 0],
      [1, -1],
      [0, -1],
      [-1, 0],
      [-1, 1],
      [0, 1],
    ];

    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);

      final parts = currentId.split('_');
      if (parts.length != 3 || parts[0] != 'hex') continue;
      final q = int.tryParse(parts[1]);
      final r = int.tryParse(parts[2]);
      if (q == null || r == null) continue;

      for (final dir in directions) {
        final nq = q + dir[0];
        final nr = r + dir[1];
        final neighborId = 'hex_${nq}_$nr';

        if (neighborId == targetTileId) {
          return true;
        }

        if (myTiles.contains(neighborId) && !visited.contains(neighborId)) {
          visited.add(neighborId);
          queue.add(neighborId);
        }
      }
    }

    return false;
  }

  /// 메인 기지와 대상 타일 간의 H3 거리에 따른 위성점령 소요 시간(초)을 계산
  int getSatelliteCaptureDurationSeconds(String tileId) {
    final mainBaseId = _authProvider?.profile?.mainBaseTileId;
    if (mainBaseId == null || mainBaseId.isEmpty) return 0;

    final partsBase = mainBaseId.split('_');
    final bq = int.tryParse(partsBase[1]);
    final br = int.tryParse(partsBase[2]);

    final partsTarget = tileId.split('_');
    final tq = int.tryParse(partsTarget[1]);
    final tr = int.tryParse(partsTarget[2]);

    if (bq == null || br == null || tq == null || tr == null) return 0;

    final dist = HexService.hexDistance(bq, br, tq, tr);
    final seconds = (dist * GameConstants.satelliteCaptureSecondsPerTile).round();
    return seconds < 1 ? 1 : seconds;
  }

  /// 위성 점령 프로세스 개시
  void executeSatelliteCapture(String tileId) {
    if (tileId.isEmpty || _isSavingSatellite) return;

    // 쿨타임 검증
    if (remainingSatelliteCaptureCoolSeconds > 0) {
      addAlert(GameStrings.satelliteCooltimeAlert, AlertType.error);
      return;
    }

    // 빈 타일 여부 검증 (이미 누군가가 점령했다면 불가능)
    final existingTile = _capturedTiles[tileId];
    final isTileEmpty = existingTile == null || existingTile.userId == null || existingTile.userId == 'none';
    if (!isTileEmpty) {
      addAlert(GameStrings.satelliteAlreadyCapturedAlert, AlertType.error);
      return;
    }

    // 연결성 검증
    if (!checkSatelliteCaptureConnectivity(tileId)) {
      addAlert(GameStrings.satelliteDisconnectedAlert, AlertType.error);
      return;
    }

    final mainBaseId = _authProvider?.profile?.mainBaseTileId;
    if (mainBaseId == null || mainBaseId.isEmpty) {
      addAlert(GameStrings.satelliteNoHQAlert, AlertType.error);
      return;
    }

    final partsBase = mainBaseId.split('_');
    final bq = int.tryParse(partsBase[1]);
    final br = int.tryParse(partsBase[2]);

    final partsTarget = tileId.split('_');
    final tq = int.tryParse(partsTarget[1]);
    final tr = int.tryParse(partsTarget[2]);

    if (bq == null || br == null || tq == null || tr == null) {
      addAlert(GameStrings.satelliteCoordError, AlertType.error);
      return;
    }

    // 거리에 비례하여 점령 소요 시간 계산 (1타일당 1초)
    final dist = HexService.hexDistance(bq, br, tq, tr);
    final seconds = (dist * GameConstants.satelliteCaptureSecondsPerTile).round();
    final duration = Duration(seconds: seconds < 1 ? 1 : seconds);

    // 물리 GPS 점령 진행 중인 경우 중단
    if (isCapturing) {
      _captureController.cancelCapture();
    }

    cancelSatelliteCapture();

    _satelliteCapturingTileId = tileId;
    _satelliteCaptureProgress = 0.0;
    _satelliteCaptureStartTime = DateTime.now();
    _satelliteCaptureDuration = duration;

    _satelliteCaptureTimer = Timer.periodic(
      const Duration(milliseconds: GameConstants.updateIntervalMs),
      (_) {
        if (_satelliteCapturingTileId == null || _isSavingSatellite) return;

        final elapsed = DateTime.now().difference(_satelliteCaptureStartTime!);
        _satelliteCaptureProgress = (elapsed.inMilliseconds / _satelliteCaptureDuration!.inMilliseconds).clamp(0.0, 1.0);

        if (_satelliteCaptureProgress >= 1.0) {
          _saveSatelliteCapture(tileId);
        } else {
          notifyListeners();
        }
      },
    );

    addAlert(GameStrings.satelliteCaptureStart(duration.inSeconds.toString()), AlertType.info);
    notifyListeners();
  }

  /// 현재 위성 점령 취소
  void cancelSatelliteCapture() {
    if (_isSavingSatellite) return;
    _satelliteCaptureTimer?.cancel();
    _satelliteCaptureTimer = null;
    _satelliteCapturingTileId = null;
    _satelliteCaptureProgress = 0.0;
    _satelliteCaptureDuration = null;
    _satelliteCaptureStartTime = null;
    notifyListeners();
  }

  /// 위성 점령 데이터 DB 저장 및 쿨타임 갱신
  Future<void> _saveSatelliteCapture(String tileId) async {
    if (_isSavingSatellite) return;
    _isSavingSatellite = true;
    _satelliteCaptureTimer?.cancel();

    final myId = _authProvider?.user?.id;
    final myColor = _authProvider?.profile?.colorHex;

    if (myId == null || myColor == null) {
      addAlert(GameStrings.satelliteUserInvalid, AlertType.error);
      _isSavingSatellite = false;
      cancelSatelliteCapture();
      return;
    }

    final parts = tileId.split('_');
    final q = int.tryParse(parts[1]) ?? 0;
    final r = int.tryParse(parts[2]) ?? 0;

    final tile = HexTile(
      id: tileId,
      q: q,
      r: r,
      userId: myId,
      colorHex: myColor,
      bounds: HexService.getHexCorners(q, r).map((l) => [l.latitude, l.longitude]).toList(),
      capturedAt: DateTime.now().toUtc(),
      captureCount: 1, // 위성 점령은 점령 카운트 1로 초기화 (또는 고정)
    );

    final success = await _supabase.captureTile(tile);
    if (success) {
      _lastSatelliteCaptureTime = DateTime.now();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('hq_last_satellite_capture_time', _lastSatelliteCaptureTime!.toIso8601String());
      } catch (e) {
        debugPrint('SharedPreferences 쿨타임 저장 실패: $e');
      }

      _capturedTiles[tileId] = tile;
      addAlert(GameStrings.satelliteCaptureSuccess, AlertType.success);
    } else {
      addAlert(GameStrings.satelliteCaptureFail, AlertType.error);
    }

    _isSavingSatellite = false;
    _satelliteCapturingTileId = null;
    _satelliteCaptureProgress = 0.0;
    _satelliteCaptureDuration = null;
    _satelliteCaptureStartTime = null;
    notifyListeners();
  }
}
