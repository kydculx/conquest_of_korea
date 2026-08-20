import 'dart:async';
import 'package:flutter/material.dart';
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
import '../widgets/onboarding_overlay.dart';

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
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final geo = context.read<GeoService>();

      // 최초 로그인 온보딩 가이드 체크
      final hasSeen = await PreferencesService.hasSeenOnboarding();
      if (!hasSeen && mounted) {
        setState(() {
          _showOnboarding = true;
        });
      }

      geo.checkPermissions().then((ok) async {
        if (ok) {
          await geo.startTracking();
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
      showCompletedPatterns: _gameProvider!.showCompletedPatterns,
      consumedTileIds: _gameProvider!.showCompletedPatterns
          ? (_achievementProvider?.consumedTileIds ?? {})
          : {},
      coins: _gameProvider!.coins,
      showFootprints: _gameProvider!.isFootprintMode,
      footprints: _gameProvider!.footprints,
      selectedFootprintTileId: _gameProvider!.selectedFootprintTileId,
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

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double topOffset = topPadding > 0 ? topPadding + 12.0 : 24.0;

    // 1. SNS 최초 로그인 등 약관 동의 리다이렉트만 최상단에서 감시
    // 프로필 로딩 중 깜빡임 방지: 로그인되었으나 프로필 정보가 없고 아직 로딩 중인 상태
    final isAuthPending = context.select<AuthProvider, bool>((auth) =>
        auth.isAuthenticated && auth.profile == null && (auth.isLoading || auth.isProfileLoading));

    if (isAuthPending) {
      return Scaffold(
        backgroundColor: GameColors.tacticalBlack,
        body: Container(
          decoration: const BoxDecoration(
            gradient: GameColors.cozyDarkGradient,
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: GameColors.accentNeon,
            ),
          ),
        ),
      );
    }

    // isProfileLoading: 로그인 직후 프로필 로딩 중에는 리다이렉트하지 않음 (깜빡임 방지)
    final isRedirectNeeded = context.select<AuthProvider, bool>((auth) =>
        auth.isAuthenticated && auth.profile == null && !auth.isLoading && !auth.isProfileLoading);

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
          HudOverlay(
            onProfileClosed: () async {
              final hasSeen = await PreferencesService.hasSeenOnboarding();
              if (!hasSeen && mounted) {
                setState(() {
                  _showOnboarding = true;
                });
              }
            },
          ),

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

          // GPS 위치 미획득 로딩 오버레이
          // 첫 위치 수신 전까지 "로딩중" 원형 인디케이터를 화면 중앙에 표시
          Selector<LocationProvider, bool>(
            selector: (_, loc) => loc.currentLocation == null,
            builder: (context, waitingForLocation, child) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: waitingForLocation
                    ? LoadingOverlay(
                        key: const ValueKey('gps-waiting'),
                        message: GameStrings.searchingSignal,
                      )
                    : const SizedBox.shrink(key: ValueKey('gps-ready')),
              );
            },
          ),

          // 온보딩 가이드 오버레이 (최초 진입 시)
          if (_showOnboarding)
            OnboardingOverlay(
              onFinish: () async {
                await PreferencesService.setSeenOnboarding();
                if (mounted) {
                  setState(() {
                    _showOnboarding = false;
                  });
                }
              },
            ),
        ],
      ),
    );
  }
}
