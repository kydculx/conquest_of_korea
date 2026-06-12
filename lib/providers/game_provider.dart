import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/capture_controller.dart';
import '../controllers/notification_controller.dart';
import '../services/preferences_service.dart';
import '../controllers/satellite_capture_controller.dart';
import '../models/alert_model.dart';
import '../models/tile_model.dart';
import '../models/user_profile.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/achievement_provider.dart';
import '../services/hex_service.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';
import '../controllers/gold_manager.dart';
import '../core/constants/game_config.dart';
import '../core/constants/map_config.dart';
import '../core/constants/strings.dart';

/// 게임의 핵심 인게임 비즈니스 상태 및 점령 로직을 관리하고 UI에 변경을 전파하는 메인 프로바이더 클래스
class GameProvider extends ChangeNotifier with WidgetsBindingObserver {
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

  /// 화면 상단에 표시될 인게임 알림/경고 목록
  final List<GameAlert> _alerts = [];

  /// 프로바이더 내부 데이터 초기화 완료 여부
  bool _isInitialized = false;

  /// 자동 점령 모드 활성화 여부
  bool _isAutoCapture = false;

  /// 현재 적용 중인 지도 스타일 인덱스
  int _currentMapStyleIndex = 0;

  /// 지도 회전 모드(나침반 정렬) 사용 여부
  bool _isMapRotationMode = false;

  /// 지도 카메라가 플레이어의 GPS 실시간 위치를 추적(Following)하고 있는지 여부
  bool _isFollowingUser = true;

  // --- 위성 스캔 상태 ---
  /// 위성 궤도 정밀 스캔 모드 활성화 여부
  bool _isScanMode = false;

  /// 위성 스캔 조준 중인 대상 타일 ID
  String? _selectedScanTileId;

  /// 위성 스캔 조준 타일의 중심 지리 좌표 (맭 스크롤 시 실시간 화면 좌표 변환에 사용)
  LatLng? _selectedScanTileLatLng;

  // --- 위성 점령 컨트롤러 ---
  /// 위성 원격 점령 프로세스를 전담 제어하는 컨트롤러
  late final SatelliteCaptureController _satelliteController;

  /// 알림 설정(FCM 구독 + 원격 동기화)을 전담 제어하는 컨트롤러
  late final NotificationController _notificationController;

  // --- 위치 변경 감지 시 서버 부하 방지용 3초 딜레이 타이머 ---
  /// 서버 부하 방지를 위해 마지막으로 위치 상태를 조정한 일시
  DateTime? _lastServerCheckTime;

  // --- 편법 방지용 최근 방문한 2개 타일 ID 캐시 ---
  String? _lastTileId;
  String? _secondLastTileId;

  // --- 재화(골드) 상태 관리자 ---
  late final GoldManager _goldManager;

  // 관련 Provider 참조
  /// 사용자 위치 정보를 공유하는 LocationProvider 인스턴스
  LocationProvider? _locationProvider;

  /// 사용자 인증 상태 정보를 공유하는 AuthProvider 인스턴스
  AuthProvider? _authProvider;

  /// 업적 상태 감시 및 해금을 관리하는 AchievementProvider 인스턴스
  AchievementProvider? _achievementProvider;

  // --- 데이터 접근자 (Provider 참조 캡슐화) ---
  /// 현재 로그인된 플레이어의 ID
  String? get _userId => _authProvider?.user?.id;

  /// 플레이어 인증 완료 여부
  bool get _isAuthenticated => _authProvider?.isAuthenticated ?? false;

  /// 플레이어의 프로필 객체
  UserProfile? get _profile => _authProvider?.profile;

  /// 플레이어 메인 기지 타일 ID
  String? get _userMainBaseTileId => _profile?.mainBaseTileId;

  /// 플레이어 테마 색상 (Hex)
  String? get _userColorHex => _profile?.colorHex;

  /// 플레이어 닉네임
  String? get _userNickname => _profile?.nickname;

  // --- Getters (public API) ---
  /// 실시간 점령된 타일 정보를 담은 불변 Map을 반환합니다.
  /// 내 메인 기지는 가상으로 내 땅으로 강제 주입(빈 타일이 아닌 내 땅으로 확실히 렌더링)하여 반환합니다.
  Map<String, HexTile> get capturedTiles {
    final Map<String, HexTile> copy = Map<String, HexTile>.from(_capturedTiles);

    final myMainBaseId = _userMainBaseTileId;
    final myId = _userId;
    final myColor = _userColorHex;

    // 내 메인 기지는 내 맵 상에서 가상으로 내 땅으로 강제 주입 (빈 타일이 아닌 내 땅으로 확실히 렌더링)
    if (myMainBaseId != null &&
        myMainBaseId.isNotEmpty &&
        myId != null &&
        myColor != null) {
      try {
        final parts = myMainBaseId.split('_');
        if (parts.length == 3) {
          final q = int.tryParse(parts[1]) ?? 0;
          final r = int.tryParse(parts[2]) ?? 0;
           final existing = _capturedTiles[myMainBaseId];
          copy[myMainBaseId] = HexTile(
            id: myMainBaseId,
            q: q,
            r: r,
            userId: myId,
            colorHex: myColor,
            capturedAt: existing?.capturedAt ?? DateTime.now().toUtc(),
            captureCount: existing?.captureCount ?? 1,
          );
        }
      } catch (e) {
        debugPrint('⚠️ 내 메인기지 가상 타일 주입 오류: $e');
      }
    }

    return Map.unmodifiable(copy);
  }

  /// 현재 보유 중인 골드 재화 수량
  double get currentGold => _goldManager.currentGold;

  /// 초당 골드 획득율 배율
  double get goldRate => _goldManager.goldRate;

  /// 현재 정보 조준경(정보 카드) 활성화 여부 (조준된 타일이 있거나 원격 확보 작업이 진행 중일 때 참)
  bool get isScanMode => _selectedScanTileId != null || _satelliteController.isCapturing;

  /// 위성 조준 스캔 상에서 선택된 타일 ID
  String? get selectedScanTileId => _selectedScanTileId;

  /// 선택된 위성 조준 타일의 중심 지리 좌표 (맵 스크롤 시 실시간 화면 좌표 변환에 사용)
  LatLng? get selectedScanTileLatLng => _selectedScanTileLatLng;

  /// 현재 위성 점령의 상태 단계 반환 (SatelliteCaptureController에 위임)
  SatelliteCapturePhase get satelliteCapturePhase => _satelliteController.phase;

  /// 현재 위성 점령 진행 중인 타일 ID
  String? get satelliteCapturingTileId => _satelliteController.capturingTileId;

  /// 위성 빔 비행 진행률 (0.0 ~ 1.0)
  double get satelliteTravelProgress => _satelliteController.travelProgress;

  /// 위성 점령 진행률 (0.0 ~ 1.0)
  double get satelliteCaptureProgress => _satelliteController.captureProgress;

  /// 위성 점령 시도가 활성화 중인지 여부
  bool get isSatelliteCapturing => _satelliteController.isCapturing;

  /// 마지막으로 위성 점령에 성공한 일시
  DateTime? get lastSatelliteCaptureTime => _satelliteController.lastCaptureTime;

  /// 위성 점령이 완료될 때까지 남은 초 단위 시간
  int get remainingSatelliteCaptureSeconds => _satelliteController.remainingSeconds;

  /// 위성 조준 장비의 재충전 쿨타임 남은 시간 (초)
  int get remainingSatelliteCaptureCoolSeconds => _satelliteController.remainingCoolSeconds;

  /// 인게임 상황판 알림 목록
  List<GameAlert> get alerts => List.unmodifiable(_alerts);

  /// 로컬 및 서버 상태 초기화 완료 여부
  bool get isInitialized => _isInitialized;

  /// 자동 점령 모드 활성화 여부
  bool get isAutoCapture => _isAutoCapture;

  /// 현재 활성화된 타일 지도 스타일의 인덱스
  int get currentMapStyleIndex => _currentMapStyleIndex;

  /// 로컬 푸시 알림 허용 여부
  bool get isNotificationEnabled =>
      _notificationController.isNotificationEnabled;

  /// 영토 침공 알림 수신 여부
  bool get isNotifTerritoryAttack =>
      _notificationController.isNotifTerritoryAttack;

  /// 위성 점령 완료 알림 수신 여부
  bool get isNotifSatelliteComplete =>
      _notificationController.isNotifSatelliteComplete;

  /// 시스템 공지 알림 수신 여부
  bool get isNotifSystemNotice =>
      _notificationController.isNotifSystemNotice;

  /// 지도 회전 모드(나침반 방향에 연동) 활성화 여부
  bool get isMapRotationMode => _isMapRotationMode; // 추가: 맵 회전 여부 getter

  /// 지도 카메라가 플레이어의 GPS 실시간 위치를 추적(Following)하고 있는지 여부
  bool get isFollowingUser => _isFollowingUser;

  /// 지도 카메라 추적 상태 명시적 업데이트
  void setFollowingUser(bool value) {
    if (_isFollowingUser != value) {
      _isFollowingUser = value;
      notifyListeners();
    }
  }

  /// 지도 카메라 추적 상태 토글
  void toggleFollowingUser() {
    _isFollowingUser = !_isFollowingUser;
    notifyListeners();
  }

  /// 현재 지정된 지도 스타일 환경 설정
  MapStyle get currentMapStyle => MapConfig.mapStyles[_currentMapStyleIndex];

  /// 지도를 실제로 렌더링해야 하는지의 여부
  bool get showMap => currentMapStyle.url.isNotEmpty;

  /// 본인 플레이어(계정)가 획득한 영토(타일)의 총 개수
  int get myCapturedCount {
    if (_userId == null) return 0;
    final myId = _userId!;
    final baseCount = _capturedTiles.values
        .where((t) => t.userId == myId)
        .length;

    // 본진(mainBaseTileId)이 설정되어 있다면 무조건 영토 개수는 1개 이상이 되도록 보장
    final myMainBaseId = _userMainBaseTileId;
    if (myMainBaseId != null && myMainBaseId.isNotEmpty) {
      return baseCount < 1 ? 1 : baseCount;
    }
    return baseCount;
  }

  /// 현재 물리 GPS 점령을 시도 중인 타일 ID
  String? get capturingTileId => _captureController.capturingTileId;

  /// 현재 점령 진행 중인 타일 플레이어의 테마 컬러 코드
  String? get capturingColorHex => _captureController.capturingColorHex;

  /// 물리 GPS 점령의 진행 진척도 (0.0 ~ 1.0)
  double get captureProgress => _captureController.captureProgress;

  /// 물리 GPS 점령이 실행 중인지 여부
  bool get isCapturing => _captureController.isCapturing;

  /// 현재 플레이어의 상태와 GPS 수신 상태를 기반으로 점령 개시가 가능한 상태인지 판단합니다.
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

    // 내 본진 타일은 점령할 필요가 없는 상시 내 영토이므로 점령 개시 불가로 철저히 차단
    final myMainBaseId = auth.profile?.mainBaseTileId;
    final hex = HexService.latLngToHex(loc.currentLocation!);
    final currentTileId = HexService.tileId(hex['q']!, hex['r']!);
    if (myMainBaseId != null && myMainBaseId.isNotEmpty && currentTileId == myMainBaseId) {
      return false;
    }

    // 이미 본인이 점령한 타일이면 점령 불가
    if (isAlreadyCapturedByMe) {
      return false;
    }

    return true;
  }

  /// 현재 GPS 위치에 대응하는 점령 타일 정보(HexTile)를 반환 (아직 점령되지 않았거나 GPS 미수신 상태이면 null 반환)
  HexTile? get currentTile {
    final loc = _locationProvider;
    if (loc?.currentLocation == null) return null;

    final hex = HexService.latLngToHex(loc!.currentLocation!);
    final tileId = HexService.tileId(hex['q']!, hex['r']!);
    return capturedTiles[tileId];
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
    _goldManager = GoldManager(
      supabase: supabase,
      getAuthProvider: () => _authProvider,
      notifyListeners: notifyListeners,
    );
    _captureController = CaptureController(
      supabase: supabase,
      onAlert: addAlert,
      onTileCaptured: (id, tile, {required bool wasEnemyTile}) {
        final oldOwnerId = _capturedTiles[id]?.userId;
        _capturedTiles[id] = tile;
        if (_notificationController.isNotificationEnabled) {
          NotificationService().showLocalNotification(
            id: id.hashCode,
            title: GameStrings.notificationCaptureEmptyTitle,
            body: GameStrings.notificationCaptureEmptyBody,
          );
        }

        // 🎵 공통 알림 효과음 재생
        AudioService().playNotification();

        // 상대방 구역 침탈 시 침탈 푸시 알림 발송
        final myId = _userId;
        if (wasEnemyTile &&
            oldOwnerId != null &&
            oldOwnerId != 'none' &&
            oldOwnerId != myId) {
          try {
            debugPrint('📡 침탈 푸시 알림 발송 요청 시작 (target: $oldOwnerId)');
            _supabase.client.functions.invoke(
              'send-push',
              body: {
                'topic': 'user_$oldOwnerId',
                'title': GameStrings.notificationInvasionTitle,
                'body': GameStrings.notificationInvasionBody,
                'data_payload': {
                  'type': 'territory_attack',
                  'tile_id': id,
                },
              },
            ).then((response) {
              debugPrint('🎯 침탈 푸시 알림 발송 결과: ${response.status}');
            }).catchError((e) {
              debugPrint('⚠️ 침탈 푸시 알림 발송 중 에러 발생: $e');
            });
          } catch (e) {
            debugPrint('⚠️ 침탈 푸시 알림 발송 예외 발생: $e');
          }
        }

        _goldManager.syncWithServer();
        _achievementProvider?.checkAndUnlock(capturedTiles: _capturedTiles);
        notifyListeners();
      },
      onStateChanged: notifyListeners,
    );
    _satelliteController = SatelliteCaptureController(
      supabase: supabase,
      onAlert: addAlert,
      onCaptureSuccess: (tileId, tile) {
        _capturedTiles[tileId] = tile;
        _selectedScanTileId = null;
        _selectedScanTileLatLng = null;

        // 🎵 공통 알림 효과음 재생
        AudioService().playNotification();

        _achievementProvider?.checkAndUnlock(capturedTiles: _capturedTiles);
        notifyListeners();
      },
      onStateChanged: notifyListeners,
      getCapturedTiles: () => _capturedTiles,
      getUserId: () => _userId,
      getColorHex: () => _userColorHex,
      getMainBaseTileId: () => _userMainBaseTileId,
      getCurrentGold: () => _goldManager.currentGold,
      deductGold: (amount) => _goldManager.deductOptimistic(amount),
      getCurrentUserId: () => _userId ?? '',
      refreshProfile: () async => _authProvider?.refreshProfile(),
      isPhysicalCapturing: () => _captureController.isCapturing,
      cancelPhysicalCapture: () => _captureController.cancelCapture(),
    );
    _notificationController = NotificationController(
      onStateChanged: notifyListeners,
      getUserId: () => _userId,
      onSyncToRemote: ({
        required bool isMasterEnabled,
        required bool territoryAttack,
        required bool satelliteComplete,
        required bool systemNotice,
      }) async {
        if (_isAuthenticated) {
          try {
            await _authProvider!.updateGranularNotifications(
              isMasterEnabled: isMasterEnabled,
              territoryAttack: territoryAttack,
              satelliteComplete: satelliteComplete,
              systemNotice: systemNotice,
            );
          } catch (e) {
            debugPrint('⚠️ 원격 DB 프로필 알림 일괄 동기화 실패: $e');
          }
        }
      },
    );
    NotificationService().onForegroundMessageReceived = (title, body, type) {
      // ⚠️ 포그라운드 상태일 때 침탈 및 위성 성공은 이미 로컬(스트림/콜백)에서 배너를 띄우므로 FCM 포그라운드 노출 중복을 차단합니다.
      if (type == 'territory_attack' || type == 'satellite_complete') {
        debugPrint('🔔 [포그라운드 FCM 중복 차단] $type 타입의 알림은 로컬 화면에 이미 표시되었으므로 배너 생성을 무시합니다.');
        return;
      }

      final alertType = switch (type) {
        'system_notice' => AlertType.info,
        _ => AlertType.info,
      };
      _addAlertInternal('[$title] $body', alertType);
    };
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

  /// 업적 관리 프로바이더([AchievementProvider]) 인스턴스를 설정합니다.
  void setAchievementProvider(AchievementProvider ach) {
    if (_achievementProvider != ach) {
      _achievementProvider = ach;
      notifyListeners();
    }
  }

  /// 사용자 인증 관리 프로바이더([AuthProvider])를 설정하고 로그인 세션 여부에 따라 골드 생산 타이머를 가동/종료합니다.
  void setAuthProvider(AuthProvider auth) {
    final oldProfile = _profile;
    _authProvider = auth;

    if (auth.isAuthenticated) {
      // 🎯 [신규] 로그인 상태에서는 항상 자동 점령(Auto Capture) 활성화
      _isAutoCapture = true;

      // [추가] 외부(관리자 등) 조작에 의해 profiles 테이블의 골드 잔액이 로컬과 편차가 생겼을 때 강제 덮어쓰기 동기화
      if (auth.profile != null) {
        final double serverGold = auth.profile!.gold;
        final double localGold = _goldManager.currentGold;
        if ((localGold - serverGold).abs() > 0.5) {
          _goldManager.setGold(serverGold);
        }
      }

      // 1. 프로필이 null이었다가 최초 로드(비동기 완료)된 시점
      // 2. 혹은 골드 타이머가 실행 중이지 않은 상태일 때 동기화 트리거
      if ((oldProfile == null && auth.profile != null) ||
          !_goldManager.isTimerActive) {
        _goldManager.syncWithServer();
      }
    } else {
      _goldManager.reset();

      // 로그아웃 시 자동 점령 모드 강제 정지(비활성화)
      _isAutoCapture = false;

      // 로그아웃 시 위성 모드 및 위성 점령 상태 전격 해제
      _isScanMode = false;
      _selectedScanTileId = null;
      _selectedScanTileLatLng = null;
      _satelliteController.cancelCapture();

      // 로그아웃 시 진행 중이던 물리 점령 작전 강제 중단
      _captureController.cancelCapture();
    }
    notifyListeners();
  }

  /// 프로바이더의 비동기 초기 데이터 설정 및 로드가 완전히 완료되었는지 감시할 수 있는 Future 객체
  Future<void> get initializationFuture => _initCompleter.future;

  /// 초기 설정을 불러오고, 기점령 타일 정보 획득 및 Supabase 실시간 타일 스트림을 연결합니다.
  Future<void> _init() async {
    try {
      _isMapRotationMode = await PreferencesService.isMapRotationMode();
      _lastTileId = await PreferencesService.getLastVisitedTileId();
      _secondLastTileId = await PreferencesService.getSecondLastVisitedTileId();

      // 알림 설정 로드 및 FCM 구독 동기화
      await _notificationController.loadFromPrefs();

      final lastSatCapTimeStr =
          await PreferencesService.getLastSatelliteCaptureTime();
      _satelliteController.loadLastCaptureTime(lastSatCapTimeStr);

      final tiles = await _supabase.fetchAllCapturedTiles();
      for (final tile in tiles) {
        _capturedTiles[tile.id] = tile;
      }
    } catch (e) {
      debugPrint('초기 데이터 로드 실패: $e');
    } finally {
      _isInitialized = true;
      if (!_initCompleter.isCompleted) _initCompleter.complete();
      if (_isAuthenticated == true) {
        _goldManager.syncWithServer();
      }
      notifyListeners();
    }
    _tilesStreamSub = _supabase.capturedTilesStream.listen(
      _onTilesUpdated,
      onError: (e) => debugPrint('⚠️ 점령 타일 스트림 에러: $e'),
    );
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

    final myMainBaseId = auth!.profile?.mainBaseTileId;

    // 1. 서버에서 수신된 최신 활성 타일 ID 집합 구성
    final incomingIds = tiles.map((t) => t.id).toSet();

    // 2. 현재 로컬 캐시에는 존재하나 서버 스트림 목록에 없는 (즉, 삭제된) 타일 소거
    final localIds = _capturedTiles.keys.toSet();
    final removedIds = localIds.difference(incomingIds);
    for (final id in removedIds) {
      _capturedTiles.remove(id);
      changed = true;
    }

    // 3. 신규 및 업데이트 타일 반영
    for (final tile in tiles) {
      // 침공 감지: 기존에 내 땅이었는데 주인이 바뀐 경우
      // 단, 내 메인기지 타일(mainBaseTileId)인 경우는 언제나 내 영토이므로 침공 판정에서 제외합니다.
      if (tile.id != myMainBaseId) {
        final oldTile = _capturedTiles[tile.id];
        if (oldTile != null &&
            oldTile.userId == auth.user!.id &&
            tile.userId != auth.user!.id) {
          invasionDetected = true;
        }
      }

      // 실제 데이터가 변경되었을 때만 주입 및 변경 플래그 활성화 (성능 누수 및 무차별 리빌드 방지)
      final oldTile = _capturedTiles[tile.id];
      if (oldTile == null ||
          oldTile.userId != tile.userId ||
          oldTile.colorHex != tile.colorHex ||
          oldTile.captureCount != tile.captureCount) {
        _capturedTiles[tile.id] = tile;
        changed = true;
      }
    }

    if (invasionDetected) {
      // 침공 알림 발송
      NotificationService().showLocalNotification(
        id: 999,
        title: GameStrings.notificationInvasionTitle,
        body: GameStrings.notificationInvasionBody,
      );

      // 인게임 화면 내 노티 배너 띄우기
      _addAlertInternal(
        '[${GameStrings.notificationInvasionTitle}] ${GameStrings.notificationInvasionBody}',
        AlertType.error,
      );

      // 만약 내가 그 자리에 있다면 즉시 반격 시작
      if (_isAutoCapture) {
        onLocationUpdated();
      }
    }

    if (changed) {
      // 위성 점령 진행 중일 때, 기지 침공이나 영토 분실 등으로 연결성이 끊어졌는지 실시간 체크
      bool alreadyNotified = false;
      if (_satelliteController.isCapturing) {
        final captTileId = _satelliteController.capturingTileId;
        if (captTileId != null) {
          final stillConnected = _satelliteController.checkConnectivity(captTileId);
          if (!stillConnected) {
            _satelliteController.cancelCapture();
            addAlert(GameStrings.satelliteDisconnectedAlert, AlertType.error);
            alreadyNotified = true;
          }
        }
      }
      if (!alreadyNotified) {
        notifyListeners();
      }
    }
  }

  void onLocationUpdated() {
    if (!_isInitialized) return;
    final loc = _locationProvider;
    final auth = _authProvider;
    if (loc == null || !loc.isGpsActive || loc.currentLocation == null) return;
    if (auth == null || !auth.isAuthenticated || auth.profile == null) return;

    final hex = HexService.latLngToHex(loc.currentLocation!);
    final tileId = HexService.tileId(hex['q']!, hex['r']!);

    // --- [신규] 편법 방지 타일 이동 카운팅 및 랭킹 반영 로직 ---
    if (_lastTileId == null) {
      _lastTileId = tileId;
      PreferencesService.setLastVisitedTileId(tileId);
    } else if (_lastTileId != tileId) {
      if (tileId != _secondLastTileId) {
        final String oldLastTileId = _lastTileId!;
        _secondLastTileId = oldLastTileId;
        _lastTileId = tileId;

        PreferencesService.setLastVisitedTileId(tileId);
        PreferencesService.setSecondLastVisitedTileId(oldLastTileId);

        _supabase.incrementMovedTiles(auth.profile!.id).then((success) {
          if (success) {
            final updatedProfile = auth.profile!.copyWith(
              dailyMovedTilesCount: auth.profile!.dailyMovedTilesCount + 1,
              totalMovedTilesCount: auth.profile!.totalMovedTilesCount + 1,
            );
            auth.updateProfileCache(updatedProfile);
            _achievementProvider?.checkAndUnlock(capturedTiles: _capturedTiles);
            notifyListeners();
          }
        }).catchError((e) {
          debugPrint('⚠️ 타일 이동 횟수 DB 증가 실패: $e');
        });
      } else {
        final String oldLastTileId = _lastTileId!;
        _secondLastTileId = oldLastTileId;
        _lastTileId = tileId;

        PreferencesService.setLastVisitedTileId(tileId);
        PreferencesService.setSecondLastVisitedTileId(oldLastTileId);
      }
    }

    // 1. 상태 체크 (백그라운드 타이머 보정 + 실시간 구역 이탈 체크)
    _captureController.checkCaptureStatus(loc.currentLocation);

    // 2. 오직 순수하게 지정된 간격(딜레이)으로만 현재 위치 타일 상태를 서버에 확인하여 진행
    final now = DateTime.now();
    if (_lastServerCheckTime == null ||
        now.difference(_lastServerCheckTime!) >= GameConfig.serverCheckDelay) {
      _lastServerCheckTime = now;

      checkCurrentLocationTileStatusFromServer().then((status) {
        _processCaptureDecision(tileId, status);
      }).catchError((e) {
        debugPrint('⚠️ 위치 기반 타일 상태 서버 조회 실패: $e');
      });
    }

    // 업적 조건 체크 호출
    _achievementProvider?.checkAndUnlock(capturedTiles: _capturedTiles);
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

    // 내 본진 타일은 점령할 필요가 없는 상시 내 영토이므로 점령 개시 불가로 철저히 차단
    final myMainBaseId = auth.profile?.mainBaseTileId;
    if (myMainBaseId != null && myMainBaseId.isNotEmpty && tileId == myMainBaseId) {
      if (_captureController.capturingTileId == tileId) {
        _captureController.cancelCapture();
      }
      return;
    }

    // mine: 내 타일 → 점령 중단
    // empty/enemy: 점령 대상이므로 진행
    if (status == TileStatus.empty || status == TileStatus.enemy) {
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
        _satelliteController.cancelCapture();

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
    final tileId = HexService.tileId(hex['q']!, hex['r']!);

    // 내 본진 타일은 점령할 필요가 없는 상시 내 영토이므로 수동 점령 개시 즉시 무시 차단
    final myMainBaseId = auth?.profile?.mainBaseTileId;
    if (myMainBaseId != null && myMainBaseId.isNotEmpty && tileId == myMainBaseId) {
      return;
    }

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
    _satelliteController.cancelCapture();

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
  /// 인증된 상태에서는 항상 자동 점령이 강제로 유지되므로 토글 효과가 없습니다(항상 true).
  void toggleAutoCapture() {
    if (_isAuthenticated == true) {
      _isAutoCapture = true;
    } else {
      _isAutoCapture = !_isAutoCapture;
    }
    notifyListeners();
  }

  /// 지도 배경 스타일(다크, 사이버펑크, 위성 등)을 순환 변경합니다.
  void cycleMapStyle() {
    _currentMapStyleIndex =
        (_currentMapStyleIndex + 1) % MapConfig.mapStyles.length;
    notifyListeners();
  }

  /// 지도 회전 모드(나침반 헤딩 동기화)를 활성화/비활성화하고 내부 설정을 저장합니다.
  Future<void> toggleMapRotationMode() async {
    _isMapRotationMode = !_isMapRotationMode;
    notifyListeners();
    // PreferencesService IO는 백그라운드 비동기 처리 — UI 반응성 확보
    PreferencesService.setMapRotationMode(_isMapRotationMode).catchError((e) {
      debugPrint('⚠️ 회전 모드 설정 저장 실패: $e');
    });
  }

  /// 현재 위치의 헥사곤 타일 점령 상태를 서버 기준으로 실시간 확인하는 함수
  Future<TileStatus> checkCurrentLocationTileStatusFromServer() async {
    final loc = _locationProvider;
    final auth = _authProvider;

    if (loc?.currentLocation == null || auth?.user == null) {
      return TileStatus.empty;
    }

    final hex = HexService.latLngToHex(loc!.currentLocation!);
    final tileId = HexService.tileId(hex['q']!, hex['r']!);

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
    // 내 구역(mine)이어도 최신 타일 정보로 즉시 동기화 갱신
    else if (status == TileStatus.mine) {
      final serverTile = await _supabase.fetchTile(tileId);
      if (serverTile != null) {
        _capturedTiles[tileId] = serverTile;
        notifyListeners();
        debugPrint(
          '🎨 [내 구역 갱신] 타일($tileId)의 최신 상태를 실시간 동기화 완료.',
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

  /// 알림 수신 동의 여부를 전환하고 변경 설정을 로컬 저장소 및 원격 DB 프로필에 보관합니다.
  Future<void> toggleNotifications() =>
      _notificationController.toggleNotifications();

  /// 영토 침공 알림 여부를 토글합니다.
  Future<void> toggleNotifTerritoryAttack() =>
      _notificationController.toggleNotifTerritoryAttack();

  /// 위성 점령 완료 알림 여부를 토글합니다.
  Future<void> toggleNotifSatelliteComplete() =>
      _notificationController.toggleNotifSatelliteComplete();

  /// 시스템 공지 알림 여부를 토글합니다.
  Future<void> toggleNotifSystemNotice() =>
      _notificationController.toggleNotifSystemNotice();

  /// 화면 상단에 표시될 새 경고/알림 팝업 메시지를 발행하고 3초 경과 후 자동 페이드아웃 되도록 타이머를 연동합니다.
  void addAlert(String message, AlertType type) {
    _addAlertInternal(message, type);
  }

  /// 내부 알림 등록 메서드. 중복 추가되지 않았을 경우 true를 반환합니다.
  bool _addAlertInternal(String message, AlertType type) {
    // ⚠️ 중복 알림 방지: 동일한 메시지가 이미 알림 목록에 존재하면 추가하지 않음
    if (_alerts.any((a) => a.message == message)) return false;

    final alert = GameAlert.create(message: message, type: type);
    _alerts.insert(0, alert);
    if (_alerts.length > 5) _alerts.removeLast();
    notifyListeners();

    // 🎵 공통 알림 효과음 재생
    AudioService().playNotification();

    Timer(const Duration(seconds: GameConfig.alertDismissDurationSeconds),
        () => _removeAlert(alert.id));
    return true;
  }

  /// 알림 목록에서 특정 ID의 경고 알림을 제거하고 화면을 갱신합니다.
  void _removeAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  /// 유저 고유 ID를 닉네임으로 캐싱하는 메모리 버퍼
  final Map<String, String> _agentNicknames = {};

  /// 유저 고유 ID에 해당하는 닉네임을 반환합니다.
  /// 만약 로그인된 본인의 ID라면 캐시/DB 조회 없이 즉시 본인 프로필의 닉네임을 반환합니다.
  /// 캐시에 없으면 Supabase에서 즉시 조회 후 캐싱하여 반환합니다.
  Future<String> getAgentNickname(String userId) async {
    final myId = _userId;
    final myNick = _userNickname;

    if (myId == userId && myNick != null && myNick.isNotEmpty) {
      return myNick;
    }

    if (_agentNicknames.containsKey(userId)) {
      return _agentNicknames[userId]!;
    }

    try {
      final res = await _supabase.client
          .from('profiles')
          .select('nickname')
          .eq('id', userId)
          .maybeSingle();
      if (res != null && res['nickname'] != null) {
        final nick = res['nickname'] as String;
        _agentNicknames[userId] = nick;
        notifyListeners();
        return nick;
      }
    } catch (e) {
      debugPrint('⚠️ 닉네임 조회 실패: $e');
    }

    // 실패 시 마스킹된 ID 반환
    final masked = userId.length > 8 ? '${userId.substring(0, 6)}...' : userId;
    return masked;
  }

  /// 정보가 보안 해제(Reveal)된 타일 ID와 해제 일시 맵
  final Map<String, DateTime> _revealedTileTimes = {};

  /// 대상 타일과 유저의 본진 사이의 최단 경로 거리를 반환합니다. (SatelliteCaptureController에 위임)
  int getTileDistance(String targetTileId) =>
      _satelliteController.getTileDistance(targetTileId);

  /// 타일 정보가 열람(보안 해제) 가능한 상태인지 여부를 판별합니다.
  /// 본인 타일이거나 중립(점령자 없음) 타일인 경우 항상 상시 노출(true)됩니다.
  /// 상대 타일인 경우, 해제 일시로부터 10분(GameConfig.tileRevealDurationSeconds)이 지나지 않았는지 판별합니다.
  bool isTileInfoRevealed(String tileId) {
    final myMainBaseId = _userMainBaseTileId;
    if (myMainBaseId != null && myMainBaseId.isNotEmpty && tileId == myMainBaseId) {
      return true; // 내 본진 타일은 상시 보안 해제 상태로 모든 정보 노출
    }

    final myId = _userId;
    final tile = capturedTiles[tileId]; // 게터 호출로 안전하게 가상 주입본 사용
    final isOwnTile = tile != null && tile.userId == myId;
    final isNeutral = tile == null || tile.userId == null || tile.userId == 'none';

    if (isOwnTile || isNeutral) {
      return true;
    }

    final revealedAt = _revealedTileTimes[tileId];
    if (revealedAt == null) return false;

    // 만료 여부 검증 (10분)
    final expiration = revealedAt.add(const Duration(seconds: GameConfig.tileRevealDurationSeconds));
    final isValid = DateTime.now().toUtc().isBefore(expiration);

    if (!isValid) {
      _revealedTileTimes.remove(tileId);
      notifyListeners();
    }

    return isValid;
  }

  /// 보안 해제된 타일의 남은 만료 시각(DateTime)을 반환합니다.
  /// 해제되지 않았거나 이미 만료된 경우 null을 반환합니다.
  DateTime? getTileRevealExpiration(String tileId) {
    final revealedAt = _revealedTileTimes[tileId];
    if (revealedAt == null) return null;
    return revealedAt.add(const Duration(seconds: GameConfig.tileRevealDurationSeconds));
  }

  /// 상대 타일 상세 정보 열람을 위해 본진으로부터의 거리(GP)만큼 골드를 지불하고 정보를 해제합니다.
  Future<bool> revealTileInfo(String tileId) async {
    if (isTileInfoRevealed(tileId)) return true;

    final distance = getTileDistance(tileId);
    if (_goldManager.currentGold < distance) {
      addAlert(GameStrings.satGoldShortage, AlertType.error);
      return false;
    }

    // [낙관적 업데이트] 골드 즉각 차감 및 해제 시간 즉시 등록
    final double previousGold = _goldManager.currentGold;
    final DateTime nowUtc = DateTime.now().toUtc();

    _goldManager.deductOptimistic(distance.toDouble());
    _revealedTileTimes[tileId] = nowUtc;
    notifyListeners(); // 즉각적인 UI 갱신 유도

    final myId = _userId;
    if (myId != null) {
      // 백엔드 API 요청은 await 하지 않고 백그라운드 비동기 처리하여 화면 멈춤(랙) 현상 완벽 방지
      _supabase.client
          .from('profiles')
          .update({
            'gold': _goldManager.currentGold,
            'last_gold_updated_at': nowUtc.toIso8601String(),
          })
          .eq('id', myId)
          .then((_) {
            _authProvider?.refreshProfile();
          })
          .catchError((e) {
            debugPrint('⚠️ 상대 타일 정보 백엔드 저장 실패: $e');
            // 네트워크 오류 등으로 실패 시 로컬 데이터 롤백 처리
            _goldManager.setGold(previousGold);
            _revealedTileTimes.remove(tileId);
            notifyListeners();
            addAlert(GameStrings.satSecurityDecryptFailed, AlertType.error);
          });
    }

    addAlert(GameStrings.satSecurityDecryptSuccess, AlertType.success);
    return true;
  }

  /// 본진을 새로운 위치로 이전(재설정)하고 해당 거리에 따른 비용(재화)을 차감합니다.
  Future<bool> rebaseMainBase(String tileId, double cost) async {
    final myId = _userId;
    if (myId == null) return false;

    if (_goldManager.currentGold < cost) {
      addAlert(GameStrings.satGoldShortage, AlertType.error);
      return false;
    }

    final double previousGold = _goldManager.currentGold;
    final nowUtc = DateTime.now().toUtc();

    // 낙관적 업데이트
    _goldManager.deductOptimistic(cost);
    notifyListeners();

    try {
      await _supabase.client
          .from('profiles')
          .update({
            'main_base_tile_id': tileId,
            'gold': _goldManager.currentGold,
            'last_gold_updated_at': nowUtc.toIso8601String(),
          })
          .eq('id', myId);

      // 프로필 데이터 강제 동기화
      await _authProvider?.refreshProfile();
      return true;
    } catch (e) {
      debugPrint('⚠️ 본진 이전 처리 중 오류 발생: $e');
      // 롤백
      _goldManager.setGold(previousGold);
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _goldManager.dispose();
    _tilesStreamSub?.cancel();
    _backgroundPollingTimer?.cancel();
    _satelliteController.dispose();
    _locationProvider?.removeListener(onLocationUpdated);
    _captureController.dispose();
    super.dispose();
  }

  /// 지정한 타일이 본진 기지이거나 본진을 둘러싼 인접 1링(Ring) 범위에 포함되는지 확인합니다.
  bool isHQOr1Ring(String tileId) =>
      _satelliteController.isHQOr1Ring(tileId);

  /// 위성 궤도 스캔 모드의 On/Off 여부를 전환합니다.
  void toggleScanMode() {
    _isScanMode = !_isScanMode;
    _selectedScanTileId = null;
    notifyListeners();
  }

  /// 위성 스캔 화면 상에서 조준점으로 지정할 대상 헥사곤 타일을 선택 조준합니다.
  /// 이미 선택된 타일을 다시 선택하는 경우 조준을 해제합니다.
  void selectScanTile(String tileId) {
    if (!_isAuthenticated) {
      return;
    }
    if (_selectedScanTileId == tileId) {
      _selectedScanTileId = null;
      _selectedScanTileLatLng = null;
      notifyListeners();
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
      notifyListeners();

      // [신규] 조준 즉시 서버 DB에서 이 타일의 실시간 최신 정보 강제 패치하여 동기화
      _supabase.fetchTile(tileId).then((serverTile) {
        if (_selectedScanTileId == tileId) {
          if (serverTile != null) {
            _capturedTiles[tileId] = serverTile;
          } else {
            _capturedTiles.remove(tileId);
          }
          notifyListeners();
        }
      }).catchError((e) {
        debugPrint('⚠️ 조준 타일 최신 정보 실시간 패치 실패: $e');
      });
    }
  }

  /// 위성 점령 연결성을 검증합니다. (SatelliteCaptureController에 위임)
  bool checkSatelliteCaptureConnectivity(String targetTileId) =>
      _satelliteController.checkConnectivity(targetTileId);

  /// 내 영토와 대상 타일 간의 거리를 산출하여 위성 점령 완료에 소요될 지연 시간(초)을 계산합니다.
  int getSatelliteCaptureDurationSeconds(String tileId) =>
      _satelliteController.getCaptureDurationSeconds(tileId);

  /// 위성 점령의 총 시간 중 '이동(비행) 시간'이 차지하는 비율을 산출합니다.
  double getSatelliteTravelRatio(String tileId) =>
      _satelliteController.getTravelRatio(tileId);

  /// 위성 원격 점령을 실행합니다. (SatelliteCaptureController에 위임)
  void executeSatelliteCapture(String tileId) =>
      _satelliteController.executeCapture(tileId);

  /// 현재 시도 중인 위성 원격 점령을 취소합니다.
  void cancelSatelliteCapture() =>
      _satelliteController.cancelCapture();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isAuthenticated == true) {
        _goldManager.syncWithServer();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // [신규] 사용자가 홈 화면으로 나가거나 앱을 끌 때 즉시 모인 실시간 재화를 DB에 저장하여 증발 유실 완벽 차단
      if (_isAuthenticated == true) {
        _goldManager.persistToServer();
      }
    }
  }

}
