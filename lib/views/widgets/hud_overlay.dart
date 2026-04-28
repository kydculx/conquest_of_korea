import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/game_provider.dart';
import '../../providers/location_provider.dart';

/// 인게임 HUD 오버레이 (점수판, 점령 버튼, 유틸리티 버튼)
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final loc = context.watch<LocationProvider>();

    return Stack(
      children: [
        // 상단 점수판
        Positioned(
          top: 50,
          left: 30,
          right: 30,
          child: _ScoreBoard(scores: game.score),
        ),

        // 점령 중 안내 텍스트
        if (game.isCapturing)
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

        // 수동 점령 버튼
        if (!game.isAutoCapture && !game.isCapturing)
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
          ),
        ),
      ],
    );
  }
}

// --- 내부 위젯 ---

class _ScoreBoard extends StatelessWidget {
  final Map<String, int> scores;
  const _ScoreBoard({required this.scores});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(200),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(150), blurRadius: 15)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TeamScore('블루', scores['blue'] ?? 0, GameConstants.teamBlue),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('VS',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900)),
          ),
          _TeamScore('레드', scores['red'] ?? 0, GameConstants.teamRed),
        ],
      ),
    );
  }
}

class _TeamScore extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  const _TeamScore(this.label, this.score, this.color);

  @override
  Widget build(BuildContext context) {
    final scoreBox = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(score.toString(),
          style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace')),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: label == '레드'
          ? [scoreBox, const SizedBox(width: 8), Text(label, style: TextStyle(color: color.withAlpha(200), fontSize: 14, fontWeight: FontWeight.w900))]
          : [Text(label, style: TextStyle(color: color.withAlpha(200), fontSize: 14, fontWeight: FontWeight.w900)), const SizedBox(width: 8), scoreBox],
    );
  }
}

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
        if (loc.isGpsActive)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(150),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accuracy > GameConstants.captureAccuracyThreshold
                    ? Colors.red.withAlpha(150)
                    : Colors.green.withAlpha(150),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gps_fixed,
                    size: 12,
                    color: accuracy > GameConstants.captureAccuracyThreshold
                        ? Colors.red
                        : Colors.green),
                const SizedBox(width: 6),
                Text('오차: ${accuracy.toStringAsFixed(1)}m',
                    style: TextStyle(
                        color: accuracy > GameConstants.captureAccuracyThreshold
                            ? Colors.red
                            : Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        GestureDetector(
          onTap: canCapture ? () => game.startManualCapture() : null,
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
