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

    // 전체 달성 통계
    final totalCount = allAchievements.length;
    final unlockedCount = allAchievements.where((a) => unlockedIds.contains(a.id)).length;
    final progressRatio = totalCount > 0 ? unlockedCount / totalCount : 0.0;

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

              // 2. 업적 리스트 (단일 열 리스트뷰)
              Expanded(
                child: achProvider.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(GameColors.accentNeon),
                        ),
                      )
                    : allAchievements.isEmpty
                        ? Center(
                            child: Text(
                              '등록된 업적이 없습니다.',
                              style: TextStyle(
                                color: GameColors.textSecondary,
                                fontFamily: 'Fredoka',
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: allAchievements.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final ach = allAchievements[index];
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
            tr(ach.titleKey),
            style: TextStyle(
              color: isUnlocked ? GameColors.textPrimary : GameColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          // 2. 업적 설명
          Text(
            tr(ach.descriptionKey),
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
    }
  }
}
