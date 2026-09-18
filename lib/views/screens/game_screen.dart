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
import '../../providers/game_tile_provider.dart';
import '../../models/tile_attribute_model.dart';
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

  /// 첫 위치 수신 대기 타임아웃 여부 (15초 초과 시 재시도 UI 표시)
  bool _locationTimedOut = false;
  Timer? _locationWaitTimer;

  /// 위치 대기 타이머 시작 (수신 즉시 해제, 15초 초과 시 재시도 안내)
  void _startLocationWaitTimer() {
    _locationWaitTimer?.cancel();
    _locationTimedOut = false;
    _locationWaitTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted) return;
      final loc = _locationProvider ?? context.read<LocationProvider>();
      if (loc.currentLocation == null) {
        setState(() {
          _locationTimedOut = true;
        });
      }
    });
  }

  /// 위치 재시도: 권한 재확인 후 추적 재시작
  Future<void> _retryLocation() async {
    final geo = context.read<GeoService>();
    _startLocationWaitTimer();
    if (mounted) setState(() {});
    try {
      final ok = await geo.checkPermissions();
      if (ok) {
        await geo.startTracking();
      } else {
        // 권한 흐름이 설정 화면으로 넘어간 경우 복귀 후 상태 반영
        if (mounted) {
          setState(() {
            _locationTimedOut = true;
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ 위치 재시도 실패: $e');
    }
  }

  /// 위치 설정 화면 열기 (GPS 꺼짐이면 위치 설정, 그 외엔 앱 설정)
  Future<void> _openLocationSetup() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (enabled) {
      await Geolocator.openAppSettings();
    } else {
      await Geolocator.openLocationSettings();
    }
  }

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

      _startLocationWaitTimer();
      geo.checkPermissions().then((ok) async {
        if (ok) {
          await geo.startTracking();
        } else {
          // 권한 미획득 시 타임아웃 UI를 즉시 노출하여 대기 고착 방지
          if (mounted) {
            setState(() {
              _locationTimedOut = true;
            });
          }
        }
      }).catchError((e) {
        debugPrint('⚠️ 위치 권한 확인 실패: $e');
        if (mounted) {
          setState(() {
            _locationTimedOut = true;
          });
        }
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

    // 첫 위치 수신 시 대기 타임아웃 해제
    if (_locationProvider!.currentLocation != null && _locationTimedOut) {
      _locationWaitTimer?.cancel();
      if (mounted) {
        setState(() {
          _locationTimedOut = false;
        });
      } else {
        _locationTimedOut = false;
      }
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

    // [신규] 어드민이 정의한 타일 타입과 영역 내 속성을 함께 전달하여
    // 정적 지형(랜드마크 / 차단 구역) 색상이 점령 색상보다 우선 적용되도록 한다.
    final tileProvider = Provider.of<GameTileProvider>(context, listen: false);
    final adminTileTypes = Map<int, TileType>.from(tileProvider.tileTypes);
    final adminTileAttributes =
        Map<String, TileAttribute>.from(tileProvider.tileAttributes);

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
      tileTypes: adminTileTypes.isEmpty ? null : adminTileTypes,
      tileAttributes: adminTileAttributes.isEmpty ? null : adminTileAttributes,
    );
  }

  @override
  void dispose() {
    _locationWaitTimer?.cancel();
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
            top: topOffset + 132.0,
            left: 20,
            right: 20,
            child: Selector<GameProvider, List<GameAlert>>(
              selector: (_, provider) => provider.alerts,
              builder: (context, alerts, child) {
                if (alerts.isEmpty) return const SizedBox.shrink();
                return IgnorePointer(
                  child: TacticalAlertList(alerts: alerts),
                );
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
          // 첫 위치 수신 전까지 표시, 15초 초과 시 재시도/설정 버튼 노출
          Selector<LocationProvider, bool>(
            selector: (_, loc) => loc.currentLocation == null,
            builder: (context, waitingForLocation, child) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: waitingForLocation
                    ? (_locationTimedOut
                        ? _LocationRetryOverlay(
                            key: const ValueKey('gps-retry'),
                            onRetry: _retryLocation,
                            onOpenSettings: _openLocationSetup,
                          )
                        : LoadingOverlay(
                            key: const ValueKey('gps-waiting'),
                            message: GameStrings.searchingSignal,
                          ))
                    : const SizedBox.shrink(key: ValueKey('gps-ready')),
              );
            },
          ),

          // 온보딩 가이드 오버레이 (첫 GPS 위치 수신 전에는 표시하지 않고, 수신 후 자동 표시)
          Selector<LocationProvider, bool>(
            selector: (_, loc) => loc.currentLocation != null,
            builder: (context, gpsReceived, child) {
              if (!_showOnboarding || !gpsReceived) {
                return const SizedBox.shrink();
              }
              return OnboardingOverlay(
                onFinish: () async {
                  await PreferencesService.setSeenOnboarding();
                  if (mounted) {
                    setState(() {
                      _showOnboarding = false;
                    });
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 첫 위치 수신 지연 시 노출되는 재시도 오버레이
class _LocationRetryOverlay extends StatelessWidget {
  final Future<void> Function() onRetry;
  final Future<void> Function() onOpenSettings;

  const _LocationRetryOverlay({
    super.key,
    required this.onRetry,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: GameColors.tacticalBlack,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: GameColors.accentNeon.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: GameColors.accentNeon,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              GameStrings.searchingSignal,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameColors.accentNeon,
                    foregroundColor: GameColors.tacticalBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '다시 시도',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: onOpenSettings,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('설정 열기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
