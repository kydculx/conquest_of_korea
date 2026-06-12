import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/achievement_model.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/colors.dart';
import '../widgets/tactical_app_bar.dart';

/// 플레이어의 업적 목록 및 달성률을 시각화하는 UI 화면 클래스
class AchievementScreen extends StatefulWidget {
  /// AchievementScreen 생성자
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  AchievementCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 최신 상태를 기반으로 미해금 업적들의 달성 조건 충족 여부를 즉시 자동 검사 및 해금 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final gameProvider = Provider.of<GameProvider>(context, listen: false);
        final achProvider = Provider.of<AchievementProvider>(context, listen: false);
        achProvider.checkAndUnlock(capturedTiles: gameProvider.capturedTiles);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final achProvider = Provider.of<AchievementProvider>(context);
    final profile = authProvider.profile;

    final unlockedIds = achProvider.unlockedAchievementIds;
    const allAchievements = Achievement.masterAchievements;

    // 필터 적용된 업적 목록
    final filteredAchievements = _selectedCategory == null
        ? allAchievements
        : allAchievements.where((a) => a.category == _selectedCategory).toList();

    // 전체 달성 통계
    final totalCount = allAchievements.length;
    final unlockedCount = allAchievements.where((a) => unlockedIds.contains(a.id)).length;
    final progressRatio = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Scaffold(
      // Cozy Dark 그라데이션 배경을 본문에 일관성 있게 장착
      appBar: TacticalAppBar(
        titleText: GameStrings.achievementBoardTitle,
        showBackButton: true,
      ),
      extendBodyBehindAppBar: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: GameColors.cozyDarkGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. 달성률 헤더 대시보드 (Glassmorphism & Neon)
              _buildHeaderDashboard(unlockedCount, totalCount, progressRatio),

              // 2. 카테고리 필터 칩 영역 (수평 스크롤)
              _buildCategoryFilterList(),

              // 3. 업적 리스트 (그리드뷰)
              Expanded(
                child: achProvider.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(GameColors.accentNeon),
                        ),
                      )
                    : filteredAchievements.isEmpty
                        ? Center(
                            child: Text(
                              '등록된 업적이 없습니다.',
                              style: TextStyle(
                                color: GameColors.textSecondary,
                                fontFamily: 'Fredoka',
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.82,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: filteredAchievements.length,
                            itemBuilder: (context, index) {
                              final ach = filteredAchievements[index];
                              final isUnlocked = unlockedIds.contains(ach.id);
                              return _buildAchievementCard(ach, isUnlocked, profile);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 상단 대시보드 위젯 (진척도 게이지 포함)
  Widget _buildHeaderDashboard(int unlockedCount, int totalCount, double progressRatio) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameColors.backgroundMedium.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GameColors.borderNeon,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: GameColors.accentNeon.withValues(alpha: 0.03),
            blurRadius: 12,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        children: [
          // 원형 게이지
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: progressRatio,
                  strokeWidth: 6,
                  backgroundColor: GameColors.dividerColor,
                  valueColor: AlwaysStoppedAnimation<Color>(GameColors.accentNeon),
                ),
              ),
              Text(
                '${(progressRatio * 100).toInt()}%',
                style: GoogleFonts.outfit(
                  color: GameColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // 정보 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  GameStrings.achievements,
                  style: TextStyle(
                    color: GameColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unlockedCount / $totalCount ${GameStrings.countUnit}',
                  style: GoogleFonts.outfit(
                    color: GameColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '모험을 통해 획득한 나의 성과표',
                  style: TextStyle(
                    color: GameColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// 카테고리 필터 리스트 (가로 스크롤)
  Widget _buildCategoryFilterList() {
    const categories = AchievementCategory.values;

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final cat = isAll ? null : categories[index - 1];
          final isSelected = _selectedCategory == cat;

          final label = isAll ? '전체' : _getCategoryName(cat!);
          final icon = isAll ? Icons.apps_rounded : _getCategoryIcon(cat!);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              avatar: Icon(
                icon,
                size: 15,
                color: isSelected ? GameColors.backgroundMedium : GameColors.accentNeon,
              ),
              label: Text(
                label,
                style: TextStyle(
                  color: isSelected ? GameColors.backgroundMedium : GameColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              selectedColor: GameColors.accentNeon,
              backgroundColor: GameColors.backgroundMedium.withValues(alpha: 0.6),
              checkmarkColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? GameColors.accentNeon : GameColors.borderLight,
                  width: 1.0,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = cat;
                });
              },
            ),
          );
        },
      ),
    );
  }

  /// 업적 카드 위젯
  Widget _buildAchievementCard(Achievement ach, bool isUnlocked, dynamic profile) {
    final tierColor = _getTierColor(ach.tier);
    final icon = _getCategoryIcon(ach.category);
    final currentVal = _getCurrentValueForCategory(ach.category, profile);

    return Container(
      decoration: BoxDecoration(
        color: isUnlocked
            ? GameColors.backgroundMedium.withValues(alpha: 0.85)
            : GameColors.backgroundMedium.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked ? tierColor.withValues(alpha: 0.7) : GameColors.borderLight,
          width: isUnlocked ? 1.5 : 1.0,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: tierColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // 티어 리본 탑라인
            if (isUnlocked)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 4,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        tierColor.withValues(alpha: 0.1),
                        tierColor,
                        tierColor.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),
            // 내부 패딩
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 아이콘 및 티어 라벨
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        isUnlocked ? icon : Icons.lock_outline_rounded,
                        color: isUnlocked ? tierColor : GameColors.textMuted.withValues(alpha: 0.5),
                        size: 22,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isUnlocked ? tierColor.withValues(alpha: 0.12) : GameColors.borderLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'T${ach.tier}',
                          style: TextStyle(
                            color: isUnlocked ? tierColor : GameColors.textMuted.withValues(alpha: 0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Fredoka',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 업적 명
                  Text(
                    tr(ach.titleKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isUnlocked ? GameColors.textPrimary : GameColors.textSecondary.withValues(alpha: 0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 업적 설명
                  Text(
                    tr(ach.descriptionKey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isUnlocked ? GameColors.textSecondary : GameColors.textMuted.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  // 진행 바 또는 해금 라벨
                  _buildProgressOrBadge(ach, isUnlocked, currentVal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 카드 하단 진척도 또는 획득 완료 표시 위젯
  Widget _buildProgressOrBadge(Achievement ach, bool isUnlocked, double currentVal) {
    if (isUnlocked) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.check_circle_outline_rounded, color: _getTierColor(ach.tier), size: 14),
          const SizedBox(width: 4),
          Text(
            GameStrings.unlocked,
            style: TextStyle(
              color: _getTierColor(ach.tier),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else {
      final ratio = ach.threshold > 0 ? (currentVal / ach.threshold).clamp(0.0, 1.0) : 0.0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentVal.toInt()}/${ach.threshold.toInt()}',
                style: TextStyle(color: GameColors.textMuted.withValues(alpha: 0.6), fontSize: 10, fontFamily: 'Fredoka'),
              ),
              Text(
                '${(ratio * 100).toInt()}%',
                style: TextStyle(color: GameColors.textMuted.withValues(alpha: 0.6), fontSize: 10, fontFamily: 'Fredoka'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 4,
              backgroundColor: GameColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(GameColors.textMuted.withValues(alpha: 0.4)),
            ),
          ),
        ],
      );
    }
  }

  // --- 유틸리티 매핑 함수들 ---

  /// 카테고리별 다국어 명칭 획득
  String _getCategoryName(AchievementCategory cat) {
    switch (cat) {
      case AchievementCategory.capturedTiles:
        return '누적 점령';
      case AchievementCategory.enemyCapturedTiles:
        return '상대 영토 점령';
      case AchievementCategory.totalMovedTiles:
        return '누적 이동';
      case AchievementCategory.dailyMovedTiles:
        return '일일 이동';
      case AchievementCategory.satelliteCapture:
        return '위성 원격 점령';
      case AchievementCategory.satelliteInfo:
        return '위성 정보 조회';
      case AchievementCategory.hqFortification:
        return '기지 주변 확장';
      case AchievementCategory.goldAmount:
        return '보유 골드';
    }
  }

  /// 카테고리별 대표 아이콘 매칭
  IconData _getCategoryIcon(AchievementCategory cat) {
    switch (cat) {
      case AchievementCategory.capturedTiles:
        return Icons.map_rounded;
      case AchievementCategory.enemyCapturedTiles:
        return Icons.swap_horiz_rounded;
      case AchievementCategory.totalMovedTiles:
        return Icons.directions_walk_rounded;
      case AchievementCategory.dailyMovedTiles:
        return Icons.today_rounded;
      case AchievementCategory.satelliteCapture:
        return Icons.satellite_alt_rounded;
      case AchievementCategory.satelliteInfo:
        return Icons.remove_red_eye_rounded;
      case AchievementCategory.hqFortification:
        return Icons.home_work_rounded;
      case AchievementCategory.goldAmount:
        return Icons.monetization_on_rounded;
    }
  }

  /// 티어에 따른 네온 테마 색상 획득
  Color _getTierColor(int tier) {
    switch (tier) {
      case 1:
        return const Color(0xFFFFB74D); // 브론즈 -> 솜사탕 오렌지 경보 컬러로 교체
      case 2:
        return const Color(0xFFB0BEC5); // 실버 -> 공용 서브 실버그레이 컬러
      case 3:
        return const Color(0xFFFFD54F); // 골드 -> 따뜻한 골드 옐로우
      case 4:
        return GameColors.accentNeon; // 마스터 -> 공용 솜사탕 네온 시안
      default:
        return GameColors.textSecondary;
    }
  }

  /// 카테고리별 유저 프로필 수치 게터
  double _getCurrentValueForCategory(AchievementCategory cat, dynamic profile) {
    if (profile == null) return 0.0;
    switch (cat) {
      case AchievementCategory.capturedTiles:
        return (profile.capturedTilesCount as num).toDouble();
      case AchievementCategory.enemyCapturedTiles:
        return (profile.enemyCapturedTilesCount as num).toDouble();
      case AchievementCategory.totalMovedTiles:
        return (profile.totalMovedTilesCount as num).toDouble();
      case AchievementCategory.dailyMovedTiles:
        return (profile.dailyMovedTilesCount as num).toDouble();
      case AchievementCategory.satelliteCapture:
        return (profile.satelliteCaptureCount as num).toDouble();
      case AchievementCategory.satelliteInfo:
        return (profile.satelliteScanCount as num).toDouble();
      case AchievementCategory.hqFortification:
        final gameProvider = Provider.of<GameProvider>(context, listen: false);
        final achProvider = Provider.of<AchievementProvider>(context, listen: false);
        return achProvider.getHQFortificationLevel(
          profile.mainBaseTileId,
          profile.id,
          gameProvider.capturedTiles,
        ).toDouble();
      case AchievementCategory.goldAmount:
        return (profile.gold as num).toDouble();
    }
  }
}
