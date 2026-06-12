import 'package:flutter/material.dart';
import '../../core/constants/app_routes.dart';
import 'tactical_press_button.dart';

/// 상단 우측 업적 버튼 (별/배지 아이콘)
class AchievementActionButton extends StatelessWidget {
  final double size;

  const AchievementActionButton({required this.size, super.key});

  @override
  Widget build(BuildContext context) {
    return TacticalPressButton(
      size: size,
      onTap: () => Navigator.pushNamed(context, AppRoutes.achievement),
      child: const Icon(
        Icons.workspace_premium_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
