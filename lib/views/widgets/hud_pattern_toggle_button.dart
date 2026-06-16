import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import 'tactical_press_button.dart';

/// 상단 우측 패턴 완료 타일 맵 오버레이 토글 버튼 (레이어 아이콘)
class PatternToggleActionButton extends StatelessWidget {
  final double size;

  const PatternToggleActionButton({required this.size, super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<GameProvider, bool>(
      selector: (_, provider) => provider.showCompletedPatterns,
      builder: (context, showCompleted, _) {
        // 활성화(ON) 시 일렉트릭 파란색, 비활성화(OFF) 시 차분한 회색조 그라데이션 적용
        final gradientColors = showCompleted
            ? [const Color(0xFF0066FF), const Color(0xFF0033AA)]
            : [const Color(0xFF37474F), const Color(0xFF212121)];

        final shadowColor = showCompleted
            ? const Color(0xFF0066FF)
            : const Color(0xFF212121);

        return TacticalPressButton(
          size: size,
          onTap: () {
            context.read<GameProvider>().toggleCompletedPatternsView();
          },
          gradientColors: gradientColors,
          shadowColor: shadowColor,
          child: Icon(
            showCompleted ? Icons.layers : Icons.layers_clear,
            color: showCompleted ? Colors.white : Colors.white.withValues(alpha: 0.6),
            size: 20,
          ),
        );
      },
    );
  }
}
