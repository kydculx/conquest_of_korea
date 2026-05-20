import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/constants/strings.dart';
import '../../game/conquest_game.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/geo_service.dart';
import '../screens/auth/social_profile_setup_screen.dart';
import '../widgets/alert_widget.dart';
import '../widgets/game_map_widget.dart';
import '../widgets/hud_overlay.dart';
import '../widgets/loading_overlay.dart';
import '../../models/tile_model.dart';

/// 메인 게임 화면
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final geo = context.read<GeoService>();
      geo.checkPermissions().then((ok) async {
        if (ok) {
          await geo.startTracking();
          _checkAndPromptBatteryOptimization(geo);
        }
      });
    });
  }

  Future<void> _checkAndPromptBatteryOptimization(GeoService geo) async {
    final bool isIgnoring = await geo.isIgnoringBatteryOptimizations();
    if (!isIgnoring && mounted) {
      _showBatteryOptimizationDialog(geo);
    }
  }

  void _showBatteryOptimizationDialog(GeoService geo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Container(
            decoration: ShapeDecoration(
              color: GameColors.backgroundMedium.withValues(alpha: 0.95),
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: GameColors.accentNeon,
                  width: 1.5,
                ),
              ),
              shadows: [
                BoxShadow(
                  color: GameColors.accentNeon.withValues(alpha: 0.35),
                  blurRadius: 15.0,
                  spreadRadius: 2.0,
                )
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.battery_alert_rounded,
                      color: GameColors.accentNeon,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '백그라운드 통신 보장 설정',
                        style: TextStyle(
                          color: GameColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: GameColors.dividerColor, height: 1),
                const SizedBox(height: 20),
                Text(
                  '본 앱은 실시간 위치 기반의 행정구역 점령 게임입니다.\n\n안드로이드 시스템 절전 정책에 의해 화면이 꺼지면 영토 점령 및 백그라운드 위성 동기화가 강제 차단될 수 있습니다.\n\n안정적인 점령 작전 수행을 위해 배터리 최적화 대상에서 [제한 없음]으로 제외 설정해 주세요.',
                  style: TextStyle(
                    color: GameColors.textPrimary.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(
                              color: GameColors.textMuted,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Text(
                          '나중에',
                          style: TextStyle(
                            color: GameColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          geo.requestIgnoreBatteryOptimizations();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GameColors.accentNeon,
                          foregroundColor: GameColors.tacticalBlack,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 4,
                          shadowColor: GameColors.accentNeon,
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          '설정하기',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final auth = context.watch<AuthProvider>();
    final flameGame = context.read<ConquestGame>();
    final loc = context.watch<LocationProvider>();

    // 인증은 되었으나 프로필 정보가 없는 경우 (SNS 최초 로그인 등) 설정 화면으로 리다이렉트
    if (auth.isAuthenticated && auth.profile == null && !auth.isLoading) {
      return const SocialProfileSetupScreen();
    }

    // 현재 사용자의 최신 색상을 자신의 타일에 즉시 반영 (데이터베이스 동기화 전에도 즉각 응답)
    final currentTiles = Map<String, HexTile>.from(game.capturedTiles);
    if (auth.profile != null) {
      currentTiles.updateAll((id, tile) {
        if (tile.userId == auth.user?.id) {
          return tile.copyWith(colorHex: auth.profile!.colorHex);
        }
        return tile;
      });
    }

    // Flame 엔진에 최신 상태 전달
    flameGame.updateCapturedTiles(
      capturedTiles: currentTiles,
      capturingTileId: game.capturingTileId,
      captureProgress: game.captureProgress,
      capturingColorHex: auth.profile?.colorHex,
      currentLocation: loc.currentLocation,
    );

    // 플레이어 위치/방향 갱신
    if (loc.currentLocation != null) {
      flameGame.updatePlayerLocation(loc.currentLocation!);
      flameGame.updatePlayerHeading(game.isMapRotationMode ? 0.0 : loc.heading);
    }

    final currentLocation =
        loc.currentLocation ?? GameConstants.defaultPosition;

    return Scaffold(
      backgroundColor: GameColors.tacticalBlack,
      body: Stack(
        children: [
          // 지도 + Flame 레이어
          GameMapWidget(initialLocation: currentLocation, game: flameGame),

          // HUD 레이어
          const HudOverlay(),

          // 전술 알림 레이어
          if (game.alerts.isNotEmpty)
            Positioned(
              top: 150,
              left: 20,
              right: 20,
              child: Column(
                children: game.alerts
                    .map((a) => AlertWidget(alert: a))
                    .toList(),
              ),
            ),

          // 로딩 오버레이 (상태 플래그 기반)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: game.isInitialized
                ? const SizedBox.shrink()
                : LoadingOverlay(
                    message: GameStrings.tacticalSatelliteSync,
                  ),
          ),
        ],
      ),
    );
  }
}
