import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/map_config.dart';
import '../../core/constants/strings.dart';
import '../../game/conquest_game.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/geo_service.dart';
import '../screens/auth/terms_agreement_screen.dart';
import '../widgets/alert_widget.dart';
import '../widgets/game_map_widget.dart';
import '../widgets/hud_overlay.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/tactical_dialog.dart';
import '../../models/tile_model.dart';

/// 메인 게임 화면
/// 실시간 헥사곤 전술 지도와 요원의 실시간 GPS 위치를 화면 상에 시각화하고,
/// 알림(Alerts) 및 HUD 레이어를 동기화하여 인게임 루프를 조율하는 메인 게임 화면 클래스입니다.
class GameScreen extends StatefulWidget {
  /// 게임 화면의 생성자입니다.
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

/// [GameScreen]의 생명주기와 위치 추적 권한 및 배터리 절전 예외 처리를 관장하는 상태 클래스입니다.
class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final geo = context.read<GeoService>();
      geo.checkPermissions().then((ok) async {
        if (ok) {
          await geo.startTracking();

          // 안드로이드 환경이고 권한이 '앱 사용 중에만 허용(whileInUse)'인 경우 '항상 허용' 유도
          if (Platform.isAndroid) {
            final permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.whileInUse && mounted) {
              _showBackgroundLocationDialog();
            }
          }

          _checkAndPromptBatteryOptimization(geo);
        }
      });
    });
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
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: GameColors.textMuted, width: 1.0),
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
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
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
  /// 배터리 최적화 무시 설정 대상인지 점검하고 필요시 가이드 팝업을 연계합니다.
  Future<void> _checkAndPromptBatteryOptimization(GeoService geo) async {
    final bool isIgnoring = await geo.isIgnoringBatteryOptimizations();
    if (!isIgnoring && mounted) {
      _showBatteryOptimizationDialog(geo);
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
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: GameColors.textMuted, width: 1.0),
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
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
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
    final game = context.watch<GameProvider>();
    final auth = context.watch<AuthProvider>();
    final flameGame = context.read<ConquestGame>();
    final loc = context.read<LocationProvider>();

    final double topPadding = MediaQuery.of(context).padding.top;
    final double topOffset = topPadding > 0 ? topPadding + 12.0 : 24.0;

    // 인증은 되었으나 프로필 정보가 없는 경우 (SNS 최초 로그인 등) 약관 동의 화면으로 리다이렉트
    if (auth.isAuthenticated && auth.profile == null && !auth.isLoading) {
      return const TermsAgreementScreen(isSocial: true);
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

    flameGame.updateCapturedTiles(
      capturedTiles: currentTiles,
      capturingTileId: game.capturingTileId,
      captureProgress: game.captureProgress,
      capturingColorHex: auth.profile?.colorHex,
      currentLocation: loc.currentLocation,
      mainBaseTileId: auth.profile?.mainBaseTileId,
      selectedScanTileId: game.selectedScanTileId,
      isScanMode: game.isScanMode,
      currentUserId: auth.user?.id,
      isSatelliteCapturing: game.isSatelliteCapturing,
      satelliteCapturePhase: game.satelliteCapturePhase,
      satelliteTravelProgress: game.satelliteTravelProgress,
      satelliteCaptureProgress: game.satelliteCaptureProgress,
      satelliteCapturingTileId: game.satelliteCapturingTileId,
    );

    final currentLocation = loc.currentLocation ?? MapConfig.defaultPosition;

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
              top: topOffset + 90.0,
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
                : LoadingOverlay(message: GameStrings.tacticalSatelliteSync),
          ),
        ],
      ),
    );
  }
}
