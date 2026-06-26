import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/game_provider.dart';
import 'tactical_press_button.dart';

/// 하단 우측 맵 뷰 모드 통합 순환 토글 버튼 (일반 ➔ 발자취 ➔ 패턴 도감 순환)
class MapModeToggleButton extends StatelessWidget {
  final double size;

  const MapModeToggleButton({required this.size, super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<GameProvider, MapMode>(
      selector: (_, provider) => provider.mapMode,
      builder: (context, mapMode, _) {
        List<Color> gradientColors;
        Color shadowColor;
        IconData iconData;
        Color iconColor;

        switch (mapMode) {
          case MapMode.normal:
            // 일반 모드: 내 영토(타일) 색상 기반 동적 그라데이션 및 나침반 아이콘
            final baseColor = GameColors.myTileColor;
            final hsl = HSLColor.fromColor(baseColor);
            final darkColor = hsl.withLightness((hsl.lightness - 0.25).clamp(0.0, 1.0)).toColor();
            gradientColors = [baseColor, darkColor];
            shadowColor = baseColor;
            iconData = Icons.explore_rounded;
            iconColor = Colors.white;
            break;
          case MapMode.footprint:
            // 발자취 모드: 네온 민트 그린 그라데이션 및 걷기 아이콘
            gradientColors = [const Color(0xFF00FFCC), const Color(0xFF00AA88)];
            shadowColor = const Color(0xFF00FFCC);
            iconData = Icons.directions_walk_rounded;
            iconColor = const Color(0xFF121212);
            break;
          case MapMode.pattern:
            // 패턴 도감 모드: 네온 블루 그라데이션 및 퍼즐 아이콘
            gradientColors = [const Color(0xFF0066FF), const Color(0xFF0033AA)];
            shadowColor = const Color(0xFF0066FF);
            iconData = Icons.extension_rounded;
            iconColor = Colors.white;
            break;
        }

        return TacticalPressButton(
          size: size,
          onTap: () {
            context.read<GameProvider>().cycleMapMode();
          },
          gradientColors: gradientColors,
          shadowColor: shadowColor,
          child: Icon(
            iconData,
            color: iconColor,
            size: size * 0.5,
          ),
        );
      },
    );
  }
}
