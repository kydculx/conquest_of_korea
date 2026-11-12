import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import 'tactical_press_button.dart';

/// 상단 우측 업적 버튼 (별/배지 아이콘)
class AchievementActionButton extends StatelessWidget {
  final double size;

  const AchievementActionButton({required this.size, super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return TacticalPressButton(
      size: size,
      onTap: () {
        if (!auth.isAuthenticated) {
          Navigator.pushNamed(context, AppRoutes.login);
          return;
        }
        Navigator.pushNamed(context, AppRoutes.achievement);
      },
      child: const Icon(
        Icons.workspace_premium_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
