import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/game_provider.dart';
import 'tactical_press_button.dart';

/// [신규] 하단 조작계 극우측 날개에 배치되는 3D 솜사탕 보석 젤리 내 위치 찾기 및 맵 회전 토글 버튼
class MapFollowRotationButton extends StatelessWidget {
  final double size;
  final double iconSize;

  const MapFollowRotationButton({
    this.size = 42.0,
    this.iconSize = 20.0,
    super.key,
  });

  IconData _getCurrentIcon(bool isFollowing, bool isRotation) {
    if (!isFollowing) {
      return Icons.my_location_rounded;
    }
    if (isRotation) {
      return Icons.navigation_rounded;
    }
    return Icons.my_location_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Selector<GameProvider, (bool, bool)>(
      selector: (_, provider) =>
          (provider.isFollowingUser, provider.isMapRotationMode),
      builder: (context, state, child) {
        final isFollowing = state.$1;
        final isRotation = state.$2;

        final icon = _getCurrentIcon(isFollowing, isRotation);
        final Color iconColor = switch ((isFollowing, isRotation)) {
          (true, true) => Colors.white,
          (true, false) => const Color(0xFF80DEEA),
          (false, false) => GameColors.textSecondary,
          (false, true) => const Color(0xFFFFD54F),
        };

        return TacticalPressButton(
          size: size,
          onTap: () {
            final game = context.read<GameProvider>();
            if (!isFollowing) {
              game.setFollowingUser(true);
            } else {
              game.toggleMapRotationMode();
            }
          },
          child: Icon(icon, color: iconColor, size: iconSize),
        );
      },
    );
  }
}
