import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:easy_localization/easy_localization.dart';
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
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: ShapeDecoration(
              color: GameColors.backgroundMedium.withValues(alpha: 0.92),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: GameColors.accentNeon.withValues(alpha: 0.2),
                  width: 1.0,
                ),
              ),
            ),
            child: Center(
              child: Text(
                '아직 완성한 패턴이 없습니다. 패턴 도감맵을 모험해 보세요!',
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
          height: 76,
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
                      '${item.char} 패턴 영역으로 이동했습니다.',
                      AlertType.info,
                    );
                  },
                  child: Container(
                    width: 156,
                    padding: const EdgeInsets.all(12),
                    decoration: ShapeDecoration(
                      color: GameColors.backgroundMedium.withValues(alpha: 0.92),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: GameColors.accentNeon.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // 왼쪽에 크게 형광 파란색 패턴 문자 노출
                        Container(
                          width: 36,
                          height: 36,
                          decoration: ShapeDecoration(
                            color: const Color(0xFF0066FF).withValues(alpha: 0.15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                color: Color(0xFF0066FF),
                                width: 1.0,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              item.char,
                              style: GoogleFonts.fredoka(
                                color: const Color(0xFF0066FF),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 오른쪽에 텍스트 정보 노출
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '패턴 정복자: ${item.char}',
                                style: GoogleFonts.fredoka(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '타일 ${item.tiles.length}개로 완성',
                                style: GoogleFonts.quicksand(
                                  color: GameColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
