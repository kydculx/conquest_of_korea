import 'package:flutter/material.dart';
import '../../providers/game_provider.dart';

/// [신규] 하단 조작계 극좌측 날개에 배치되는 3D 솜사탕 보석 젤리 지도 스타일 순환 버튼
class MapStyleCycleButton extends StatefulWidget {
  final GameProvider game;
  final double size;
  final double iconSize;

  const MapStyleCycleButton({
    required this.game,
    this.size = 42.0,
    this.iconSize = 20.0,
    super.key,
  });

  @override
  State<MapStyleCycleButton> createState() => MapStyleCycleButtonState();
}

class MapStyleCycleButtonState extends State<MapStyleCycleButton> {
  bool _isPressed = false;

  IconData _getMapStyleIcon(String iconName) {
    const iconMap = <String, IconData>{
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
    return iconMap[iconName] ?? Icons.map;
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final double glowRadius = widget.size * 0.38;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        game.cycleMapStyle();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF00E5FF),
                Color(0xFF00838F),
              ], // 상시 정 가동 상태인 사이버 네온 시안 젤리 톤 적용
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2.5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 3D 젤리 반사광 오버레이
              Positioned(
                top: 2,
                left: 5,
                right: 5,
                height: glowRadius,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(glowRadius),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.45),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Icon(
                  _getMapStyleIcon(game.currentMapStyle.icon),
                  color: Colors.white,
                  size: widget.iconSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
