import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_routes.dart';
import '../../services/preferences_service.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/map_config.dart';
import '../../core/constants/strings.dart';
import '../../game/conquest_game.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../models/achievement_model.dart';
import '../widgets/achievement_toast.dart';
import '../../services/geo_service.dart';
import '../screens/auth/terms_agreement_screen.dart';
import '../widgets/tactical_alert_list.dart';
import '../widgets/game_map_widget.dart';
import '../widgets/hud_overlay.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/tactical_dialog.dart';
import '../../models/tile_model.dart';
import '../../models/alert_model.dart';

/// 메인 게임 화면
/// 실시간 헥사곤 지도와 플레이어의 실시간 GPS 위치를 화면 상에 시각화하고,
/// 알림(Alerts) 및 HUD 레이어를 동기화하여 인게임 루프를 조율하는 메인 게임 화면 클래스입니다.
class GameScreen extends StatefulWidget {
  /// 게임 화면의 생성자입니다.
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

/// [GameScreen]의 생명주기와 위치 추적 권한 및 배터리 절전 예외 처리를 관장하는 상태 클래스입니다.
class _GameScreenState extends State<GameScreen> {
  GameProvider? _gameProvider;
  AuthProvider? _authProvider;
  LocationProvider? _locationProvider;
  ConquestGame? _flameGame;
  AchievementProvider? _achievementProvider;
  StreamSubscription<Achievement>? _achievementSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final geo = context.read<GeoService>();
      geo.checkPermissions().then((ok) async {
        if (ok) {
          await geo.startTracking();

          // 안드로이드 환경이고 권한이 '앱 사용 중에만 허용(whileInUse)'인 경우 '항상 허용' 유도 (사용자가 명시적으로 거절한 적이 없을 때만)
          if (Platform.isAndroid) {
            final permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.whileInUse && mounted) {
              final isDismissed = await PreferencesService.isBgLocationDismissed();
              if (!isDismissed && mounted) {
                _showBackgroundLocationDialog();
              }
            }
          }

          _checkAndPromptBatteryOptimization(geo);
        }
      }).catchError((e) {
        debugPrint('⚠️ 위치 권한 확인 실패: $e');
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 1. 필요한 프로바이더 참조 획득 (listen: false 로 획득하여 watch로 인한 리빌드 차단)
    final newGameProvider = Provider.of<GameProvider>(context, listen: false);
    final newAuthProvider = Provider.of<AuthProvider>(context, listen: false);
    final newLocationProvider = Provider.of<LocationProvider>(context, listen: false);
    final newFlameGame = Provider.of<ConquestGame>(context, listen: false);
    final newAchProvider = Provider.of<AchievementProvider>(context, listen: false);

    // 2. 참조가 변경되었을 때만 기존 리스너 해제 및 신규 등록
    if (_gameProvider != newGameProvider ||
        _authProvider != newAuthProvider ||
        _locationProvider != newLocationProvider ||
        _flameGame != newFlameGame ||
        _achievementProvider != newAchProvider) {
      
      _gameProvider?.removeListener(_onStateChanged);
      _authProvider?.removeListener(_onStateChanged);
      _locationProvider?.removeListener(_onStateChanged);
      _achievementSubscription?.cancel();

      _gameProvider = newGameProvider;
      _authProvider = newAuthProvider;
      _locationProvider = newLocationProvider;
      _flameGame = newFlameGame;
      _achievementProvider = newAchProvider;

      _gameProvider?.addListener(_onStateChanged);
      _authProvider?.addListener(_onStateChanged);
      _locationProvider?.addListener(_onStateChanged);

      _achievementSubscription = _achievementProvider!.onAchievementUnlocked.listen((ach) {
        if (mounted) {
          AchievementToast.show(context, ach);
        }
      });

      // 최초 수동 동기화 트리거
      _onStateChanged();
    }
  }

  bool _isDuplicateDialogShowing = false;

  void _showDuplicateLoginDialog() {
    if (_isDuplicateDialogShowing) return;
    _isDuplicateDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return TacticalDialog(
          title: GameStrings.duplicateLoginTitle,
          icon: Icons.error_outline_rounded,
          accentColor: GameColors.accentNeon,
          content: Text(
            GameStrings.duplicateLoginMessage,
            style: TextStyle(
              color: GameColors.textPrimary.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _authProvider?.clearDuplicateLogoutFlag();
                Navigator.pop(context);
                _isDuplicateDialogShowing = false;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GameColors.accentNeon,
                foregroundColor: GameColors.tacticalBlack,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                GameStrings.confirm,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 프로바이더 내부 상태 변화 감지 시, UI 리빌드(Scaffold 빌드) 없이 Flame 게임 엔진의 데이터만 직접 동기화
  void _onStateChanged() {
    if (!mounted ||
        _gameProvider == null ||
        _authProvider == null ||
        _locationProvider == null ||
        _flameGame == null) {
      return;
    }

    // 중복 로그인 감지 시 처리
    if (_authProvider!.isDuplicateLoggedOut) {
      _showDuplicateLoginDialog();
      return;
    }

    final currentTiles = Map<String, HexTile>.from(_gameProvider!.capturedTiles);
    final profile = _authProvider!.profile;
    final userId = _authProvider!.user?.id;

    if (profile != null) {
      currentTiles.updateAll((id, tile) {
        if (tile.userId == userId) {
          return tile.copyWith(colorHex: GameColors.myTileColorHex);
        }
        return tile;
      });
    }

    _flameGame!.updateCapturedTiles(
      capturedTiles: currentTiles,
      capturingTileId: _gameProvider!.capturingTileId,
      captureProgress: _gameProvider!.captureProgress,
      capturingColorHex: GameColors.myTileColorHex,
      currentLocation: _locationProvider!.currentLocation,
      mainBaseTileId: profile?.mainBaseTileId,
      selectedScanTileId: _gameProvider!.selectedScanTileId,
      isScanMode: _gameProvider!.isScanMode,
      currentUserId: userId,
      isSatelliteCapturing: _gameProvider!.isSatelliteCapturing,
      satelliteCapturePhase: _gameProvider!.satelliteCapturePhase,
      satelliteTravelProgress: _gameProvider!.satelliteTravelProgress,
      satelliteCaptureProgress: _gameProvider!.satelliteCaptureProgress,
      satelliteCapturingTileId: _gameProvider!.satelliteCapturingTileId,
    );
  }

  @override
  void dispose() {
    _gameProvider?.removeListener(_onStateChanged);
    _authProvider?.removeListener(_onStateChanged);
    _locationProvider?.removeListener(_onStateChanged);
    _achievementSubscription?.cancel();
    super.dispose();
  }

  /// 안드로이드 OS에서 백그라운드 환경에서도 중단 없는 위치 갱신과 점령 작전을 수행하기 위해
  /// 사용자에게 위치 권한 설정을 [항상 허용]으로 유도하는 안내 팝업 다이얼로그를 표시합니다.
  void _showBackgroundLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return TacticalDialog(
          title: GameStrings.bgLocationSetupTitle,
          icon: Icons.location_on_rounded,
          accentColor: GameColors.accentNeon,
          content: Text(
            GameStrings.bgLocationSetupMessage,
            style: TextStyle(
              color: GameColors.textPrimary.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await PreferencesService.setBgLocationDismissed();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: GameColors.dividerColor, width: 1.0),
                ),
              ),
              child: Text(
                GameStrings.later,
                style: TextStyle(
                  color: GameColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Geolocator.openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GameColors.accentNeon,
                foregroundColor: GameColors.tacticalBlack,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                GameStrings.setupNow,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// OS가 임의로 백그라운드 서비스 동작 및 위치 권한 추적을 정지시키는 것을 방지하기 위해
  /// 배터리 최적화 무시 설정 대상인지 점검하고 필요시 가이드 팝업을 연계합니다. (거절한 플래그가 저장되어 있지 않은 경우에만)
  Future<void> _checkAndPromptBatteryOptimization(GeoService geo) async {
    final bool isIgnoring = await geo.isIgnoringBatteryOptimizations();
    if (!isIgnoring && mounted) {
      final isDismissed = await PreferencesService.isBgBatteryDismissed();
      if (!isDismissed && mounted) {
        _showBatteryOptimizationDialog(geo);
      }
    }
  }

  /// 안드로이드 OS의 배터리 최적화 예외 등록('제한 없음' 설정)을 통해 백그라운드 영토 탐지 서비스가
  /// 시스템에 의해 차단되지 않도록 환경설정 등록을 요청하고 유도하는 다이얼로그 팝업을 표시합니다.
  void _showBatteryOptimizationDialog(GeoService geo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return TacticalDialog(
          title: GameStrings.bgNetworkSetupTitle,
          icon: Icons.battery_alert_rounded,
          accentColor: GameColors.accentNeon,
          content: Text(
            GameStrings.bgNetworkSetupMessage,
            style: TextStyle(
              color: GameColors.textPrimary.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await PreferencesService.setBgBatteryDismissed();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: GameColors.dividerColor, width: 1.0),
                ),
              ),
              child: Text(
                GameStrings.later,
                style: TextStyle(
                  color: GameColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                geo.requestIgnoreBatteryOptimizations();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GameColors.accentNeon,
                foregroundColor: GameColors.tacticalBlack,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                GameStrings.setupNow,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double topOffset = topPadding > 0 ? topPadding + 12.0 : 24.0;

    // 1. SNS 최초 로그인 등 약관 동의 리다이렉트만 최상단에서 감시
    final isRedirectNeeded = context.select<AuthProvider, bool>((auth) =>
        auth.isAuthenticated && auth.profile == null && !auth.isLoading);

    if (isRedirectNeeded) {
      return const TermsAgreementScreen(isSocial: true);
    }

    // 2. 초기 맵 렌더링에 사용할 위치 획득 (최초 1회만 참조하고, 리스너가 지도 내부 제어를 직접 처리하므로 watch 차단)
    final locProvider = Provider.of<LocationProvider>(context, listen: false);
    final initialLocation = locProvider.currentLocation ?? MapConfig.defaultPosition;
    final flameGame = Provider.of<ConquestGame>(context, listen: false);

    return Scaffold(
      backgroundColor: GameColors.tacticalBlack,
      body: Stack(
        children: [
          // 지도 + Flame 레이어
          GameMapWidget(initialLocation: initialLocation, game: flameGame),

          // HUD 레이어 (내부에 Selector 처리를 장착하여 독립 렌더링)
          const HudOverlay(),

          // 알림 레이어 (알림 리스트 변동 시에만 국한 리빌드)
          Positioned(
            top: topOffset + 90.0,
            left: 20,
            right: 20,
            child: Selector<GameProvider, List<GameAlert>>(
              selector: (_, provider) => provider.alerts,
              builder: (context, alerts, child) {
                return TacticalAlertList(alerts: alerts);
              },
            ),
          ),

          // 로딩 오버레이 (초기화 완료 시점에만 가볍게 리빌드)
          Selector<GameProvider, bool>(
            selector: (_, provider) => provider.isInitialized,
            builder: (context, isInitialized, child) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: isInitialized
                    ? const SizedBox.shrink()
                    : LoadingOverlay(message: GameStrings.tacticalSatelliteSync),
              );
            },
          ),
        ],
      ),
    );
  }
}
