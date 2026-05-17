import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/constants/strings.dart';
import '../../providers/game_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/auth_provider.dart';

/// 인게임 HUD 오버레이 (점수판, 점령 버튼, 유틸리티 버튼)
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final loc = context.watch<LocationProvider>();
    final auth = context.watch<AuthProvider>();

    return Stack(
      children: [
        // 상단 우측 로그인/프로필 버튼
        Positioned(
          top: 60,
          right: 20,
          child: _AuthProfileButton(auth: auth),
        ),


        // 점령 중 안내 텍스트
        if (auth.isAuthenticated && game.isCapturing)
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: GameColors.backgroundTranslucent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GameColors.dividerColor),
                ),
                child: Text(GameStrings.capturingZone,
                    style: TextStyle(
                        color: GameColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),

        // 수동 점령 버튼 (로그인 상태 & 수동 모드 & 점령 중이 아님 & 점령 가능할 때만 노출)
        if (auth.isAuthenticated && !game.isAutoCapture && !game.isCapturing && game.canCapture)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(child: _CaptureButton(game: game, loc: loc)),
          ),

        // 좌측 하단 유틸리티 버튼
        Positioned(
          left: 20,
          bottom: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _UtilButton(
                label: GameStrings.gpsReset,
                icon: Icons.flash_on,
                color: GameColors.warning,
                onTap: () => loc.resetGps(),
              ),
              const SizedBox(height: 12),
              _MapStyleButton(game: game),
              if (auth.isAuthenticated) ...[
                const SizedBox(height: 12),
                _UtilButton(
                  label: game.isAutoCapture ? GameStrings.auto : GameStrings.manual,
                  icon: game.isAutoCapture ? Icons.sync : Icons.touch_app,
                  color: game.isAutoCapture
                      ? GameColors.accentNeon
                      : GameColors.textMuted,
                  onTap: () => game.toggleAutoCapture(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthProfileButton extends StatelessWidget {
  final AuthProvider auth;
  const _AuthProfileButton({required this.auth});

  @override
  Widget build(BuildContext context) {
    final bool isAuth = auth.isAuthenticated;
    
    // 프로필 버튼은 공용 네온 그린 전술 컬러로 고정
    final Color color = isAuth 
        ? GameColors.accentNeon 
        : GameColors.textMuted;

    return GestureDetector(
      onTap: () {
        if (isAuth) {
          Navigator.pushNamed(context, '/profile');
        } else {
          Navigator.pushNamed(context, '/login');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: GameColors.backgroundMedium,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: (isAuth ? 100 : 50) / 255), 
            width: 1.5,
          ),
          boxShadow: isAuth 
              ? [BoxShadow(color: color.withValues(alpha: 50 / 255), blurRadius: 10)]
              : [],
        ),
        child: Icon(
          Icons.person_rounded,
          color: color,
          size: 28,
        ),
      ),
    );
  }
}

// --- 내부 위젯 ---

class _CaptureButton extends StatelessWidget {
  final GameProvider game;
  final LocationProvider loc;
  const _CaptureButton({required this.game, required this.loc});

  @override
  Widget build(BuildContext context) {
    final canCapture = game.canCapture;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (canCapture) {
              game.startManualCapture();
            } else {
              final auth = context.read<AuthProvider>();
              String reason = GameStrings.cannotCapture;
              if (!loc.isGpsActive || loc.currentAccuracy > GameConstants.captureAccuracyThreshold) {
                reason = GameStrings.gpsInaccurateCannotCapture;
              } else if (!auth.isAuthenticated) {
                reason = GameStrings.loginRequiredOperation;
              } else if (game.isAlreadyCapturedByMe) {
                reason = GameStrings.alreadyCapturedByMe;
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(reason),
                  backgroundColor: GameColors.backgroundMedium,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                )
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: canCapture
                  ? GameColors.error.withValues(alpha: 220 / 255)
                  : GameColors.textMuted.withValues(alpha: 150 / 255),
              shape: BoxShape.circle,
              border: Border.all(
                  color: GameColors.tacticalWhite.withValues(alpha: (canCapture ? 200 : 50) / 255),
                  width: 4),
              boxShadow: canCapture
                  ? [
                      BoxShadow(
                          color: GameColors.error.withValues(alpha: 150 / 255),
                          blurRadius: 25,
                          spreadRadius: 5)
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(canCapture ? Icons.radar : Icons.lock,
                    color: GameColors.tacticalWhite, size: 40),
                const SizedBox(height: 4),
                Text(canCapture ? GameStrings.captureAction : GameStrings.cannotCaptureLabel,
                    style: TextStyle(
                        color: GameColors.tacticalWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UtilButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _UtilButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                color: GameColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Material(
          color: GameColors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: GameColors.backgroundTranslucent,
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 100 / 255)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapStyleButton extends StatelessWidget {
  final GameProvider game;
  const _MapStyleButton({required this.game});

  static const _iconMap = <String, IconData>{
    'dark_mode': Icons.dark_mode,
    'satellite_alt': Icons.satellite_alt,
    'terrain': Icons.terrain,
    'add_road': Icons.add_road,
    'explore': Icons.explore,
    'brightness_5': Icons.brightness_5,
    'map': Icons.map,
    'public': Icons.public,
    'straighten': Icons.straighten,
    'filter_hdr': Icons.filter_hdr,
    'landscape': Icons.landscape,
    'directions_bike': Icons.directions_bike,
    'layers_clear': Icons.layers_clear,
  };

  @override
  Widget build(BuildContext context) {
    final style = game.currentMapStyle;
    final icon = _iconMap[style.icon] ?? Icons.map;
    return _UtilButton(
      label: style.name,
      icon: icon,
      color: game.showMap ? GameColors.tacticalWhite : GameColors.accentNeon,
      onTap: () => game.cycleMapStyle(),
    );
  }
}
