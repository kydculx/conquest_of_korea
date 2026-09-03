import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/capture_controller.dart';
import '../controllers/notification_controller.dart';
import '../services/preferences_service.dart';
import '../services/geo_service.dart';
import '../services/photo_service.dart';
import '../controllers/satellite_capture_controller.dart';
import '../models/alert_model.dart';
import '../models/map_mode.dart';
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
import '../controllers/coin_manager.dart';
import '../controllers/game_alert_manager.dart';
import '../controllers/map_view_controller.dart';
import '../controllers/tile_selection_controller.dart';
import '../controllers/utc_countdown_controller.dart';
import '../core/constants/game_config.dart';
import '../core/constants/map_config.dart';
import '../core/constants/strings.dart';
import '../services/health_service.dart';

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
  /// 마지막으로 무거운 위치 파이프라인을 실행한 타일 ID.
  /// 사용자가 같은 타일 안에 머무르는 동안에는 네트워크 호출이 발생하지 않도록 게이트 역할을 한다.
  String? _lastProcessedTileId;

  /// UTC 자정 카운트다운을 전담 관리하는 컨트롤러
  late final UtcCountdownController _utcCountdown;

  String get utcTimeString => _utcCountdown.timeString;

  // --- 상태 ---
  /// 인게임 알림 배너를 전담 관리하는 매니저
  late final GameAlertManager _alertManager;

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

  // --- 지도 뷰 상태 ---
  /// 지도 카메라/스타일/뷰 모드 상태를 전담 관리하는 컨트롤러
  late final MapViewController _mapView;

  Stream<LatLng> get mapMoveRequests => _mapView.mapMoveRequests;

  void requestMapMove(LatLng destination) =>
      _mapView.requestMapMove(destination);

  // --- 타일 선택 상태 (위성 스캔 / 발자국) ---
  /// 위성 스캔 대상 및 발자국 조회 타일 선택 상태를 전담 관리하는 컨트롤러
  late final TileSelectionController _tileSelection;

  // --- 편법 방지용 최근 방문한 2개 타일 ID 캐시 ---
  String? _lastTileId;
  String? _secondLastTileId;

  // --- 동전 아이템 ---
  /// 동전 생성/수집 상태를 전담 관리하는 컨트롤러
  late final CoinManager _coinManager;

  List<UserCoin> get coins => _coinManager.coins;

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
      _tileSelection.selectedScanTileId != null ||
      _satelliteController.isCapturing;
  String? get selectedScanTileId => _tileSelection.selectedScanTileId;
  LatLng? get selectedScanTileLatLng => _tileSelection.selectedScanTileLatLng;
  String? get selectedFootprintTileId =>
      _tileSelection.selectedFootprintTileId;
  LatLng? get selectedFootprintTileLatLng =>
      _tileSelection.selectedFootprintTileLatLng;

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
  List<GameAlert> get alerts => _alertManager.alerts;

  // --- Public Getters (Init / State) ---
  bool get isInitialized => _tileProvider.isInitialized;
  Future<void> get initializationFuture => _tileProvider.initializationFuture;

  bool get isAutoCapture => _isAutoCapture;
  int get currentMapStyleIndex => _mapView.currentMapStyleIndex;

  // --- Public Getters (Notification — NotificationController 위임) ---
  bool get isNotificationEnabled =>
      _notificationController.isNotificationEnabled;
  bool get isNotifTerritoryAttack =>
      _notificationController.isNotifTerritoryAttack;
  bool get isNotifSatelliteComplete =>
      _notificationController.isNotifSatelliteComplete;
  bool get isNotifSystemNotice => _notificationController.isNotifSystemNotice;

  // --- Public Getters (Map — MapViewController 위임) ---
  bool get isMapRotationMode => _mapView.isMapRotationMode;
  bool get isFollowingUser => _mapView.isFollowingUser;
  bool get showMap => currentMapStyle.url.isNotEmpty;

  MapStyle get currentMapStyle => _mapView.currentMapStyle;
  MapMode get mapMode => _mapView.mapMode;
  bool get isFootprintMode => _mapView.isFootprintMode;
  bool get showCompletedPatterns => _mapView.showCompletedPatterns;

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
    _alertManager = GameAlertManager(notifyListeners: notifyListeners);
    _tileSelection = TileSelectionController(
      notifyListeners: notifyListeners,
      isAuthenticated: () => _isAuthenticated,
      onScanTileSelected: _tileProvider.fetchAndUpdateTile,
    );
    _coinManager = CoinManager(
      supabase: supabase,
      getAuthProvider: () => _authProvider,
      getLocationProvider: () => _locationProvider,
      notifyListeners: notifyListeners,
      onAlert: addAlert,
      onCoinCollected: () => _goldManager.syncWithServer(),
    );
    _mapView = MapViewController(notifyListeners: notifyListeners);
    _tileProvider.addListener(notifyListeners);
    WidgetsBinding.instance.addObserver(this);
    _utcCountdown = UtcCountdownController(notifyListeners: notifyListeners);
    _utcCountdown.start();
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
        _tileSelection.clearScanSelectionQuietly();

        _coinManager.checkCoinCollection(tileId);
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
      _alertManager.add('[$title] $body', alertType);
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
  Future<String?> uploadPhotoForTile(String tileId, File file, {String? comment}) async {
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
        comment: comment,
      );

      if (response != null) {
        await loadPhotosForTile(tileId);
        _tileProvider.loadPhotoTileIds().catchError((e) {
          debugPrint('⚠️ 사진 업로드 후 캐시 동기화 실패: $e');
        });

        // [추가] 프로필 정보(photo_upload_count) 동기화 및 즉시 업적 체크 가동
        await auth.refreshProfile();
        _achievementProvider?.checkAndUnlock(
          capturedTiles: _tileProvider.capturedTiles,
        );

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

        // 로그인 사용자 변경 또는 프로필 최초 로드 시 알림 설정 동기화
        if (oldProfile?.id != auth.profile!.id ||
            oldProfile?.isNotificationsEnabled != auth.profile!.isNotificationsEnabled ||
            oldProfile?.notifTerritoryAttack != auth.profile!.notifTerritoryAttack ||
            oldProfile?.notifSatelliteComplete != auth.profile!.notifSatelliteComplete ||
            oldProfile?.notifSystemNotice != auth.profile!.notifSystemNotice) {
          _notificationController.syncFromProfile(auth.profile!);
        }
      }

      _coinManager.checkAndSyncCoins();

      if ((oldProfile == null && auth.profile != null) ||
          !_goldManager.isTimerActive) {
        _goldManager.syncWithServer();
      }
    } else {
      _goldManager.reset();
      _notificationController.resetToDefault();
      _isAutoCapture = false;
      _tileSelection.resetScanState();
      _satelliteController.cancelCapture();
      _captureController.cancelCapture();
    }
    notifyListeners();
  }

  // --- 초기화 ---
  Future<void> _init() async {
    try {
      await _mapView.loadFromPrefs();
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
    // [개편] 1초 주기 폴링 타이머 제거. 위치 변경에 따른 무거운 파이프라인은
    // [onLocationUpdated]의 타일 ID 변경 게이트가 담당한다. GPS 리스너가
    // 매 위치 업데이트마다 호출해주므로 별도 타이머가 필요 없다.
    // 걸음수 동기화만 30초 주기로 유지.
    _stepsTimer?.cancel();
    _stepsTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => updateStepsState(),
    );
  }

  /// 침공 감지 시 알림/반격 처리
  void _onInvasionDetectedFromTiles() {
    NotificationService().showLocalNotification(
      id: 999,
      title: GameStrings.notificationInvasionTitle,
      body: GameStrings.notificationInvasionBody,
    );
    _alertManager.add(
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

  /// GPS 위치 변경 시 전체 처리 파이프라인을 실행하는 진입점입니다.
  ///
  /// [개편] 무거운 네트워크 호출 파이프라인(동전 처리 → 주변 타일 갱신 → 이동/발자국
  /// 기록 → 서버 타일 상태 폴링 → 업적 검사)은 **현재 타일 ID가 직전 처리 타일과
  /// 달라진 경우에만** 실행된다. GPS 리스너가 초당 호출되지만 같은 타일 안에서는
  /// 네트워크가 발생하지 않는다. 점령 진행 체크는 게이트 외부에서 항상 실행된다(로컬
  /// 로직만, 네트워크 없음).
  ///
  /// 트레이드오프: 사용자가 정지해 있는 동안에는 다른 플레이어가 현재 타일을 침공해도
  /// 감지하지 못한다. 서버측 FCM 푸시 알림이 보완한다.
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

    // [신규] 타일 ID 변경 게이트: 같은 타일에 머무는 동안에는 무거운 파이프라인 스킵
    if (_lastProcessedTileId != tileId) {
      _processCoinsForCurrentTile(tileId);
      _refreshNearbyTiles(hex['q']!, hex['r']!);
      _recordMovementAndFootprint(auth, tileId);
      _pollCurrentTileStatusIfNeeded(loc, auth, tileId);
      _achievementProvider?.checkAndUnlock(capturedTiles: capturedTiles);
      _lastProcessedTileId = tileId;
    }

    // 점령 진행 중 체크는 항상 실행 (로컬 로직만, 네트워크 없음)
    _captureController.checkCaptureStatus(loc.currentLocation);
  }

  /// 현재 타일 기준으로 동전 동기화 및 획득 여부를 확인합니다.
  void _processCoinsForCurrentTile(String tileId) {
    _coinManager.checkAndSyncCoins();
    _coinManager.checkCoinCollection(tileId);
  }

  /// 내 주변 2km 범위의 타일 실시간 갱신 트리거 작동
  void _refreshNearbyTiles(int q, int r) {
    _tileProvider.updateTilesInArea(q, r);
  }

  /// 편법 방지용 최근 방문 타일 카운팅과 발자취 기록을 수행합니다.
  void _recordMovementAndFootprint(AuthProvider auth, String tileId) {
    // [보완] 현재 밟고 있는 타일의 발자취 기록을 매번 확인 시도 (내부 캐시 조건으로 중복 저장 원천 차단됨)
    _tileProvider.addFootprint(auth.profile!.id, tileId, DateTime.now());

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
  }

  /// 주기 throttling에 따라 현재 위치 타일의 서버 상태를 조회하고 점령 판정을 수행합니다.
  /// 본진(메인 베이스)에 있으면 캡처가 불가하므로 조회를 생략합니다.
  void _pollCurrentTileStatusIfNeeded(
      LocationProvider loc, AuthProvider auth, String tileId) {
    // 본진(메인 베이스)에 있으면 캡처가 불가하므로 매초 서버 상태 조회(1초 폴링)를 생략한다.
    // 조회 결과는 항상 'mine'으로 고정되어, 무의미한 네트워크 왕복만 발생하기 때문이다.
    final myMainBaseId = auth.profile!.mainBaseTileId;
    if (myMainBaseId != null &&
        myMainBaseId.isNotEmpty &&
        tileId == myMainBaseId) {
      return;
    }

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
            // ★ 서버에 타일이 없더라도 로컬 캐시에 내 타일이 있으면 보존
            // (네트워크 오류·DB 지연으로 서버 상태를 신뢰할 수 없는 케이스 방어)
            final localTile = _tileProvider.tileById(tileId);
            if (localTile?.userId != _userId) {
              _tileProvider.removeTile(tileId);
            }
          }
          notifyListeners();
        } catch (e) {
          debugPrint('자동 점령 전 서버 타일 정보 패치 실패: $e');
        }

        // ★ 서버 fetch 결과 로컬에 내 타일이 남아있으면 점령 재시작하지 않음
        final currentTile = _tileProvider.tileById(tileId);
        if (currentTile?.userId == _userId) {
          debugPrint('자동 점령 스킵 - 이미 내 타일: $tileId');
          return;
        }

        final int currentCaptureCount =
            currentTile?.captureCount ?? 0;
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

  // --- Map State (MapViewController 위임 + 모드 전환 오케스트레이션) ---
  void setFollowingUser(bool value) => _mapView.setFollowingUser(value);

  void toggleFollowingUser() => _mapView.toggleFollowingUser();

  void cycleMapMode() {
    final oldMode = _mapView.cycleModeQuiet();
    if (!_mapView.isFootprintMode) {
      _tileSelection.clearSelectedFootprintQuietly();
    }
    notifyListeners();
    _showMapModeAlert(oldMode);
  }

  void toggleCompletedPatternsView() {
    final oldMode = _mapView.toggleCompletedPatternsViewQuiet();
    if (!_mapView.isFootprintMode) {
      _tileSelection.clearSelectedFootprintQuietly();
    }
    notifyListeners();
    _showMapModeAlert(oldMode);
  }

  void toggleFootprintMode() {
    final oldMode = _mapView.toggleFootprintModeQuiet();
    if (!_mapView.isFootprintMode) {
      _tileSelection.clearSelectedFootprintQuietly();
    }
    notifyListeners();
    _showMapModeAlert(oldMode);
  }

  void _showMapModeAlert(MapMode oldMode) {
    final currentMode = _mapView.mapMode;
    if (oldMode != currentMode) {
      String message;
      switch (currentMode) {
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

  void cycleMapStyle() => _mapView.cycleMapStyle();

  Future<void> toggleMapRotationMode() =>
      _mapView.toggleMapRotationMode();

  // --- Alert System (GameAlertManager 위임) ---
  void addAlert(String message, AlertType type) {
    _alertManager.add(message, type);
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

  // --- Satellite Scan / Footprint Selection (TileSelectionController 위임) ---
  void toggleScanMode() => _tileSelection.toggleScanMode();

  void selectScanTile(String tileId) => _tileSelection.selectScanTile(tileId);

  void selectFootprintTile(String tileId) =>
      _tileSelection.selectFootprintTile(tileId);

  void clearSelectedFootprint() =>
      _tileSelection.clearSelectedFootprint();

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
    _stepsTimer?.cancel();
    _utcCountdown.dispose();
    _satelliteController.dispose();
    _locationProvider?.removeListener(onLocationUpdated);
    _captureController.dispose();
    _tileProvider.removeListener(notifyListeners);
    _tileProvider.dispose();
    _mapView.dispose();
    super.dispose();
  }
}
