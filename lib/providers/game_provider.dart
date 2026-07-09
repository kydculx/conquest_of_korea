import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/capture_controller.dart';
import '../controllers/notification_controller.dart';
import '../services/preferences_service.dart';
import '../services/geo_service.dart';
import '../services/photo_service.dart';
import '../controllers/satellite_capture_controller.dart';
import '../models/alert_model.dart';
import '../models/tile_model.dart';
import '../models/user_profile.dart';
import '../models/user_coin.dart';
import '../models/footprint_model.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/game_tile_provider.dart';
import '../services/hex_service.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';
import '../controllers/gold_manager.dart';
import '../core/constants/game_config.dart';
import '../core/constants/map_config.dart';
import '../core/constants/strings.dart';
import '../services/health_service.dart';

enum MapMode {
  normal,
  footprint,
  pattern,
}

/// 게임의 핵심 인게임 비즈니스 상태 및 점령 로직을 관리하고 UI에 변경을 전파하는 메인 프로바이더.
///
/// 타일 데이터 저장소는 [GameTileProvider]로 분리되었으며,
/// 본 클래스는 점령/위성/맵 상태/알림/재화 등 컨트롤러 간 오케스트레이션을 담당합니다.
class GameProvider extends ChangeNotifier with WidgetsBindingObserver {
  final SupabaseService _supabase;

  /// 타일 데이터 저장 및 실시간 동기화를 전담하는 프로바이더
  final GameTileProvider _tileProvider;

  /// 영토 점령 과정을 제어하는 컨트롤러
  late final CaptureController _captureController;

  /// 위성 원격 점령 프로세스를 전담 제어하는 컨트롤러
  late final SatelliteCaptureController _satelliteController;

  /// 알림 설정(FCM 구독 + 원격 동기화)을 전담 제어하는 컨트롤러
  late final NotificationController _notificationController;

  /// 재화(골드) 상태 관리자
  late final GoldManager _goldManager;

  // --- 백그라운드 타이머 ---
  /// 백그라운드 점령 및 침공 상태 정기 검사를 수행하는 타이머
  Timer? _backgroundPollingTimer;

  /// UTC 자정 카운트다운을 업데이트하는 1초 주기 타이머
  Timer? _utcTimer;

  /// UTC 00시까지 남은 시간 문자열 (HH:MM:SS)
  String _utcTimeString = '00:00:00';

  String get utcTimeString => _utcTimeString;

  // --- 상태 ---
  /// 화면 상단에 표시될 인게임 알림/경고 목록
  final List<GameAlert> _alerts = [];

  /// 오늘의 누적 걸음수 데이터
  int _todaySteps = 0;
  int get todaySteps => _todaySteps;

  /// 사용자가 설정한 로컬 GPS 정확도 레벨 ('high', 'best', 'bestForNavigation', 'medium')
  String _gpsAccuracyLevel = 'high';
  String get gpsAccuracyLevel => _gpsAccuracyLevel;

  /// 타일 ID별 등록된 사진 데이터 목록 캐시
  final Map<String, List<Map<String, dynamic>>> _tilePhotosCache = {};
  Map<String, List<Map<String, dynamic>>> get tilePhotosCache => _tilePhotosCache;

  /// 자동 점령 모드 활성화 여부
  bool _isAutoCapture = false;

  /// 현재 적용 중인 지도 스타일 인덱스
  int _currentMapStyleIndex = 0;

  /// 지도 회전 모드(나침반 정렬) 사용 여부
  bool _isMapRotationMode = false;

  /// 지도 카메라가 플레이어의 GPS 실시간 위치를 추적하고 있는지 여부
  bool _isFollowingUser = true;

  /// 맵 뷰 모드 통합 관리 상태
  MapMode _mapMode = MapMode.normal;
  MapMode get mapMode => _mapMode;

  bool get isFootprintMode => _mapMode == MapMode.footprint;
  bool get showCompletedPatterns => _mapMode == MapMode.pattern;

  /// 지도 카메라 이동 요청을 중계하기 위한 브로드캐스트 스트림 컨트롤러
  final StreamController<LatLng> _mapMoveRequestController = StreamController<LatLng>.broadcast();
  Stream<LatLng> get mapMoveRequests => _mapMoveRequestController.stream;

  void requestMapMove(LatLng destination) {
    // 🧭 수동 맵 카메라 이동(본진 이동, 패턴 조회 등) 시 나침반 회전 모드를 꺼서 불필요한 강제 회전 방지
    if (_isMapRotationMode) {
      _isMapRotationMode = false;
      PreferencesService.setMapRotationMode(false).catchError((e) {
        debugPrint('❌ MapRotationMode 저장 실패: $e');
      });
      notifyListeners();
    }
    _mapMoveRequestController.add(destination);
  }

  // --- 위성 스캔 상태 ---
  bool _isScanMode = false;
  String? _selectedScanTileId;
  LatLng? _selectedScanTileLatLng;

  // --- 발자취 선택 상태 ---
  String? _selectedFootprintTileId;
  LatLng? _selectedFootprintTileLatLng;
  String? get selectedFootprintTileId => _selectedFootprintTileId;
  LatLng? get selectedFootprintTileLatLng => _selectedFootprintTileLatLng;

  // --- 편법 방지용 최근 방문한 2개 타일 ID 캐시 ---
  String? _lastTileId;
  String? _secondLastTileId;

  // --- 동전 아이템 상태 ---
  List<UserCoin> _coins = [];
  List<UserCoin> get coins => List.unmodifiable(_coins);

  /// 동전 재생성이 비동기적으로 중복 실행되는 것을 방지하는 뮤텍스 락 플래그
  bool _isRegeneratingCoins = false;

  // --- 관련 Provider 참조 ---
  LocationProvider? _locationProvider;
  AuthProvider? _authProvider;
  AchievementProvider? _achievementProvider;

  /// 현재 로그인된 플레이어의 ID
  String? get _userId => _authProvider?.user?.id;

  /// 플레이어 인증 완료 여부
  bool get _isAuthenticated => _authProvider?.isAuthenticated ?? false;

  /// 플레이어의 프로필 객체
  UserProfile? get _profile => _authProvider?.profile;

  /// 플레이어 메인 기지 타일 ID
  String? get _userMainBaseTileId => _profile?.mainBaseTileId;

  // --- Public Getters (Tile — GameTileProvider 위임) ---
  Map<String, HexTile> get capturedTiles => _tileProvider.capturedTiles;

  Map<String, FootprintTile> get footprints => _tileProvider.footprints;

  int get myCapturedCount => _tileProvider.myCapturedCount;

  int getRemainingShieldSeconds(String tileId) =>
      _tileProvider.getRemainingShieldSeconds(tileId);

  bool isTileInfoRevealed(String tileId) =>
      _tileProvider.isTileInfoRevealed(tileId);

  DateTime? getTileRevealExpiration(String tileId) =>
      _tileProvider.getTileRevealExpiration(tileId);

  Future<String> getAgentNickname(String userId) =>
      _tileProvider.getAgentNickname(userId);

  // --- Public Getters (Gold) ---
  double get currentGold => _goldManager.currentGold;
  double get goldRate => _goldManager.goldRate;

  /// 서버에서 골드를 강제 동기화하여 가져옵니다.
  Future<void> syncGoldWithServer() async {
    await _goldManager.syncWithServer();
  }

  // --- Public Getters (Satellite) ---
  bool get isScanMode =>
      _selectedScanTileId != null || _satelliteController.isCapturing;
  String? get selectedScanTileId => _selectedScanTileId;
  LatLng? get selectedScanTileLatLng => _selectedScanTileLatLng;

  SatelliteCapturePhase get satelliteCapturePhase =>
      _satelliteController.phase;
  String? get satelliteCapturingTileId => _satelliteController.capturingTileId;
  double get satelliteTravelProgress => _satelliteController.travelProgress;
  double get satelliteCaptureProgress => _satelliteController.captureProgress;
  bool get isSatelliteCapturing => _satelliteController.isCapturing;
  DateTime? get lastSatelliteCaptureTime =>
      _satelliteController.lastCaptureTime;
  int get remainingSatelliteCaptureSeconds =>
      _satelliteController.remainingSeconds;
  int get remainingSatelliteCaptureCoolSeconds =>
      _satelliteController.remainingCoolSeconds;

  // --- Public Getters (Alert) ---
  List<GameAlert> get alerts => List.unmodifiable(_alerts);

  // --- Public Getters (Init / State) ---
  bool get isInitialized => _tileProvider.isInitialized;
  Future<void> get initializationFuture => _tileProvider.initializationFuture;

  bool get isAutoCapture => _isAutoCapture;
  int get currentMapStyleIndex => _currentMapStyleIndex;

  // --- Public Getters (Notification — NotificationController 위임) ---
  bool get isNotificationEnabled =>
      _notificationController.isNotificationEnabled;
  bool get isNotifTerritoryAttack =>
      _notificationController.isNotifTerritoryAttack;
  bool get isNotifSatelliteComplete =>
      _notificationController.isNotifSatelliteComplete;
  bool get isNotifSystemNotice => _notificationController.isNotifSystemNotice;

  // --- Public Getters (Map) ---
  bool get isMapRotationMode => _isMapRotationMode;
  bool get isFollowingUser => _isFollowingUser;
  bool get showMap => currentMapStyle.url.isNotEmpty;

  MapStyle get currentMapStyle => MapConfig.mapStyles[_currentMapStyleIndex];

  // --- Capture Getters ---
  String? get capturingTileId => _captureController.capturingTileId;
  String? get capturingColorHex => _captureController.capturingColorHex;
  double get captureProgress => _captureController.captureProgress;
  bool get isCapturing => _captureController.isCapturing;

  /// 현재 플레이어의 상태와 GPS 수신 상태를 기반으로 점령 개시가 가능한 상태인지 판단합니다.
  bool get canCapture {
    final loc = _locationProvider;
    final auth = _authProvider;

    if (loc == null || loc.currentLocation == null) {
      return false;
    }
    if (loc.currentAccuracy > GameConfig.captureAccuracyThreshold) {
      return false;
    }
    if (auth == null || !auth.isAuthenticated) {
      return false;
    }

    final myMainBaseId = auth.profile?.mainBaseTileId;
    final hex = HexService.latLngToHex(loc.currentLocation!);
    final currentTileId = HexService.tileId(hex['q']!, hex['r']!);
    if (myMainBaseId != null &&
        myMainBaseId.isNotEmpty &&
        currentTileId == myMainBaseId) {
      return false;
    }
    if (_tileProvider.isAlreadyCapturedByMe(loc)) {
      return false;
    }
    return true;
  }

  /// 현재 GPS 위치에 대응하는 점령 타일 정보를 반환합니다.
  HexTile? get currentTile => _tileProvider.currentTile(_locationProvider!);

  /// 사진(갤러리)이 등록된 전체 타일 ID 목록 게터 (시각 표시용)
  Set<String> get photoTileIds => _tileProvider.photoTileIds;

  /// 현재 위치한 타일이 이미 자신이 지배 중인 타일인지 여부
  bool get isAlreadyCapturedByMe {
    final loc = _locationProvider;
    if (loc == null) return false;
    return _tileProvider.isAlreadyCapturedByMe(loc);
  }

  // --- 생성자 ---
  GameProvider({
    required SupabaseService supabase,
    required GameTileProvider tileProvider,
  })  : _supabase = supabase,
        _tileProvider = tileProvider {
    _tileProvider.addListener(notifyListeners);
    WidgetsBinding.instance.addObserver(this);
    _startUtcTimer();
    initGpsSettings();
    _goldManager = GoldManager(
      supabase: supabase,
      getAuthProvider: () => _authProvider,
      notifyListeners: notifyListeners,
    );
    _captureController = CaptureController(
      supabase: supabase,
      onAlert: addAlert,
      onTileCaptured: (id, tile, {required bool wasEnemyTile}) {
        final oldOwnerId = _tileProvider.tileById(id)?.userId;
        _tileProvider.updateTile(id, tile);

        if (_notificationController.isNotificationEnabled) {
          NotificationService().showLocalNotification(
            id: id.hashCode,
            title: GameStrings.notificationCaptureEmptyTitle,
            body: GameStrings.notificationCaptureEmptyBody,
          );
        }
        AudioService().playNotification();

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
        _achievementProvider?.checkAndUnlock(
          capturedTiles: capturedTiles,
          newlyCapturedTileId: id,
        );
        notifyListeners();
      },
      onStateChanged: notifyListeners,
    );
    _satelliteController = SatelliteCaptureController(
      supabase: supabase,
      onAlert: addAlert,
      onCaptureSuccess: (tileId, tile) {
        _tileProvider.updateTile(tileId, tile);
        _selectedScanTileId = null;
        _selectedScanTileLatLng = null;

        _checkCoinCollection(tileId);
        AudioService().playNotification();

        final String? currentUserId = _userId;
        if (currentUserId != null &&
            _authProvider != null &&
            _authProvider!.profile != null) {
          _supabase.incrementSatelliteCapture(currentUserId).then((success) {
            if (success) {
              final updatedProfile = _authProvider!.profile!.copyWith(
                satelliteCaptureCount:
                    _authProvider!.profile!.satelliteCaptureCount + 1,
              );
              _authProvider!.updateProfileCache(updatedProfile);
              _achievementProvider?.checkAndUnlock(
                capturedTiles: capturedTiles,
                newlyCapturedTileId: tileId,
              );
              notifyListeners();
            }
          }).catchError((e) {
            debugPrint('⚠️ 위성 점령 카운트 DB 증가 실패: $e');
            _achievementProvider?.checkAndUnlock(
              capturedTiles: capturedTiles,
              newlyCapturedTileId: tileId,
            );
            notifyListeners();
          });
        } else {
          _achievementProvider?.checkAndUnlock(
            capturedTiles: capturedTiles,
            newlyCapturedTileId: tileId,
          );
          notifyListeners();
        }
      },
      onStateChanged: notifyListeners,
      getCapturedTiles: () => _tileProvider.capturedTiles,
      getUserId: () => _userId,
      getColorHex: () => _authProvider?.profile?.colorHex,
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
      if (type == 'territory_attack' || type == 'satellite_complete') {
        debugPrint(
            '🔔 [포그라운드 FCM 중복 차단] $type 타입의 알림은 로컬 화면에 이미 표시되었으므로 배너 생성을 무시합니다.');
        return;
      }
      final alertType = switch (type) {
        'system_notice' => AlertType.info,
        _ => AlertType.info,
      };
      _addAlertInternal('[$title] $body', alertType);
    };

    // 틸 프로바이더 침공 감지 시 알림/금/반격 처리
    _tileProvider.onInvasionDetected = _onInvasionDetectedFromTiles;

    _init();
  }

  /// GPS 설정값을 비동기로 초기 로드합니다.
  Future<void> initGpsSettings() async {
    _gpsAccuracyLevel = await PreferencesService.getGpsAccuracyLevel();
    notifyListeners();
  }

  /// 사용자가 GPS 정확도를 변경했을 때 호출됩니다.
  Future<void> updateGpsAccuracy(String newLevel) async {
    if (_gpsAccuracyLevel != newLevel) {
      _gpsAccuracyLevel = newLevel;
      await PreferencesService.setGpsAccuracyLevel(newLevel);
      notifyListeners();
      
      // 실시간 하드웨어 수신 정확도 재동기화
      await GeoService().updateTrackingAccuracy();
    }
  }

  /// 특정 타일 ID에 등록된 사진첩 데이터를 Supabase에서 로드하고 캐시를 갱신합니다.
  Future<List<Map<String, dynamic>>> loadPhotosForTile(String tileId) async {
    final photos = await PhotoService().fetchPhotosForTile(tileId);
    _tilePhotosCache[tileId] = photos;
    notifyListeners();
    return photos;
  }

  /// 현재 밟고 있는 타일에 사진첩 등록을 수행하고 연동 캐시를 리로드합니다.
  /// 성공 시 null을 반환하며, 실패 시 에러 사유 문자열을 반환합니다.
  Future<String?> uploadPhotoForTile(String tileId, File file) async {
    final auth = _authProvider;
    if (auth == null) {
      const msg = '인증 서비스(authProvider) 연동 실패';
      debugPrint('❌ [GameProvider] uploadPhotoForTile 실패: $msg');
      return msg;
    }
    if (!auth.isAuthenticated) {
      const msg = '인증되지 않은 유저 세션입니다. 로그인이 필요합니다.';
      debugPrint('❌ [GameProvider] uploadPhotoForTile 실패: $msg');
      return msg;
    }
    if (auth.profile == null) {
      const msg = '사용자 프로필 정보가 누락되었습니다.';
      debugPrint('❌ [GameProvider] uploadPhotoForTile 실패: $msg');
      return msg;
    }

    try {
      final profile = auth.profile!;
      final response = await PhotoService().uploadTilePhoto(
        tileId: tileId,
        file: file,
        userId: profile.id,
        userNickname: profile.nickname,
      );

      if (response != null) {
        await loadPhotosForTile(tileId);
        _tileProvider.loadPhotoTileIds().catchError((e) {
          debugPrint('⚠️ 사진 업로드 후 캐시 동기화 실패: $e');
        });
        return null; // 성공
      }
      return '서버 응답 오류 (알 수 없음)';
    } catch (e) {
      final msg = e.toString();
      debugPrint('❌ [GameProvider] 사진 업로드 트랜잭션 에러: $msg');
      return msg;
    }
  }

  /// 지정된 타일의 특정 사진첩 데이터를 삭제하고 연동 캐시를 리로드합니다.
  /// 성공 시 null을 반환하며, 실패 시 에러 사유 문자열을 반환합니다.
  Future<String?> deletePhotoForTile(String tileId, String photoId, String photoUrl) async {
    try {
      final success = await PhotoService().deleteTilePhoto(
        photoId: photoId,
        photoUrl: photoUrl,
      );

      if (success) {
        await loadPhotosForTile(tileId);
        _tileProvider.loadPhotoTileIds().catchError((e) {
          debugPrint('⚠️ 사진 삭제 후 캐시 동기화 실패: $e');
        });
        return null; // 성공
      }
      return '서버 삭제 응답 오류 (알 수 없음)';
    } catch (e) {
      final msg = e.toString();
      debugPrint('❌ [GameProvider] 사진 삭제 트랜잭션 에러: $msg');
      return msg;
    }
  }

  // --- Provider 설정 ---
  void setLocationProvider(LocationProvider loc) {
    if (_locationProvider != loc) {
      _locationProvider?.removeListener(onLocationUpdated);
      _locationProvider = loc;
      _locationProvider?.addListener(onLocationUpdated);
      notifyListeners();
    }
  }

  void setAchievementProvider(AchievementProvider ach) {
    if (_achievementProvider != ach) {
      _achievementProvider = ach;
      notifyListeners();
    }
  }

  void setAuthProvider(AuthProvider auth) {
    final oldProfile = _profile;
    _authProvider = auth;

    if (auth.isAuthenticated) {
      _isAutoCapture = true;

      if (auth.profile != null) {
        final double serverGold = auth.profile!.gold;
        final double localGold = _goldManager.currentGold;
        if ((localGold - serverGold).abs() > 0.5) {
          _goldManager.setGold(serverGold);
        }
      }

      _checkAndSyncCoins();

      if ((oldProfile == null && auth.profile != null) ||
          !_goldManager.isTimerActive) {
        _goldManager.syncWithServer();
      }
    } else {
      _goldManager.reset();
      _isAutoCapture = false;
      _isScanMode = false;
      _selectedScanTileId = null;
      _selectedScanTileLatLng = null;
      _satelliteController.cancelCapture();
      _captureController.cancelCapture();
    }
    notifyListeners();
  }

  // --- 초기화 ---
  Future<void> _init() async {
    try {
      _isMapRotationMode = await PreferencesService.isMapRotationMode();
      _lastTileId = await PreferencesService.getLastVisitedTileId();
      _secondLastTileId =
          await PreferencesService.getSecondLastVisitedTileId();

      await _notificationController.loadFromPrefs();

      final lastSatCapTimeStr =
          await PreferencesService.getLastSatelliteCaptureTime();
      _satelliteController.loadLastCaptureTime(lastSatCapTimeStr);

      // 타일 데이터 초기화 (GameTileProvider 위임)
      await _tileProvider.init();
      // 초기 걸음수 로드 (비동기로 실행하여 초기화 흐름을 방해하지 않도록 처리)
      updateStepsState().catchError((e) {
        debugPrint('초기 걸음수 로드 실패: $e');
      });
    } catch (e) {
      debugPrint('초기 데이터 로드 실패: $e');
    } finally {
      if (_isAuthenticated == true) {
        _goldManager.syncWithServer();
      }
      notifyListeners();
    }
    _startBackgroundPolling();
  }

  // --- 걸음수 관리 ---
  Timer? _stepsTimer;

  /// 오늘 걸음수 수동/자동 비동기 업데이트 메서드
  Future<void> updateStepsState() async {
    try {
      final steps = await HealthService.instance.getTodaySteps();
      if (_todaySteps != steps) {
        _todaySteps = steps;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ 걸음수 데이터 업데이트 중 에러: $e');
    }
  }

  // --- 백그라운드 폴링 ---
  void _startBackgroundPolling() {
    _backgroundPollingTimer?.cancel();
    _backgroundPollingTimer = Timer.periodic(
      GameConfig.backgroundCheckInterval,
      (_) => _refreshTilesAndCheckInvasion(),
    );

    // 30초마다 건강 앱 걸음수 동기화
    _stepsTimer?.cancel();
    _stepsTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => updateStepsState(),
    );
  }

  Future<void> _refreshTilesAndCheckInvasion() async {
    if (!isInitialized) return;
    try {
      debugPrint('🔍 백그라운드 정기 정밀 점검 중...');
      onLocationUpdated();
    } catch (e) {
      debugPrint('❌ 백그라운드 동기화 실패: $e');
    }
  }

  /// 침공 감지 시 알림/반격 처리
  void _onInvasionDetectedFromTiles() {
    NotificationService().showLocalNotification(
      id: 999,
      title: GameStrings.notificationInvasionTitle,
      body: GameStrings.notificationInvasionBody,
    );
    _addAlertInternal(
      '[${GameStrings.notificationInvasionTitle}] ${GameStrings.notificationInvasionBody}',
      AlertType.error,
    );

    // 위성 점령 진행 중 연결성 상실 체크
    if (_satelliteController.isCapturing) {
      final captTileId = _satelliteController.capturingTileId;
      if (captTileId != null) {
        final stillConnected =
            _satelliteController.checkConnectivity(captTileId);
        if (!stillConnected) {
          _satelliteController.cancelCapture();
          addAlert(GameStrings.satelliteDisconnectedAlert, AlertType.error);
          return;
        }
      }
    }

    if (_isAutoCapture) {
      onLocationUpdated();
    }
    notifyListeners();
  }

  // --- 위치 기반 점령 오케스트레이션 ---
  void onLocationUpdated() {
    if (!isInitialized) return;
    final loc = _locationProvider;
    final auth = _authProvider;
    if (loc == null || loc.currentLocation == null) {
      return;
    }
    if (!_tileProvider.hasInitializedLocation) {
      _tileProvider.initializeWithLocation(loc.currentLocation!);
    }
    if (auth == null || !auth.isAuthenticated || auth.profile == null) {
      return;
    }

    final hex = HexService.latLngToHex(loc.currentLocation!);
    final tileId = HexService.tileId(hex['q']!, hex['r']!);

    _checkAndSyncCoins();
    _checkCoinCollection(tileId);

    // 내 주변 2km 범위의 타일 실시간 갱신 트리거 작동
    _tileProvider.updateTilesInArea(hex['q']!, hex['r']!);

    // 편법 방지 타일 이동 카운팅 및 발자취 기록
    final myId = auth.profile!.id;

    // [보완] 현재 밟고 있는 타일의 발자취 기록을 매번 확인 시도 (내부 캐시 조건으로 중복 저장 원천 차단됨)
    _tileProvider.addFootprint(myId, tileId, DateTime.now());

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
            _achievementProvider?.checkAndUnlock(
                capturedTiles: capturedTiles);
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

    _captureController.checkCaptureStatus(loc.currentLocation);

    final now = DateTime.now();
    final lastCheck = _tileProvider.lastServerCheckTime;
    if (lastCheck == null ||
        now.difference(lastCheck) >= GameConfig.serverCheckDelay) {
      _tileProvider.updateLastServerCheckTime();

      _tileProvider
          .checkCurrentLocationTileStatusFromServer(loc, auth)
          .then((status) {
        _processCaptureDecision(tileId, status);
      }).catchError((e) {
        debugPrint('⚠️ 위치 기반 타일 상태 서버 조회 실패: $e');
      });
    }

    _achievementProvider?.checkAndUnlock(capturedTiles: capturedTiles);
  }

  Future<void> _processCaptureDecision(
      String tileId, TileStatus status) async {
    final loc = _locationProvider;
    final auth = _authProvider;
    if (loc == null ||
        auth == null ||
        auth.user == null ||
        auth.profile == null) {
      return;
    }

    final myMainBaseId = auth.profile!.mainBaseTileId;
    if (myMainBaseId != null &&
        myMainBaseId.isNotEmpty &&
        tileId == myMainBaseId) {
      if (_captureController.capturingTileId == tileId) {
        _captureController.cancelCapture();
      }
      return;
    }

    if (status == TileStatus.empty || status == TileStatus.enemy) {
      if (_isAutoCapture && !_captureController.isCapturing) {
        try {
          final serverTile = await _supabase.fetchTile(tileId);
          if (serverTile != null) {
            _tileProvider.updateTile(tileId, serverTile);
          } else {
            _tileProvider.removeTile(tileId);
          }
          notifyListeners();
        } catch (e) {
          debugPrint('자동 점령 전 서버 타일 정보 패치 실패: $e');
        }

        final int currentCaptureCount =
            _tileProvider.tileById(tileId)?.captureCount ?? 0;
        final int targetCaptureCount = currentCaptureCount + 1;
        final int durationSeconds =
            GameConfig.initialCaptureDurationSeconds * targetCaptureCount;
        final Duration captureDuration =
            Duration(seconds: durationSeconds);

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
      if (_captureController.capturingTileId == tileId) {
        _captureController.cancelCapture();
      }
    }
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
    final tileId = HexService.tileId(hex['q']!, hex['r']!);

    final myMainBaseId = auth?.profile?.mainBaseTileId;
    if (myMainBaseId != null &&
        myMainBaseId.isNotEmpty &&
        tileId == myMainBaseId) {
      return;
    }

    try {
      final serverTile = await _supabase.fetchTile(tileId);
      if (serverTile != null) {
        _tileProvider.updateTile(tileId, serverTile);
      } else {
        _tileProvider.removeTile(tileId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('점령 시작 전 서버 타일 정보 패치 실패 (로컬 데이터로 대체 진행): $e');
    }

    final int currentCaptureCount =
        _tileProvider.tileById(tileId)?.captureCount ?? 0;
    final int targetCaptureCount = currentCaptureCount + 1;
    final int durationSeconds =
        GameConfig.initialCaptureDurationSeconds * targetCaptureCount;
    final Duration captureDuration = Duration(seconds: durationSeconds);

    _satelliteController.cancelCapture();

    _captureController.startCapture(
      tileId: tileId,
      location: loc.currentLocation!,
      userId: auth!.user!.id,
      colorHex: auth.profile!.colorHex,
      duration: captureDuration,
      targetCaptureCount: targetCaptureCount,
      wasEnemyTile: currentTile != null,
    );
  }

  void toggleAutoCapture() {
    if (_isAuthenticated == true) {
      _isAutoCapture = true;
    } else {
      _isAutoCapture = !_isAutoCapture;
    }
    notifyListeners();
  }

  // --- Map State ---
  void setFollowingUser(bool value) {
    if (_isFollowingUser != value) {
      _isFollowingUser = value;
      notifyListeners();
    }
  }

  void toggleFollowingUser() {
    _isFollowingUser = !_isFollowingUser;
    notifyListeners();
  }

  void cycleMapMode() {
    final oldMode = _mapMode;
    switch (_mapMode) {
      case MapMode.normal:
        _mapMode = MapMode.footprint;
        break;
      case MapMode.footprint:
        _mapMode = MapMode.pattern;
        break;
      case MapMode.pattern:
        _mapMode = MapMode.normal;
        break;
    }
    _clearFootprintSelectionIfNeeded();
    notifyListeners();
    _showMapModeAlert(oldMode);
  }

  void toggleCompletedPatternsView() {
    final oldMode = _mapMode;
    _mapMode = (_mapMode == MapMode.pattern) ? MapMode.normal : MapMode.pattern;
    _clearFootprintSelectionIfNeeded();
    notifyListeners();
    _showMapModeAlert(oldMode);
  }

  void toggleFootprintMode() {
    final oldMode = _mapMode;
    _mapMode = (_mapMode == MapMode.footprint) ? MapMode.normal : MapMode.footprint;
    _clearFootprintSelectionIfNeeded();
    notifyListeners();
    _showMapModeAlert(oldMode);
  }

  void _clearFootprintSelectionIfNeeded() {
    if (_mapMode != MapMode.footprint) {
      _selectedFootprintTileId = null;
      _selectedFootprintTileLatLng = null;
    }
  }

  void _showMapModeAlert(MapMode oldMode) {
    if (oldMode != _mapMode) {
      String message;
      switch (_mapMode) {
        case MapMode.normal:
          message = GameStrings.mapModeNormalAlert;
          break;
        case MapMode.footprint:
          message = GameStrings.mapModeFootprintAlert;
          break;
        case MapMode.pattern:
          message = GameStrings.mapModePatternAlert;
          break;
      }
      addAlert(message, AlertType.info);
    }
  }

  void cycleMapStyle() {
    _currentMapStyleIndex =
        (_currentMapStyleIndex + 1) % MapConfig.mapStyles.length;
    notifyListeners();
  }

  Future<void> toggleMapRotationMode() async {
    _isMapRotationMode = !_isMapRotationMode;
    notifyListeners();
    PreferencesService.setMapRotationMode(_isMapRotationMode).catchError((e) {
      debugPrint('⚠️ 회전 모드 설정 저장 실패: $e');
    });
  }

  // --- Alert System ---
  void addAlert(String message, AlertType type) {
    _addAlertInternal(message, type);
  }

  bool _addAlertInternal(String message, AlertType type) {
    if (_alerts.any((a) => a.message == message)) return false;

    final alert = GameAlert.create(message: message, type: type);
    _alerts.insert(0, alert);
    if (_alerts.length > 5) _alerts.removeLast();
    notifyListeners();
    AudioService().playNotification();

    Timer(
      const Duration(seconds: GameConfig.alertDismissDurationSeconds),
      () => _removeAlert(alert.id),
    );
    return true;
  }

  void _removeAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  // --- Notification (NotificationController 위임) ---
  Future<void> toggleNotifications() =>
      _notificationController.toggleNotifications();

  Future<void> toggleNotifTerritoryAttack() =>
      _notificationController.toggleNotifTerritoryAttack();

  Future<void> toggleNotifSatelliteComplete() =>
      _notificationController.toggleNotifSatelliteComplete();

  Future<void> toggleNotifSystemNotice() =>
      _notificationController.toggleNotifSystemNotice();

  // --- Satellite Scan ---
  void toggleScanMode() {
    _isScanMode = !_isScanMode;
    _selectedScanTileId = null;
    notifyListeners();
  }

  void selectScanTile(String tileId) {
    if (!_isAuthenticated) return;

    if (_selectedScanTileId == tileId) {
      _selectedScanTileId = null;
      _selectedScanTileLatLng = null;
      notifyListeners();
    } else {
      _selectedScanTileId = tileId;
      final parts = tileId.split('_');
      if (parts.length == 3) {
        final q = int.tryParse(parts[1]);
        final r = int.tryParse(parts[2]);
        if (q != null && r != null) {
          _selectedScanTileLatLng = HexService.hexToLatLng(q, r);
        }
      }
      notifyListeners();

      // 조준 즉시 서버에서 타일 최신 정보 패치
      _tileProvider.fetchAndUpdateTile(tileId);
    }
  }

  void selectFootprintTile(String tileId) {
    if (_selectedFootprintTileId == tileId) {
      _selectedFootprintTileId = null;
      _selectedFootprintTileLatLng = null;
    } else {
      _selectedFootprintTileId = tileId;
      final parts = tileId.split('_');
      if (parts.length == 3) {
        final q = int.tryParse(parts[1]);
        final r = int.tryParse(parts[2]);
        if (q != null && r != null) {
          _selectedFootprintTileLatLng = HexService.hexToLatLng(q, r);
        }
      }
    }
    notifyListeners();
  }

  void clearSelectedFootprint() {
    _selectedFootprintTileId = null;
    _selectedFootprintTileLatLng = null;
    notifyListeners();
  }

  // --- Satellite Capture (SatelliteCaptureController 위임) ---
  int getTileDistance(String targetTileId) =>
      _satelliteController.getTileDistance(targetTileId);

  bool checkSatelliteCaptureConnectivity(String targetTileId) =>
      _satelliteController.checkConnectivity(targetTileId);

  int getSatelliteCaptureDurationSeconds(String tileId) =>
      _satelliteController.getCaptureDurationSeconds(tileId);

  double getSatelliteTravelRatio(String tileId) =>
      _satelliteController.getTravelRatio(tileId);

  void executeSatelliteCapture(String tileId) =>
      _satelliteController.executeCapture(tileId);

  void cancelSatelliteCapture() => _satelliteController.cancelCapture();

  bool isHQOr1Ring(String tileId) =>
      _satelliteController.isHQOr1Ring(tileId);

  // --- Tile Info Reveal (orchestration: gold + tile reveal) ---
  Future<bool> revealTileInfo(String tileId) async {
    if (_tileProvider.isTileInfoRevealed(tileId)) return true;

    final distance = getTileDistance(tileId);
    if (_goldManager.currentGold < distance - 0.0001) {
      addAlert(GameStrings.satGoldShortage, AlertType.error);
      return false;
    }

    final double previousGold = _goldManager.currentGold;
    final DateTime nowUtc = DateTime.now().toUtc();

    _goldManager.deductOptimistic(distance.toDouble());
    _tileProvider.addRevealedTile(tileId, nowUtc);
    notifyListeners();

    final myId = _userId;
    if (myId != null) {
      _supabase.client
          .from('profiles')
          .update({
            'gold': _goldManager.currentGold,
            'last_gold_updated_at': nowUtc.toIso8601String(),
          })
          .eq('id', myId)
          .then((_) {
            _supabase.incrementSatelliteScan(myId).then((success) {
              if (success &&
                  _authProvider != null &&
                  _authProvider!.profile != null) {
                final updatedProfile = _authProvider!.profile!.copyWith(
                  satelliteScanCount:
                      _authProvider!.profile!.satelliteScanCount + 1,
                );
                _authProvider!.updateProfileCache(updatedProfile);
                _achievementProvider?.checkAndUnlock(
                    capturedTiles: capturedTiles);
                notifyListeners();
              } else {
                _authProvider?.refreshProfile();
              }
            }).catchError((err) {
              debugPrint('⚠️ 위성 조회 카운트 DB 증가 실패: $err');
              _authProvider?.refreshProfile();
            });
          })
          .catchError((e) {
            debugPrint('⚠️ 상대 타일 정보 백엔드 저장 실패: $e');
            _goldManager.setGold(previousGold);
            _tileProvider.removeRevealedTile(tileId);
            notifyListeners();
            addAlert(GameStrings.satSecurityDecryptFailed, AlertType.error);
          });
    }

    addAlert(GameStrings.satSecurityDecryptSuccess, AlertType.success);
    return true;
  }

  // --- Main Base ---
  Future<bool> rebaseMainBase(String tileId, double cost) async {
    final myId = _userId;
    if (myId == null) return false;

    if (_goldManager.currentGold < cost - 0.0001) {
      addAlert(GameStrings.satGoldShortage, AlertType.error);
      return false;
    }

    final double previousGold = _goldManager.currentGold;
    final nowUtc = DateTime.now().toUtc();

    _goldManager.deductOptimistic(cost);
    notifyListeners();

    try {
      await _supabase.client.from('profiles').update({
        'main_base_tile_id': tileId,
        'gold': _goldManager.currentGold,
        'last_gold_updated_at': nowUtc.toIso8601String(),
      }).eq('id', myId);

      // 본진 이동 횟수(RPC) 증가
      await _supabase.incrementMainBaseMove(myId);

      await _authProvider?.refreshProfile();
      return true;
    } catch (e) {
      debugPrint('⚠️ 본진 이전 처리 중 오류 발생: $e');
      _goldManager.setGold(previousGold);
      notifyListeners();
      return false;
    }
  }

  // --- Lifecycle ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isAuthenticated == true) {
        _goldManager.syncWithServer();
        _tileProvider.refreshTilesFromServer(); // 복귀 시 전체 점령 타일 1회 동기화
      }
      // 앱이 다시 포그라운드로 올 때 걸음수 즉시 갱신
      updateStepsState();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isAuthenticated == true) {
        _goldManager.persistToServer();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _goldManager.dispose();
    _backgroundPollingTimer?.cancel();
    _utcTimer?.cancel();
    _stepsTimer?.cancel();
    _satelliteController.dispose();
    _locationProvider?.removeListener(onLocationUpdated);
    _captureController.dispose();
    _tileProvider.removeListener(notifyListeners);
    _tileProvider.dispose();
    _mapMoveRequestController.close();
    super.dispose();
  }

  // --- Coin System ---
  Future<void> _checkAndSyncCoins() async {
    final myId = _userId;
    if (myId == null) return;
    if (_isRegeneratingCoins) {
      debugPrint('🪙 [동전 가드] 이미 동전 재생성이 진행 중이므로 중복 동기화 패치를 취소합니다.');
      return;
    }

    try {
      final nowUtc = DateTime.now().toUtc();
      final todayStr =
          "${nowUtc.year}-${nowUtc.month.toString().padLeft(2, '0')}-${nowUtc.day.toString().padLeft(2, '0')}";

      final lastDate = await PreferencesService.getLastCoinGeneratedDate();

      if (_coins.isNotEmpty && lastDate == todayStr) {
        return;
      }

      final existingCoins = await _supabase.fetchUserCoins(myId);

      if (lastDate != todayStr || existingCoins.isEmpty) {
        debugPrint(
            '🪙 자정 경과 또는 동전 없음 감지 ➔ 동전 재생성 시작 (UTC: $todayStr)');
        await _regenerateCoins(myId, todayStr);
      } else {
        _coins = existingCoins;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ 동전 상태 체크 및 동기화 실패: $e');
    }
  }

  Future<void> debugRegenerateCoins() async {
    final myId = _userId;
    if (myId == null) {
      addAlert('로그인이 필요한 작업입니다.', AlertType.error);
      return;
    }
    if (_isRegeneratingCoins) {
      addAlert('이미 동전 재배치가 진행 중입니다. 잠시만 기다려주세요.', AlertType.error);
      return;
    }

    _coins = [];
    notifyListeners();

    final nowUtc = DateTime.now().toUtc();
    final todayStr =
        "${nowUtc.year}-${nowUtc.month.toString().padLeft(2, '0')}-${nowUtc.day.toString().padLeft(2, '0')}";

    addAlert('동전을 즉시 재배치하는 중...', AlertType.info);

    try {
      await _regenerateCoins(myId, todayStr);
      addAlert('동전이 현재 위치 기준으로 성공적으로 초기화되었습니다!', AlertType.info);
    } catch (e) {
      addAlert('동전 초기화 실패: $e', AlertType.error);
    }
  }

  Future<void> _regenerateCoins(String userId, String todayStr) async {
    if (_isRegeneratingCoins) return;
    _isRegeneratingCoins = true;

    final loc = _locationProvider;
    final currLoc = loc?.currentLocation;
    if (currLoc == null) {
      debugPrint('⚠️ 위치 정보가 없어 동전을 재생성할 수 없습니다. 다음 위치 업데이트 시도 대기.');
      _isRegeneratingCoins = false;
      return;
    }

    try {
      final centerHex = HexService.latLngToHex(currLoc);
      final int centerQ = centerHex['q']!;
      final int centerR = centerHex['r']!;
      const int radius = GameConfig.coinSpawnRadius;

      final List<Map<String, dynamic>> candidates = [];
      final List<Map<String, dynamic>> backupCandidates = [];
      final centerLatLng = HexService.hexToLatLng(centerQ, centerR);

      for (int q = -radius; q <= radius; q++) {
        final int rMin = math.max(-radius, -q - radius);
        final int rMax = math.min(radius, -q + radius);
        for (int r = rMin; r <= rMax; r++) {
          if (q == 0 && r == 0) continue;
          final targetQ = centerQ + q;
          final targetR = centerR + r;
          final targetLatLng = HexService.hexToLatLng(targetQ, targetR);

          final double dLat =
              targetLatLng.latitude - centerLatLng.latitude;
          final double dLng =
              targetLatLng.longitude - centerLatLng.longitude;
          final double angle = math.atan2(dLat, dLng);

          final int distance =
              ((q.abs() + r.abs() + (q + r).abs()) / 2).round();

          final item = {
            'q': targetQ,
            'r': targetR,
            'angle': angle,
          };

          if (distance >= GameConfig.coinSpawnMinDistance &&
              distance <= GameConfig.coinSpawnMaxDistance) {
            candidates.add(item);
          } else {
            backupCandidates.add(item);
          }
        }
      }

      if (candidates.isEmpty && backupCandidates.isEmpty) return;

      final List<Map<String, int>> selected = [];
      const int numSlices = 10;
      const double sliceWidth = (2 * math.pi) / numSlices;

      for (int i = 0; i < numSlices; i++) {
        final double sliceMin = -math.pi + (i * sliceWidth);
        final double sliceMax = sliceMin + sliceWidth;

        final sliceCandidates = candidates.where((c) {
          final double angle = c['angle'] as double;
          return angle >= sliceMin && angle < sliceMax;
        }).toList();

        if (sliceCandidates.isNotEmpty) {
          sliceCandidates.shuffle();
          final chosen = sliceCandidates.first;
          selected.add({
            'q': chosen['q'] as int,
            'r': chosen['r'] as int,
          });
        }
      }

      if (selected.length < 10) {
        candidates.shuffle();
        for (final c in candidates) {
          if (selected.length >= 10) break;
          final targetQ = c['q'] as int;
          final targetR = c['r'] as int;
          final isDuplicate =
              selected.any((s) => s['q'] == targetQ && s['r'] == targetR);
          if (!isDuplicate) {
            selected.add({'q': targetQ, 'r': targetR});
          }
        }
      }

      if (selected.length < 10) {
        backupCandidates.shuffle();
        for (final c in backupCandidates) {
          if (selected.length >= 10) break;
          final targetQ = c['q'] as int;
          final targetR = c['r'] as int;
          final isDuplicate =
              selected.any((s) => s['q'] == targetQ && s['r'] == targetR);
          if (!isDuplicate) {
            selected.add({'q': targetQ, 'r': targetR});
          }
        }
      }

      final List<UserCoin> newCoins = selected.map((c) {
        final q = c['q']!;
        final r = c['r']!;
        final tileId = HexService.tileId(q, r);
        return UserCoin(
          userId: userId,
          tileId: tileId,
          q: q,
          r: r,
          isCollected: false,
          createdAt: DateTime.now().toUtc(),
        );
      }).toList();

      await _supabase.clearUserCoins(userId);
      final insertSuccess = await _supabase.insertUserCoins(newCoins);

      if (insertSuccess) {
        _coins = newCoins;
        await PreferencesService.setLastCoinGeneratedDate(todayStr);
        debugPrint('🪙 동전 10개 재생성 및 원격 DB 등록 완료.');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ 동전 생성 중 오류 발생: $e');
    } finally {
      _isRegeneratingCoins = false;
    }
  }

  Future<void> _checkCoinCollection(String tileId) async {
    final myId = _userId;
    if (myId == null) return;

    final coinIndex =
        _coins.indexWhere((c) => c.tileId == tileId && !c.isCollected);
    if (coinIndex == -1) return;

    final targetCoin = _coins[coinIndex];
    debugPrint('🪙 동전 발견! 타일 ID: ${targetCoin.tileId}. 획득 시도 중...');

    final originalCoins = List<UserCoin>.from(_coins);
    final updatedCoins = List<UserCoin>.from(_coins);
    updatedCoins[coinIndex] = UserCoin(
      userId: targetCoin.userId,
      tileId: targetCoin.tileId,
      q: targetCoin.q,
      r: targetCoin.r,
      isCollected: true,
      createdAt: targetCoin.createdAt,
      collectedAt: DateTime.now(),
    );
    _coins = updatedCoins;
    notifyListeners();

    try {
      final success =
          await _supabase.collectCoin(myId, tileId, GameConfig.coinGoldReward);
      if (success) {
        AudioService().playNotification();
        addAlert(
          '동전을 발견하여 ${GameConfig.coinGoldReward.toInt()}골드를 획득했습니다!',
          AlertType.info,
        );
        await _goldManager.syncWithServer();
      } else {
        debugPrint('⚠️ 동전 획득 DB 처리 실패 ➔ 롤백 수행');
        _coins = originalCoins;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ 동전 획득 처리 중 예외 발생 ➔ 롤백 수행: $e');
      _coins = originalCoins;
      notifyListeners();
    }
  }

  // --- UTC Timer ---
  void _startUtcTimer() {
    _updateUtcTimeString();
    _utcTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateUtcTimeString();
    });
  }

  void _updateUtcTimeString() {
    final nowUtc = DateTime.now().toUtc();
    final targetUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day + 1);
    final diff = targetUtc.difference(nowUtc);

    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

    _utcTimeString = '$hours:$minutes:$seconds';
    notifyListeners();
  }
}
