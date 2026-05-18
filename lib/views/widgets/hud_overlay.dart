import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/constants/strings.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';

/// 인게임 HUD 오버레이 (점수판, 점령 버튼, 유틸리티 버튼)
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final auth = context.watch<AuthProvider>();
    
    // 기기별 하단 제스처바/내비게이션바 안전 영역 높이 자동 산출
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    // 여백 조율을 위한 기본 하단 마진
    final double baseBottomMargin = bottomPadding > 0 ? 24.0 : 40.0;

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
            bottom: 140 + baseBottomMargin + bottomPadding,
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

        // 자동 점령(점령시작/정지) 버튼 (로그인 상태일 때 노출)
        if (auth.isAuthenticated)
          Positioned(
            bottom: baseBottomMargin + bottomPadding,
            left: 0,
            right: 0,
            child: Center(child: _StartStopCaptureButton(game: game)),
          ),

        // 우측 하단 유틸리티 버튼
        Positioned(
          right: 20,
          bottom: baseBottomMargin + bottomPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MapStyleButton(game: game),
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

class _StartStopCaptureButton extends StatelessWidget {
  final GameProvider game;
  const _StartStopCaptureButton({required this.game});

  @override
  Widget build(BuildContext context) {
    final isRunning = game.isAutoCapture;
    final Color activeColor = GameColors.accentNeon;
    final Color inactiveColor = GameColors.error;

    return GestureDetector(
      onTap: () {
        game.toggleAutoCapture();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 105,
        height: 105,
        decoration: BoxDecoration(
          color: isRunning
              ? activeColor.withValues(alpha: 210 / 255)
              : GameColors.backgroundMedium.withValues(alpha: 230 / 255),
          shape: BoxShape.circle,
          border: Border.all(
            color: isRunning
                ? GameColors.tacticalWhite
                : inactiveColor.withValues(alpha: 200 / 255),
            width: 3.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isRunning ? activeColor : inactiveColor).withValues(alpha: 120 / 255),
              blurRadius: isRunning ? 25 : 12,
              spreadRadius: isRunning ? 4 : 1,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
              color: isRunning ? GameColors.tacticalBlack : inactiveColor,
              size: 38,
            ),
            const SizedBox(height: 4),
            Text(
              isRunning ? GameStrings.stopCaptureMode : GameStrings.startCaptureMode,
              style: TextStyle(
                color: isRunning ? GameColors.tacticalBlack : GameColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
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
    return Material(
      color: GameColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: GameColors.backgroundMedium,
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 100 / 255),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
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
