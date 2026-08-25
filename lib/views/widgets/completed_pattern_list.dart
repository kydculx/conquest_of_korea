import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../models/alert_model.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/game_provider.dart';
import '../../services/hex_service.dart';

/// 패턴 도감 모드일 때 하단에 플로팅 형태로 노출되는 완성 패턴 가로 카드 리스트 위젯
class CompletedPatternList extends StatelessWidget {
  const CompletedPatternList({super.key});

  /// 주어진 타일 ID 리스트의 지리적 중심 위경도(LatLng)를 계산합니다.
  LatLng _calculateCenter(List<String> tileIds) {
    if (tileIds.isEmpty) return const LatLng(37.5665, 126.9780); // 서울 시청 fallback

    double totalLat = 0;
    double totalLng = 0;
    int validCount = 0;

    for (final id in tileIds) {
      final parsed = HexService.parseTileId(id);
      if (parsed != null) {
        final latLng = HexService.hexToLatLng(parsed['q'] as int, parsed['r'] as int);
        totalLat += latLng.latitude;
        totalLng += latLng.longitude;
        validCount++;
      }
    }

    if (validCount == 0) return const LatLng(37.5665, 126.9780);
    return LatLng(totalLat / validCount, totalLng / validCount);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AchievementProvider, GameProvider>(
      builder: (context, achievementProvider, gameProvider, _) {
        final unlockedIds = achievementProvider.unlockedAchievementIds;
        final achTiles = achievementProvider.achievementTiles;

        // 완성 패턴 업적만 필터링 (ID가 ACH_PATTERN_으로 시작하는 항목)
        final completedPatterns = unlockedIds
            .where((id) => id.startsWith('ACH_PATTERN_'))
            .map((id) {
              final char = id.replaceFirst('ACH_PATTERN_', '');
              final tiles = achTiles[id] ?? [];
              final center = _calculateCenter(tiles);
              return _PatternItem(
                id: id,
                char: char,
                tiles: tiles,
                center: center,
              );
            })
            .where((item) => item.tiles.isNotEmpty)
            .toList();

        if (completedPatterns.isEmpty) {
          // 완성된 패턴이 하나도 없는 경우: 가이드 문구 노출
          return Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: ShapeDecoration(
              color: GameColors.backgroundMedium.withValues(alpha: 0.92),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: GameColors.accentNeon.withValues(alpha: 0.2),
                  width: 1.0,
                ),
              ),
            ),
            child: Center(
              child: Text(
                GameStrings.noCompletedPatterns,
                style: GoogleFonts.quicksand(
                  color: GameColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: completedPatterns.length,
            itemBuilder: (context, index) {
              final item = completedPatterns[index];
              return Padding(
                key: ValueKey(item.id),
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 8.0,
                  right: index == completedPatterns.length - 1 ? 0 : 8.0,
                ),
                child: GestureDetector(
                  onTap: () {
                    // 지도 이동 요청 트리거
                    gameProvider.requestMapMove(item.center);
                    // 이동 완료 배너 노출
                    gameProvider.addAlert(
                      GameStrings.patternAreaMoved(item.char),
                      AlertType.info,
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: ShapeDecoration(
                      color: Palette.brightBlue.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Palette.brightBlue,
                          width: 1.2,
                        ),
                      ),
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        item.char,
                        style: GoogleFonts.fredoka(
                          color: Palette.brightBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PatternItem {
  final String id;
  final String char;
  final List<String> tiles;
  final LatLng center;

  _PatternItem({
    required this.id,
    required this.char,
    required this.tiles,
    required this.center,
  });
}
