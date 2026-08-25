import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/strings.dart';
import '../../providers/game_provider.dart';
import '../../core/constants/colors.dart';

/// [신규] 발자취 모드에서 선택된 타일의 발자취 정밀 세부 정보를 보여주는 플로팅 정보 카드 위젯
class FootprintInfoBubble extends StatelessWidget {
  const FootprintInfoBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final selectedId = game.selectedFootprintTileId;
    if (selectedId == null) return const SizedBox.shrink();

    final footprint = game.footprints[selectedId];
    if (footprint == null) return const SizedBox.shrink();

    final parts = selectedId.split('_');
    final int q = parts.length == 3 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final int r = parts.length == 3 ? (int.tryParse(parts[2]) ?? 0) : 0;

    return Center(
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Palette.charcoalLight.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Palette.footprintMint, // 발자취 전용 네온 청록색
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Palette.footprintMint.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 (타이틀 + 닫기 버튼)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.directions_walk_rounded,
                      color: Palette.footprintMint,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      GameStrings.footprintScanSuccess,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    game.selectFootprintTile(selectedId);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 좌표 정보
            Text(
              '구역 좌표: Q($q), R($r)',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            // 기록된 시간
            Text(
              '기록 일시: ${footprint.formattedTime}',
              style: const TextStyle(
                color: Palette.greyLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
