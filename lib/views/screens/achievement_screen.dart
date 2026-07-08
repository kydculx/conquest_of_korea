import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
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
  // 🧭 업적 종류 필터 칩 목록 정의
  final List<Map<String, dynamic>> _filterCategories = [
    {'id': 'ALL', 'labelKey': 'achCatAll'},
    {'id': 'CAPTURE', 'labelKey': 'achCatCapture'},
    {'id': 'EXPLORATION', 'labelKey': 'achCatExploration'},
    {'id': 'SATELLITE', 'labelKey': 'achCatSatellite'},
    {'id': 'FORTIFICATION', 'labelKey': 'achCatFortification'},
    {'id': 'GOLD', 'labelKey': 'achCatGold'},
    {'id': 'PHOTO', 'labelKey': 'achCatPhoto'},
    {'id': 'PATTERN', 'labelKey': 'achCatPattern'},
  ];

  String _activeFilterId = 'ALL';

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

  bool _matchesFilter(Achievement ach, String filterId) {
    if (filterId == 'ALL') return true;
    switch (filterId) {
      case 'CAPTURE':
        return ach.category == AchievementCategory.capturedTiles ||
               ach.category == AchievementCategory.enemyCapturedTiles;
      case 'EXPLORATION':
        return ach.category == AchievementCategory.totalMovedTiles ||
               ach.category == AchievementCategory.dailyMovedTiles ||
               ach.category == AchievementCategory.mainBaseMove;
      case 'SATELLITE':
        return ach.category == AchievementCategory.satelliteCapture ||
               ach.category == AchievementCategory.satelliteInfo;
      case 'FORTIFICATION':
        return ach.category == AchievementCategory.hqFortification;
      case 'GOLD':
        return ach.category == AchievementCategory.goldAmount;
      case 'PHOTO':
        return ach.category == AchievementCategory.photoUpload;
      case 'PATTERN':
        return ach.category == AchievementCategory.patternMatch;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final achProvider = Provider.of<AchievementProvider>(context);
    final profile = authProvider.profile;

    final unlockedIds = achProvider.unlockedAchievementIds;
    final allAchievements = Achievement.masterAchievements;

    // 전체 달성 통계
    final totalCount = allAchievements.length;
    final unlockedCount = allAchievements.where((a) => unlockedIds.contains(a.id)).length;
    final progressRatio = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    // 필터링 적용된 목록 산출
    final filteredAchievements = allAchievements
        .where((ach) => _matchesFilter(ach, _activeFilterId))
        .toList();

    return Scaffold(
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
              // 1. 달성률 헤더 대시보드
              _buildHeaderDashboard(unlockedCount, totalCount, progressRatio),

              // 2. 가로 스크롤 업적 종류 필터 칩 바
              _buildFilterChips(),
              const SizedBox(height: 12),

              // 3. 업적 리스트
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
                              GameStrings.noAchievements,
                              style: TextStyle(
                                color: GameColors.textSecondary,
                                fontFamily: 'Fredoka',
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: filteredAchievements.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
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

  /// 🧭 가로 스크롤링 카테고리 필터 칩 바 빌더
  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filterCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filterCategories[index];
          final id = filter['id'] as String;
          final labelKey = filter['labelKey'] as String;
          final isActive = _activeFilterId == id;

          return ChoiceChip(
            label: Text(
              labelKey.tr(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? GameColors.tacticalBlack : GameColors.textSecondary,
              ),
            ),
            selected: isActive,
            selectedColor: GameColors.accentNeon,
            backgroundColor: GameColors.backgroundMedium.withValues(alpha: 0.5),
            side: BorderSide(
              color: isActive ? GameColors.accentNeon : GameColors.borderLight,
              width: 1.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _activeFilterId = id;
                });
              }
            },
          );
        },
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
                  GameStrings.myAchievementSub,
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

  /// 업적 카드 위젯 (업적제목, 업적설명, 진척도 3가지 정보만 렌더링)
  Widget _buildAchievementCard(Achievement ach, bool isUnlocked, dynamic profile) {
    final currentVal = _getCurrentValueForCategory(ach.category, profile);
    final ratio = ach.threshold > 0 ? (currentVal / ach.threshold).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameColors.backgroundMedium.withValues(alpha: isUnlocked ? 0.85 : 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? GameColors.accentNeon.withValues(alpha: 0.5) : GameColors.borderLight,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 업적 제목
          Text(
            ach.getLocalizedTitle(),
            style: TextStyle(
              color: isUnlocked ? GameColors.textPrimary : GameColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          // 2. 업적 설명
          Text(
            ach.getLocalizedDescription(),
            style: TextStyle(
              color: GameColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          // 3. 진척도
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isUnlocked
                        ? '${ach.threshold.toInt()}/${ach.threshold.toInt()}'
                        : '${currentVal.toInt()}/${ach.threshold.toInt()}',
                    style: TextStyle(
                      color: isUnlocked ? GameColors.accentNeon : GameColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Fredoka',
                    ),
                  ),
                  Text(
                    isUnlocked ? '100%' : '${(ratio * 100).toInt()}%',
                    style: TextStyle(
                      color: isUnlocked ? GameColors.accentNeon : GameColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Fredoka',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: isUnlocked ? 1.0 : ratio,
                  minHeight: 6,
                  backgroundColor: GameColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUnlocked ? GameColors.accentNeon : GameColors.accentNeon.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
      case AchievementCategory.mainBaseMove:
        return (profile.mainBaseMoveCount as num).toDouble();
      case AchievementCategory.photoUpload:
        final achProvider = Provider.of<AchievementProvider>(context, listen: false);
        return achProvider.userUniquePhotoTilesCount.toDouble();
      case AchievementCategory.patternMatch:
        return 0.0;
    }
  }
}
