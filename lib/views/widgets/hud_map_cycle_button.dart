import 'package:flutter/material.dart';
import '../../providers/game_provider.dart';
import 'tactical_press_button.dart';

/// [신규] 하단 조작계 극좌측 날개에 배치되는 3D 솜사탕 보석 젤리 지도 스타일 순환 버튼
class MapStyleCycleButton extends StatelessWidget {
  final GameProvider game;
  final double size;
  final double iconSize;

  const MapStyleCycleButton({
    required this.game,
    this.size = 42.0,
    this.iconSize = 20.0,
    super.key,
  });

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
    return TacticalPressButton(
      size: size,
      onTap: game.cycleMapStyle,
      child: Icon(
        _getMapStyleIcon(game.currentMapStyle.icon),
        color: Colors.white,
        size: iconSize,
      ),
    );
  }
}
