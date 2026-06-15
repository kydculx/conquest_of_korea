import 'package:flutter/material.dart';
import '../../core/constants/app_routes.dart';
import 'tactical_press_button.dart';

/// 상단 우측 패턴 도감 버튼 (책 아이콘)
class PatternGuideActionButton extends StatelessWidget {
  final double size;

  const PatternGuideActionButton({required this.size, super.key});

  @override
  Widget build(BuildContext context) {
    return TacticalPressButton(
      size: size,
      onTap: () => Navigator.pushNamed(context, AppRoutes.patternGuide),
      child: const Icon(
        Icons.menu_book,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
