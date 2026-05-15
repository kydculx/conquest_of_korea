import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
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
                  color: Colors.black.withAlpha(180),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text('구역 점령 중...',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),

        // 수동 점령 버튼 (로그인 상태에서만)
        if (auth.isAuthenticated && !game.isAutoCapture && !game.isCapturing)
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
                label: 'GPS 리셋',
                icon: Icons.flash_on,
                color: Colors.orange,
                onTap: () => loc.resetGps(),
              ),
              const SizedBox(height: 12),
              _MapStyleButton(game: game),
              if (auth.isAuthenticated) ...[
                const SizedBox(height: 12),
                _UtilButton(
                  label: game.isAutoCapture ? '자동' : '수동',
                  icon: game.isAutoCapture ? Icons.sync : Icons.touch_app,
                  color: game.isAutoCapture
                      ? GameConstants.accentNeon
                      : Colors.white54,
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
    if (auth.isAuthenticated) {
      final profile = auth.profile;
      final color = profile != null ? TacticalTheme.parseColor(profile.colorHex) : Colors.white;
      
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/profile'),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(200),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withAlpha(100), width: 1.5),
            boxShadow: [
              BoxShadow(color: color.withAlpha(50), blurRadius: 10)
            ],
          ),
          child: Icon(
            Icons.person_rounded,
            color: color,
            size: 28,
          ),
        ),
      );
    }

    return _UtilButton(
      label: '로그인',
      icon: Icons.login,
      color: GameConstants.accentNeon,
      onTap: () => Navigator.pushNamed(context, '/login'),
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
    final accuracy = loc.currentAccuracy;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (canCapture) {
              game.startManualCapture();
            } else {
              final auth = context.read<AuthProvider>();
              String reason = "점령할 수 없는 상태입니다.";
              if (!loc.isGpsActive || loc.currentAccuracy > GameConstants.captureAccuracyThreshold) {
                reason = "위치 정보가 부정확하여 점령할 수 없습니다.";
              } else if (!auth.isAuthenticated) {
                reason = "로그인이 필요한 작전입니다.";
              } else if (game.isAlreadyCapturedByMe) {
                reason = "이미 당신이 점령한 지역입니다.";
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(reason),
                  backgroundColor: Colors.black87,
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
                  ? Colors.red.withAlpha(220)
                  : Colors.grey.withAlpha(150),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withAlpha(canCapture ? 200 : 50),
                  width: 4),
              boxShadow: canCapture
                  ? [
                      BoxShadow(
                          color: Colors.red.withAlpha(150),
                          blurRadius: 25,
                          spreadRadius: 5)
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(canCapture ? Icons.radar : Icons.lock,
                    color: Colors.white, size: 40),
                const SizedBox(height: 4),
                Text(canCapture ? '점령하기' : '점령불가',
                    style: const TextStyle(
                        color: Colors.white,
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
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(180),
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(100)),
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
      color: game.showMap ? Colors.white : GameConstants.accentNeon,
      onTap: () => game.cycleMapStyle(),
    );
  }
}
