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
        if (ok) await geo.startTracking();
      });
    });
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
      flameGame.updatePlayerHeading(loc.heading);
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
                : const LoadingOverlay(message: GameStrings.tacticalSatelliteSync),
          ),
        ],
      ),
    );
  }
}
