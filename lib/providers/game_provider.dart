import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/capture_controller.dart';
import '../models/alert_model.dart';
import '../models/tile_model.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart';
import '../services/hex_service.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../core/constants/game_config.dart';
import '../core/constants/map_config.dart';
import '../core/constants/strings.dart';

/// 위성 원격 점령의 진행 단계를 구분하는 상태 열거형
enum SatelliteCapturePhase {
  /// 대기 상태
  none,
  /// 본진에서 대상 타일까지 빔 화살표가 날아가는 상태
  flying,
  /// 빔 도착 후 타일을 점령(오렌지 게이지 누적) 중인 상태
  capturing,
}

/// 게임의 핵심 인게임 비즈니스 상태 및 점령 로직을 관리하고 UI에 변경을 전파하는 메인 프로바이더 클래스
class GameProvider extends ChangeNotifier with WidgetsBindingObserver {
  /// 로컬 저장소에 저장될 알림 설정 키
  static const String _notifKey = 'conquest_notifications_enabled';
  /// 로컬 저장소에 저장될 영토 침공 알림 키
  static const String _notifTerritoryAttackKey = 'conquest_notif_territory_attack';
  /// 로컬 저장소에 저장될 위성 점령 완료 알림 키
  static const String _notifSatelliteCompleteKey = 'conquest_notif_satellite_complete';
  /// 로컬 저장소에 저장될 시스템 공지 알림 키
  static const String _notifSystemNoticeKey = 'conquest_notif_system_notice';
  /// 로컬 저장소에 저장될 지도 회전 설정 키
  static const String _rotationModeKey = 'conquest_map_rotation_enabled';

  /// Supabase 데이터베이스 서비스 인스턴스
  final SupabaseService _supabase;
  /// 영토 점령 과정을 제어하는 컨트롤러
  late final CaptureController _captureController;
  /// 실시간 점령 타일 목록 스트림 구독 객체
  StreamSubscription<List<HexTile>>? _tilesStreamSub;
  /// 백그라운드 점령 및 침공 상태 정기 검사를 수행하는 타이머
  Timer? _backgroundPollingTimer;
  /// 초기화 완료 처리를 조율하는 Completer 객체
  final Completer<void> _initCompleter = Completer<void>();

  // --- 상태 ---
  /// 점령된 타일 목록 (Key: 타일 ID, Value: 타일 상세 모델)
  final Map<String, HexTile> _capturedTiles = {};
  /// 화면 상단에 표시될 전술 알림/경고 목록
  final List<GameAlert> _alerts = [];
  /// 프로바이더 내부 데이터 초기화 완료 여부
  bool _isInitialized = false;
  /// 자동 점령 모드 활성화 여부
  bool _isAutoCapture = false;
  /// 현재 적용 중인 지도 스타일 인덱스
  int _currentMapStyleIndex = 0;
  /// 알림 수신 동의 여부
  bool _isNotificationEnabled = true;
  /// 영토 침공 알림 여부
  bool _isNotifTerritoryAttack = true;
  /// 위성 점령 완료 알림 여부
  bool _isNotifSatelliteComplete = true;
  /// 시스템 공지 알림 여부
  bool _isNotifSystemNotice = true;
  /// 지도 회전 모드(나침반 정렬) 사용 여부
  bool _isMapRotationMode = false;

  // --- 위성 스캔 상태 ---
  /// 위성 궤도 정밀 스캔 모드 활성화 여부
  bool _isScanMode = false;
  /// 위성 스캔 조준 중인 대상 타일 ID
  String? _selectedScanTileId;
  /// 위성 스캔 조준 타일의 중심 지리 좌표 (맭 스크롤 시 실시간 화면 좌표 변환에 사용)
  LatLng? _selectedScanTileLatLng;

  // --- 위성 점령 상태 변수 ---
  /// 현재 위성 점령의 상태 단계
  SatelliteCapturePhase _satelliteCapturePhase = SatelliteCapturePhase.none;
  /// 현재 위성 점령을 시도 중인 대상 타일 ID
  String? _satelliteCapturingTileId;
  /// 위성 빔 비행 진행률 (0.0 ~ 1.0)
  double _satelliteTravelProgress = 0.0;
  /// 위성 원격 타일 점령 진행률 (0.0 ~ 1.0)
  double _satelliteCaptureProgress = 0.0;
  /// 위성 점령 주기 업데이트 타이머
  Timer? _satelliteCaptureTimer;
  /// 위성 점령 특정 단계(비행 또는 점령)를 시작한 일시
  DateTime? _satellitePhaseStartTime;
  /// 위성 빔 비행 완료에 소요되는 총 시간
  Duration? _satelliteTravelDuration;
  /// 위성 타일 점령 완료에 소요되는 총 시간
  Duration? _satelliteCaptureDuration;
  /// 마지막으로 성공한 위성 점령 일시
  DateTime? _lastSatelliteCaptureTime;
  /// 위성 점령 정보의 서버 저장 진행 여부
  bool _isSavingSatellite = false;

  // --- 위치 변경 감지 시 서버 부하 방지용 3초 딜레이 타이머 ---
  /// 서버 부하 방지를 위해 마지막으로 위치 상태를 조정한 일시
  DateTime? _lastServerCheckTime;

  // --- 재화(골드) 상태 변수 ---
  /// 현재 보유 중인 골드 재화 잔액
  double _currentGold = 0.0;
  /// 초당 골드 생산율
  double _goldRate = GameConfig.defaultGoldRate;
  /// 주기적으로 골드 재화를 누적하는 타이머
  Timer? _goldTimer;
  /// 주기적 서버 동기화를 위한 1초 단위 누적 카운터
  int _syncCounter = 0;

  // 관련 Provider 참조
  /// 사용자 위치 정보를 공유하는 LocationProvider 인스턴스
  LocationProvider? _locationProvider;
  /// 사용자 인증 상태 정보를 공유하는 AuthProvider 인스턴스
  AuthProvider? _authProvider;

  // --- Getters ---
  /// 실시간 점령된 타일 정보를 담은 불변 Map을 반환합니다.
  Map<String, HexTile> get capturedTiles {
    return Map.unmodifiable(_capturedTiles);
  }

  /// 현재 보유 중인 골드 재화 수량
  double get currentGold => _currentGold;

  /// 초당 골드 획득율 배율
  double get goldRate => _goldRate;

  /// 위성 정밀 조준 스캔 모드 활성화 여부
  bool get isScanMode => _isScanMode;

  /// 위성 조준 스캔 상에서 선택된 타일 ID
  String? get selectedScanTileId => _selectedScanTileId;

  /// 선택된 위성 조준 타일의 중심 지리 좌표 (맵 스크롤 시 실시간 화면 좌표 변환에 사용)
  LatLng? get selectedScanTileLatLng => _selectedScanTileLatLng;

  /// 현재 위성 점령의 상태 단계 반환
  SatelliteCapturePhase get satelliteCapturePhase => _satelliteCapturePhase;

  /// 현재 위성 점령 진행 중인 타일 ID
  String? get satelliteCapturingTileId => _satelliteCapturingTileId;

  /// 위성 빔 비행 진행률 (0.0 ~ 1.0)
  double get satelliteTravelProgress => _satelliteTravelProgress;

  /// 위성 점령 진행률 (0.0 ~ 1.0)
  double get satelliteCaptureProgress => _satelliteCaptureProgress;

  /// 위성 점령 시도가 활성화 중인지 여부
  bool get isSatelliteCapturing => _satelliteCapturePhase != SatelliteCapturePhase.none;

  /// 마지막으로 위성 점령에 성공한 일시
  DateTime? get lastSatelliteCaptureTime => _lastSatelliteCaptureTime;

  /// 위성 점령이 완료될 때까지 남은 초 단위 시간 (비행 시간과 점령 시간의 잔여분 합산)
  int get remainingSatelliteCaptureSeconds {
    if (_satelliteCapturePhase == SatelliteCapturePhase.none || _satellitePhaseStartTime == null) {
      return 0;
    }
    final now = DateTime.now();
    if (_satelliteCapturePhase == SatelliteCapturePhase.flying) {
      final elapsed = now.difference(_satellitePhaseStartTime!);
      final remainingTravel = (_satelliteTravelDuration!.inSeconds - elapsed.inSeconds).clamp(0, double.infinity).toInt();
      final remainingCapture = _satelliteCaptureDuration!.inSeconds;
      return remainingTravel + remainingCapture;
    } else {
      final elapsed = now.difference(_satellitePhaseStartTime!);
      final remainingCapture = (_satelliteCaptureDuration!.inSeconds - elapsed.inSeconds).clamp(0, double.infinity).toInt();
      return remainingCapture;
    }
  }

  /// 위성 조준 장비의 재충전 쿨타임 남은 시간 (초)
  int get remainingSatelliteCaptureCoolSeconds {
    if (_lastSatelliteCaptureTime == null) return 0;
    final diff = DateTime.now().difference(_lastSatelliteCaptureTime!);
    final remaining = GameConfig.satelliteCaptureCooltime.inSeconds - diff.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// 인게임 전술 상황판 알림 목록
  List<GameAlert> get alerts => List.unmodifiable(_alerts);

  /// 로컬 및 서버 상태 초기화 완료 여부
  bool get isInitialized => _isInitialized;

  /// 자동 점령 모드 활성화 여부
  bool get isAutoCapture => _isAutoCapture;

  /// 현재 활성화된 타일 지도 스타일의 인덱스
  int get currentMapStyleIndex => _currentMapStyleIndex;

  /// 로컬 푸시 알림 허용 여부
  bool get isNotificationEnabled => _isNotificationEnabled;

  /// 영토 침공 알림 수신 여부
  bool get isNotifTerritoryAttack => _isNotifTerritoryAttack;

  /// 위성 점령 완료 알림 수신 여부
  bool get isNotifSatelliteComplete => _isNotifSatelliteComplete;

  /// 시스템 공지 알림 수신 여부
  bool get isNotifSystemNotice => _isNotifSystemNotice;

  /// 지도 회전 모드(나침반 방향에 연동) 활성화 여부
  bool get isMapRotationMode => _isMapRotationMode; // 추가: 맵 회전 여부 getter

  /// 현재 지정된 지도 스타일 환경 설정
  MapStyle get currentMapStyle =>
      MapConfig.mapStyles[_currentMapStyleIndex];

  /// 지도를 실제로 렌더링해야 하는지의 여부
  bool get showMap => currentMapStyle.url.isNotEmpty;

  /// 본인 요원(계정)이 획득한 영토(타일)의 총 개수
  int get myCapturedCount => _authProvider?.user?.id == null
      ? 0
      : _capturedTiles.values
            .where((t) => t.userId == _authProvider!.user!.id)
            .length;

  /// 현재 물리 GPS 점령을 시도 중인 타일 ID
  String? get capturingTileId => _captureController.capturingTileId;

  /// 현재 점령 진행 중인 타일 요원의 전술 컬러 코드
  String? get capturingColorHex => _captureController.capturingColorHex;

  /// 물리 GPS 점령의 진행 진척도 (0.0 ~ 1.0)
  double get captureProgress => _captureController.captureProgress;

  /// 물리 GPS 점령 작전이 실행 중인지 여부
  bool get isCapturing => _captureController.isCapturing;

  /// 현재 요원의 상태와 GPS 수신 상태를 기반으로 점령 개시가 가능한 상태인지 판단합니다.
  bool get canCapture {
    final loc = _locationProvider;
    final auth = _authProvider;

    if (loc == null || !loc.isGpsActive || loc.currentLocation == null) {
      return false;
    }

    // GPS 오차가 너무 크면 점령 불가
    if (loc.currentAccuracy > GameConfig.captureAccuracyThreshold) {
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

  /// 현재 GPS 위치에 대응하는 점령 타일 정보(HexTile)를 반환 (아직 점령되지 않았거나 GPS 미수신 상태이면 null 반환)
  HexTile? get currentTile {
    final loc = _locationProvider;
    if (loc?.currentLocation == null) return null;

    final hex = HexService.latLngToHex(loc!.currentLocation!);
    final tileId = 'hex_${hex['q']}_${hex['r']}';
    return _capturedTiles[tileId];
  }

  /// 현재 위치한 타일이 이미 자신이 지배 중인 타일인지 여부
  bool get isAlreadyCapturedByMe {
    final auth = _authProvider;
    if (auth?.user == null) return false;
    return currentTile?.userId == auth!.user!.id;
  }

  /// GameProvider 생성자로 초기 점령 컨트롤러 설정 및 로컬 데이터 동기화를 지시합니다.
  GameProvider({required SupabaseService supabase}) : _supabase = supabase {
    WidgetsBinding.instance.addObserver(this);
    _captureController = CaptureController(
      supabase: supabase,
      onAlert: addAlert,
      onTileCaptured: (id, tile, {required bool wasEnemyTile}) {
        _capturedTiles[id] = tile;
        if (_isNotificationEnabled) {
          // 점령 유형에 따라 알림 문구 분기
          NotificationService().showLocalNotification(
            id: id.hashCode,
            title: GameStrings.notificationCaptureEmptyTitle,
            body: GameStrings.notificationCaptureEmptyBody,
          );
        }
        syncGoldWithServer();
        notifyListeners();
      },
      onPreCapture: _persistGoldToServer,
      onStateChanged: notifyListeners,
    );
    _init();
  }

  /// 위치 관리 프로바이더([LocationProvider]) 인스턴스를 설정하고 상태 업데이트 리스너를 연동합니다.
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

  /// 사용자 인증 관리 프로바이더([AuthProvider])를 설정하고 로그인 세션 여부에 따라 골드 생산 타이머를 가동/종료합니다.
  void setAuthProvider(AuthProvider auth) {
    final oldProfile = _authProvider?.profile;
    _authProvider = auth;
    
    if (auth.isAuthenticated) {
      // 1. 프로필이 null이었다가 최초 로드(비동기 완료)된 시점
      // 2. 혹은 골드 타이머가 실행 중이지 않은 상태일 때 동기화 트리거
      if ((oldProfile == null && auth.profile != null) || (_goldTimer == null || !_goldTimer!.isActive)) {
        syncGoldWithServer();
      }
    } else {
      _goldTimer?.cancel();
      _goldTimer = null;
      _currentGold = 0.0;
    }
    notifyListeners();
  }

  /// 프로바이더의 비동기 초기 데이터 설정 및 로드가 완전히 완료되었는지 감시할 수 있는 Future 객체
  Future<void> get initializationFuture => _initCompleter.future;

  /// 초기 설정을 불러오고, 기점령 타일 정보 획득 및 Supabase 실시간 타일 스트림을 연결합니다.
  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isNotificationEnabled = prefs.getBool(_notifKey) ?? true;
      _isNotifTerritoryAttack = prefs.getBool(_notifTerritoryAttackKey) ?? true;
      _isNotifSatelliteComplete = prefs.getBool(_notifSatelliteCompleteKey) ?? true;
      _isNotifSystemNotice = prefs.getBool(_notifSystemNoticeKey) ?? true;
      _isMapRotationMode = prefs.getBool(_rotationModeKey) ?? false;

      // FCM 알림 구독 동기화 기동
      _updateFcmSubscriptions();

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
      if (_authProvider?.isAuthenticated == true) {
        syncGoldWithServer();
      }
      notifyListeners();
    }
    _tilesStreamSub = _supabase.capturedTilesStream.listen(_onTilesUpdated);
    _startBackgroundPolling(); // 추가: 주기적 감시 시작
  }

  /// 백그라운드에서도 정해진 주기마다 서버 데이터를 강제로 갱신하는 로직을 구동합니다.
  void _startBackgroundPolling() {
    _backgroundPollingTimer?.cancel();
    _backgroundPollingTimer = Timer.periodic(
      GameConfig.backgroundCheckInterval,
      (_) => _refreshTilesAndCheckInvasion(),
    );
  }

  /// 서버에서 최신 타일 정보를 가져와 침공 여부를 강제로 체크하고 내 위치 타일을 갱신합니다.
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

  /// 실시간 DB 변경 스트림을 통해 점령 타일 목록이 업데이트되었을 때 침공을 감지하고,
  /// 잃은 영토로 인해 위성 점령의 연결성(Connectivity)이 상실되었는지 실시간으로 검사합니다.
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
            GameConfig.serverCheckDelay) {
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
            GameConfig.initialCaptureDurationSeconds * targetCaptureCount;
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
  /// 특정 타일의 남은 쉴드 보호 시간(초)을 반환 (0 이하이면 보호 만료)
  int getRemainingShieldSeconds(String tileId) {
    final tile = _capturedTiles[tileId];
    if (tile == null) return 0;

    final remaining = tile.shieldExpiration
        .difference(DateTime.now().toUtc())
        .inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// 사용자가 수동 모드 상태에서 즉시 수동 점령을 개시합니다.
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
        GameConfig.initialCaptureDurationSeconds * targetCaptureCount;
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

  /// 자동 점령 작전의 활성/비활성 여부를 토글합니다.
  void toggleAutoCapture() {
    _isAutoCapture = !_isAutoCapture;
    notifyListeners();
  }

  /// 지도 배경 스타일(다크, 사이버펑크, 위성 등)을 순환 변경합니다.
  void cycleMapStyle() {
    _currentMapStyleIndex =
        (_currentMapStyleIndex + 1) % MapConfig.mapStyles.length;
    notifyListeners();
  }

  /// 지도 회전 모드(나침반 헤딩 동기화)를 활성화/비활성화하고 내부 설정을 SharedPreferences에 유지합니다.
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

  /// 알림 수신 동의 여부를 전환하고 변경 설정을 디바이스 로컬 저장소에 보관합니다.
  Future<void> toggleNotifications() async {
    _isNotificationEnabled = !_isNotificationEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifKey, _isNotificationEnabled);
    notifyListeners();
    await _updateFcmSubscriptions();
  }

  /// 영토 침공 알림 여부를 토글합니다.
  Future<void> toggleNotifTerritoryAttack() async {
    _isNotifTerritoryAttack = !_isNotifTerritoryAttack;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifTerritoryAttackKey, _isNotifTerritoryAttack);
    notifyListeners();
    await _updateFcmSubscriptions();
  }

  /// 위성 점령 완료 알림 여부를 토글합니다.
  Future<void> toggleNotifSatelliteComplete() async {
    _isNotifSatelliteComplete = !_isNotifSatelliteComplete;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifSatelliteCompleteKey, _isNotifSatelliteComplete);
    notifyListeners();
    await _updateFcmSubscriptions();
  }

  /// 시스템 공지 알림 여부를 토글합니다.
  Future<void> toggleNotifSystemNotice() async {
    _isNotifSystemNotice = !_isNotifSystemNotice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifSystemNoticeKey, _isNotifSystemNotice);
    notifyListeners();
    await _updateFcmSubscriptions();
  }

  /// SharedPreferences 상태 및 마스터 알림 여부에 맞춰 FCM 구독 토픽을 최신화합니다.
  Future<void> _updateFcmSubscriptions() async {
    final ns = NotificationService();
    if (!ns.isInitialized) {
      await ns.initialize();
    }

    const String topicTerritory = 'conquest_territory_attack';
    const String topicSatellite = 'conquest_satellite_complete';
    const String topicNotice = 'conquest_system_notice';

    if (!_isNotificationEnabled) {
      // 마스터 알림이 꺼진 경우 모든 개별 토픽 일제 구독 해제
      await ns.unsubscribeFromTopic(topicTerritory);
      await ns.unsubscribeFromTopic(topicSatellite);
      await ns.unsubscribeFromTopic(topicNotice);
      debugPrint('🔔 [FCM 구독 통제] 마스터 해제로 인한 모든 토픽 구독 해제 완료.');
      return;
    }

    // 영토 침공 알림
    if (_isNotifTerritoryAttack) {
      await ns.subscribeToTopic(topicTerritory);
    } else {
      await ns.unsubscribeFromTopic(topicTerritory);
    }

    // 위성 점령 완료 알림
    if (_isNotifSatelliteComplete) {
      await ns.subscribeToTopic(topicSatellite);
    } else {
      await ns.unsubscribeFromTopic(topicSatellite);
    }

    // 시스템 공지 알림
    if (_isNotifSystemNotice) {
      await ns.subscribeToTopic(topicNotice);
    } else {
      await ns.unsubscribeFromTopic(topicNotice);
    }
    debugPrint('🔔 [FCM 구독 통제] 개별 설정 최신화 완료 (영토: $_isNotifTerritoryAttack, 위성: $_isNotifSatelliteComplete, 공지: $_isNotifSystemNotice)');
  }

  /// 화면 상단에 표시될 새 경고/알림 팝업 메시지를 발행하고 3초 경과 후 자동 페이드아웃 되도록 타이머를 연동합니다.
  void addAlert(String message, AlertType type) {
    final alert = GameAlert.create(message: message, type: type);
    _alerts.insert(0, alert);
    if (_alerts.length > 5) _alerts.removeLast();
    notifyListeners();
    Timer(const Duration(seconds: 3), () => _removeAlert(alert.id));
  }

  /// 알림 목록에서 특정 ID의 경고 알림을 제거하고 화면을 갱신합니다.
  void _removeAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _goldTimer?.cancel();
    _tilesStreamSub?.cancel();
    _backgroundPollingTimer?.cancel(); // 타이머 해제
    _satelliteCaptureTimer?.cancel();
    _locationProvider?.removeListener(onLocationUpdated); // 리스너 해제 추가
    _captureController.dispose();
    super.dispose();
  }



  /// 지정한 타일이 본진 기지이거나 본진을 직간접으로 둘러싼 인접 1링(Ring) 범위에 포함되는지 확인합니다.
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

  /// 위성 궤도 스캔 모드의 On/Off 여부를 전환합니다.
  void toggleScanMode() {
    _isScanMode = !_isScanMode;
    _selectedScanTileId = null;
    notifyListeners();
  }

  /// 위성 스캔 화면 상에서 조준점으로 지정할 대상 헥사곤 타일을 선택 조준합니다.
  /// 이미 선택된 타일을 다시 선택하는 경우 조준을 해제합니다.
  void selectScanTile(String tileId) {
    if (!_isScanMode) return;
    if (_selectedScanTileId == tileId) {
      _selectedScanTileId = null;
      _selectedScanTileLatLng = null;
    } else {
      _selectedScanTileId = tileId;
      // tileId 형식: 'hex_q_r'
      final parts = tileId.split('_');
      if (parts.length == 3) {
        final q = int.tryParse(parts[1]);
        final r = int.tryParse(parts[2]);
        if (q != null && r != null) {
          _selectedScanTileLatLng = HexService.hexToLatLng(q, r);
        }
      }
    }
    notifyListeners();
  }

  /// 본진 기지를 시발점으로 하여 요원이 지배 중인 타일 그리드를 거쳐 대상 영토까지 끊어짐 없이 헥사 결합되어 연결되는지 BFS(너비 우선 탐색)로 무결성을 검증합니다.
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

    // 본진 타일은 소유 여부와 관계없이 BFS 탐색을 위한 연결 통로로 강제 포함
    final effectiveMyTiles = {...myTiles, mainBaseId};

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

        if (effectiveMyTiles.contains(neighborId) && !visited.contains(neighborId)) {
          visited.add(neighborId);
          queue.add(neighborId);
        }
      }
    }

    return false;
  }

  /// 본진(HQ) 타일과 대상 타일 간의 H3 헥사곤 거리를 산출하여 위성 점령 완료에 소요될 지연 시간(초)을 계산합니다.
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
    final travelSeconds = dist;
    const captureSeconds = 1; // 점령 고유 소요시간 1초
    return travelSeconds + captureSeconds;
  }

  /// 본진(HQ) 타일과 대상 타일 간의 거리를 기준으로 하여, 위성 점령의 총 시간 중 '이동(비행) 시간'이 차지하는 비율을 산출합니다.
  double getSatelliteTravelRatio(String tileId) {
    final mainBaseId = _authProvider?.profile?.mainBaseTileId;
    if (mainBaseId == null || mainBaseId.isEmpty) return 0.8;

    final partsBase = mainBaseId.split('_');
    final bq = int.tryParse(partsBase[1]);
    final br = int.tryParse(partsBase[2]);

    final partsTarget = tileId.split('_');
    final tq = int.tryParse(partsTarget[1]);
    final tr = int.tryParse(partsTarget[2]);

    if (bq == null || br == null || tq == null || tr == null) return 0.8;

    final dist = HexService.hexDistance(bq, br, tq, tr);
    final travelSeconds = dist.toDouble();
    const captureSeconds = 1.0; // 점령 고유 소요시간 1초
    final total = travelSeconds + captureSeconds;
    return total > 0.0 ? (travelSeconds / total) : 0.8;
  }

  /// 지정한 대상 헥사곤 타일에 대한 위성 연결 점령(Satellite Capture) 타이머를 구동하여 점령을 실행합니다.
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

    // 위성 점령 소모 재화 부족 검증 (거리가 D이면 D GP 소모)
    if (_currentGold < dist) {
      addAlert('위성 점령 재화가 부족합니다 (필요: $dist GP / 보유: ${_currentGold.toInt()} GP)', AlertType.error);
      return;
    }

    final travelSeconds = dist;
    const captureSeconds = 1; // 점령 고유 소요시간 1초

    // 물리 GPS 점령 진행 중인 경우 중단
    if (isCapturing) {
      _captureController.cancelCapture();
    }

    cancelSatelliteCapture();

    _satelliteCapturingTileId = tileId;
    _satelliteCapturePhase = SatelliteCapturePhase.flying;
    _satelliteTravelProgress = 0.0;
    _satelliteCaptureProgress = 0.0;
    _satellitePhaseStartTime = DateTime.now();
    _satelliteTravelDuration = Duration(seconds: travelSeconds < 1 ? 1 : travelSeconds);
    _satelliteCaptureDuration = const Duration(seconds: captureSeconds);

    _satelliteCaptureTimer = Timer.periodic(
      const Duration(milliseconds: GameConfig.updateIntervalMs),
      (_) {
        if (_satelliteCapturingTileId == null || _isSavingSatellite) return;

        final now = DateTime.now();
        if (_satelliteCapturePhase == SatelliteCapturePhase.flying) {
          final elapsed = now.difference(_satellitePhaseStartTime!);
          _satelliteTravelProgress = (elapsed.inMilliseconds / _satelliteTravelDuration!.inMilliseconds).clamp(0.0, 1.0);

          if (_satelliteTravelProgress >= 1.0) {
            // 1단계 비행 완료 ➔ 2단계 실제 점령 모드로 순차 전환!
            _satelliteCapturePhase = SatelliteCapturePhase.capturing;
            _satellitePhaseStartTime = now;
            _satelliteCaptureProgress = 0.0;
          }
          notifyListeners();
        } else if (_satelliteCapturePhase == SatelliteCapturePhase.capturing) {
          final elapsed = now.difference(_satellitePhaseStartTime!);
          _satelliteCaptureProgress = (elapsed.inMilliseconds / _satelliteCaptureDuration!.inMilliseconds).clamp(0.0, 1.0);

          if (_satelliteCaptureProgress >= 1.0) {
            _saveSatelliteCapture(tileId);
          } else {
            notifyListeners();
          }
        }
      },
    );

    notifyListeners();
  }

  /// 현재 시도 중인 위성 원격 점령 지연 프로세스를 중단하고 취소합니다.
  void cancelSatelliteCapture() {
    if (_isSavingSatellite) return;
    _satelliteCaptureTimer?.cancel();
    _satelliteCaptureTimer = null;
    _satelliteCapturingTileId = null;
    _satelliteCapturePhase = SatelliteCapturePhase.none;
    _satelliteTravelProgress = 0.0;
    _satelliteCaptureProgress = 0.0;
    _satelliteTravelDuration = null;
    _satelliteCaptureDuration = null;
    _satellitePhaseStartTime = null;
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

    // [신규] DB에 위성 점령 레코드를 쓰기 전에 현재까지 모은 실시간 로컬 골드를 DB에 선제 정산하여 증발 리셋 방지
    await _persistGoldToServer();

    final success = await _supabase.captureTile(tile);
    if (success) {
      _lastSatelliteCaptureTime = DateTime.now();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('hq_last_satellite_capture_time', _lastSatelliteCaptureTime!.toIso8601String());
      } catch (e) {
        debugPrint('SharedPreferences 쿨타임 저장 실패: $e');
      }

      // 위성 점령에 소모된 거리 비례 골드 차감 및 last_gold_updated_at 동기화
      try {
        final profile = _authProvider?.profile;
        if (profile != null) {
          final mainBaseId = profile.mainBaseTileId;
          if (mainBaseId != null && mainBaseId.isNotEmpty) {
            final partsBase = mainBaseId.split('_');
            final bq = int.tryParse(partsBase[1]) ?? 0;
            final br = int.tryParse(partsBase[2]) ?? 0;
            final dist = HexService.hexDistance(bq, br, q, r);
            // [중요] 백엔드의 구형 profile.gold가 아닌 온전히 실시간 축적분이 담긴 최신 _currentGold 기준으로 거리 차감 진행
            final newGold = (_currentGold - dist).clamp(0.0, double.infinity);
            
            await _supabase.client.from('profiles').update({
              'gold': newGold,
              'last_gold_updated_at': DateTime.now().toUtc().toIso8601String()
            }).eq('id', myId);
          }
        }
      } catch (e) {
        debugPrint('⚠️ 위성 점령 재화 차감 중 오류 발생: $e');
      }

      _capturedTiles[tileId] = tile;
      addAlert(GameStrings.satelliteCaptureSuccess, AlertType.success);
      
      // 위성 점령이 최종 성공했으므로 조준 상태를 깔끔하게 비움
      _selectedScanTileId = null;
      _selectedScanTileLatLng = null;
      
      await syncGoldWithServer();
    } else {
      final errMsg = _supabase.lastError != null ? ': ${_supabase.lastError}' : '';
      addAlert('${GameStrings.satelliteCaptureFail}$errMsg', AlertType.error);
    }

    _isSavingSatellite = false;
    _satelliteCapturingTileId = null;
    _satelliteCapturePhase = SatelliteCapturePhase.none;
    _satelliteTravelProgress = 0.0;
    _satelliteCaptureProgress = 0.0;
    _satelliteTravelDuration = null;
    _satelliteCaptureDuration = null;
    _satellitePhaseStartTime = null;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_authProvider?.isAuthenticated == true) {
        syncGoldWithServer();
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // [신규] 사용자가 홈 화면으로 나가거나 앱을 끌 때 즉시 모인 실시간 재화를 DB에 저장하여 증발 유실 완벽 차단
      if (_authProvider?.isAuthenticated == true) {
        _persistGoldToServer();
      }
    }
  }

  /// 현재 실시간으로 연산된 _currentGold 수치와 실시간 타임스탬프를 서버 백엔드 DB에 영속화(Persist)합니다.
  Future<void> _persistGoldToServer() async {
    final auth = _authProvider;
    if (auth == null || !auth.isAuthenticated || auth.profile == null) return;

    try {
      final profile = auth.profile!;
      final now = DateTime.now().toUtc();
      
      await _supabase.client.from('profiles').update({
        'gold': _currentGold,
        'last_gold_updated_at': now.toIso8601String(),
      }).eq('id', profile.id);

      await auth.refreshProfile();
    } catch (e) {
      debugPrint('❌ 골드 정밀 서버 영속화 실패: $e');
    }
  }

  /// 1초 주기로 요원의 점령 영토 개수와 골드 획득 배율에 따라 골드를 획득하여 상태를 누적합니다.
  /// 1시간에 타일당 1 GP가 쌓이도록 3600초 단위로 정밀하게 분할하여 실시간 증가를 유도합니다.
  void _startGoldTimer() {
    _goldTimer?.cancel();
    _syncCounter = 0;
    _goldTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final auth = _authProvider;
      if (auth == null || !auth.isAuthenticated || auth.profile == null) {
        timer.cancel();
        return;
      }
      final profile = auth.profile!;
      final now = DateTime.now().toUtc();
      final lastUpdated = profile.lastGoldUpdatedAt ?? now;
      final diffSeconds = now.difference(lastUpdated).inSeconds;
      final elapsed = diffSeconds > 0 ? diffSeconds : 0;

      // 시간당 1 GP를 3600초로 나누어 매초 정밀하게 소수점 단위 가산
      final double earnedGold = elapsed * profile.capturedTilesCount * (_goldRate / 3600.0);
      _currentGold = profile.gold + earnedGold;
      notifyListeners();

      // 성능 보존을 위해 매 10초마다 자동으로 서버 백엔드에 정밀 영속화 수행
      _syncCounter++;
      if (_syncCounter >= 10) {
        _syncCounter = 0;
        await _persistGoldToServer();
      }
    });
  }

  /// 보유한 영토 개수와 최종 갱신 오프라인 경과 시간을 대조 연동하여 서버와 골드 재화 보유 수량을 최종 동기화합니다.
  Future<void> syncGoldWithServer() async {
    final auth = _authProvider;
    if (auth == null || !auth.isAuthenticated || auth.profile == null) return;

    try {
      final rate = await _supabase.fetchGoldRate();
      _goldRate = rate ?? GameConfig.defaultGoldRate;

      await auth.refreshProfile();
      final profile = auth.profile;
      if (profile != null) {
        final now = DateTime.now().toUtc();
        final lastUpdated = profile.lastGoldUpdatedAt ?? now;
        final diffSeconds = now.difference(lastUpdated).inSeconds;
        final elapsed = diffSeconds > 0 ? diffSeconds : 0;
        
        // 오프라인 동안 쌓인 골드를 정밀하게 소수점 단위로 가산
        final double offlineGold = elapsed * profile.capturedTilesCount * (_goldRate / 3600.0);

        if (offlineGold > 0.0) {
          final newGold = profile.gold + offlineGold;
          // 오프라인 획득 골드를 즉시 서버 DB에 정밀 영속화
          await _supabase.client.from('profiles').update({
            'gold': newGold,
            'last_gold_updated_at': now.toIso8601String(),
          }).eq('id', profile.id);
          
          // 로컬 프로필도 다시 갱신하여 정합성 유지
          await auth.refreshProfile();
        }

        final updatedProfile = auth.profile ?? profile;
        _currentGold = updatedProfile.gold.toDouble();

        if (_goldTimer == null || !_goldTimer!.isActive) {
          _startGoldTimer();
        }
      }
    } catch (e) {
      debugPrint('❌ 골드 동기화 실패: $e');
    }
    notifyListeners();
  }
}
