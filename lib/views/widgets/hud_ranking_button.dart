import 'package:flutter/material.dart';
import 'tactical_press_button.dart';

/// 상단 우측 랭킹 버튼 (트로피 아이콘)
class RankingActionButton extends StatelessWidget {
  final double size;

  const RankingActionButton({required this.size, super.key});

  @override
  Widget build(BuildContext context) {
    return TacticalPressButton(
      size: size,
      onTap: () => Navigator.pushNamed(context, '/ranking'),
      child: const Icon(
        Icons.emoji_events_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
