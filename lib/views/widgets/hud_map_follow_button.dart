import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/game_provider.dart';

/// [신규] 하단 조작계 극우측 날개에 배치되는 3D 솜사탕 보석 젤리 내 위치 찾기 및 맵 회전 토글 버튼
class MapFollowRotationButton extends StatefulWidget {
  final double size;
  final double iconSize;

  const MapFollowRotationButton({
    this.size = 42.0,
    this.iconSize = 20.0,
    super.key,
  });

  @override
  State<MapFollowRotationButton> createState() =>
      MapFollowRotationButtonState();
}

class MapFollowRotationButtonState extends State<MapFollowRotationButton> {
  bool _isPressed = false;

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

        final IconData icon = _getCurrentIcon(isFollowing, isRotation);

        final Color iconColor;
        if (!isFollowing) {
          iconColor = GameColors.textSecondary;
        } else if (isRotation) {
          iconColor = Colors.white;
        } else {
          iconColor = const Color(0xFF80DEEA);
        }

        final double glowRadius = widget.size * 0.38;

        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapCancel: () => setState(() => _isPressed = false),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            final game = context.read<GameProvider>();
            if (!isFollowing) {
              game.setFollowingUser(true);
            } else {
              game.toggleMapRotationMode();
            }
          },
          child: AnimatedScale(
            scale: _isPressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF00E5FF),
                    const Color(0xFF00838F),
                  ],
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
                      icon,
                      color: iconColor,
                      size: widget.iconSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
