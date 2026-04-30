import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../game/conquest_game.dart';
import '../../providers/game_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/geo_service.dart';
import '../screens/team_selection_screen.dart';
import '../widgets/alert_widget.dart';
import '../widgets/game_map_widget.dart';
import '../widgets/hud_overlay.dart';
import '../widgets/loading_overlay.dart';

/// 메인 게임 화면
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Future<void>? _initFuture;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 한 번만 초기화하여 FutureBuilder가 매번 초기화되지 않도록 함
    if (_initFuture == null) {
      final game = context.read<GameProvider>();
      final loc = context.read<LocationProvider>();
      
      _initFuture = Future.wait([
        game.initializationFuture,
        // GPS 수신을 무작정 기다리면 로딩이 지연되므로 최대 2초만 대기
        loc.firstLocationFuture.timeout(const Duration(seconds: 2), onTimeout: () {}),
      ]).timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('⚠️ 전술 데이터 로딩 시간 초과 - 강제 진입 시도');
        return [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    // 팀 미선택 시 팀 선택 화면
    if (game.selectedTeam == null) {
      return const TeamSelectionScreen();
    }

    final flameGame = context.read<ConquestGame>();
    final loc = context.watch<LocationProvider>();

    // Flame 엔진에 최신 상태 전달
    flameGame.updateCapturedTiles(
      capturedTiles: game.capturedTiles,
      capturingTileId: game.capturingTileId,
      captureProgress: game.captureProgress,
      capturingTeam: game.selectedTeam,
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
      backgroundColor: GameConstants.tacticalBlack,
      body: Stack(
        children: [
          // 지도 + Flame 레이어
          GameMapWidget(
            initialLocation: currentLocation,
            game: flameGame,
          ),

          // GPS 신호 없음 배너
          if (!loc.isGpsActive)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(200),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10)
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_off,
                          color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text('GPS 신호 없음 - 점령 불가',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

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

          // 로딩 오버레이 (비동기 처리)
          FutureBuilder(
            future: _initFuture,
            builder: (context, snapshot) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: snapshot.connectionState == ConnectionState.done
                    ? const SizedBox.shrink()
                    : const LoadingOverlay(message: '전술 위성 동기화 중...'),
              );
            },
          ),
        ],
      ),
    );
  }
}
