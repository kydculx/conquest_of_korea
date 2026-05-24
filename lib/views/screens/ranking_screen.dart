import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ranking_provider.dart';
import '../../models/user_profile.dart';

/// 요원들의 전술적 활약상과 지배력을 시각화하고 대조 분석할 수 있는 메인 전술 랭킹 화면 클래스
class RankingScreen extends StatefulWidget {
  /// RankingScreen 생성자
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 최초 빌드 완료 직후 최신 랭킹 데이터 비동기 조회 가동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RankingProvider>().loadRankings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ranking = context.watch<RankingProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: GameColors.tacticalBlack,
      appBar: AppBar(
        backgroundColor: GameColors.tacticalBlack,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: GameColors.accentNeon, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '전술 상황 랭킹판',
          style: TextStyle(
            color: GameColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _RankingCategoryTabs(ranking: ranking),
        ),
      ),
      body: Stack(
        children: [
          // 랭킹 리스트 영역
          Positioned.fill(
            child: ranking.isLoading && ranking.topRankings.isEmpty
                ? Center(
                    child: CircularProgressIndicator(color: GameColors.accentNeon),
                  )
                : _RankingListView(
                    ranking: ranking,
                    currentUserId: auth.user?.id,
                  ),
          ),

          // 하단 고정 내 랭킹 앵커 배너 (로그인 유저가 있고 프로필 정보가 유효할 시 항시 노출)
          if (auth.isAuthenticated && auth.profile != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom + 8.0
                  : 16.0,
              child: _MyRankingFloatingBanner(
                ranking: ranking,
                myProfile: auth.profile!,
              ),
            ),
        ],
      ),
    );
  }
}

/// 점령수 / 누적 이동 / 당일 이동 3대 카테고리 전환 탭 세그먼트 위젯
class _RankingCategoryTabs extends StatelessWidget {
  final RankingProvider ranking;
  const _RankingCategoryTabs({required this.ranking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: GameColors.tacticalGray.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GameColors.dividerColor, width: 1.0),
      ),
      child: Row(
        children: [
          _TabItem(
            label: '점령 영토',
            isActive: ranking.currentType == RankingType.capturedTiles,
            onTap: () => ranking.loadRankings(type: RankingType.capturedTiles),
          ),
          _TabItem(
            label: '누적 이동',
            isActive: ranking.currentType == RankingType.totalDistance,
            onTap: () => ranking.loadRankings(type: RankingType.totalDistance),
          ),
          _TabItem(
            label: '당일 보행',
            isActive: ranking.currentType == RankingType.dailyDistance,
            onTap: () => ranking.loadRankings(type: RankingType.dailyDistance),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? GameColors.accentNeon : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: GameColors.accentNeon.withValues(alpha: 0.35),
                      blurRadius: 8,
                      spreadRadius: 0.5,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? GameColors.tacticalBlack : GameColors.textSecondary,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 1위부터 100위까지 랭킹 리스트를 렌더링하는 위젯
class _RankingListView extends StatelessWidget {
  final RankingProvider ranking;
  final String? currentUserId;

  const _RankingListView({
    required this.ranking,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final list = ranking.topRankings;
    if (list.isEmpty) {
      return Center(
        child: Text(
          '랭킹 데이터가 존재하지 않습니다.',
          style: TextStyle(color: GameColors.textMuted, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 120 + MediaQuery.of(context).padding.bottom, // 하단 플로팅 배너 간섭 방지 패딩
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final profile = list[index];
        final rank = index + 1;
        final isMe = profile.id == currentUserId;

        return _RankingListTile(
          rank: rank,
          profile: profile,
          rankingType: ranking.currentType,
          isMe: isMe,
        );
      },
    );
  }
}

class _RankingListTile extends StatelessWidget {
  final int rank;
  final UserProfile profile;
  final String rankingType;
  final bool isMe;

  const _RankingListTile({
    required this.rank,
    required this.profile,
    required this.rankingType,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    // 1위, 2위, 3위 특별 금/은/동 네온 칼라 테두리 배정
    Color rankColor = GameColors.textSecondary;
    IconData? medalIcon;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
      medalIcon = Icons.emoji_events_rounded;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
      medalIcon = Icons.emoji_events_rounded;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      medalIcon = Icons.emoji_events_rounded;
    }

    // 전술 색상 파싱
    Color agentColor = GameColors.accentNeon;
    try {
      final hex = profile.colorHex.replaceFirst('#', '');
      agentColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: ShapeDecoration(
        color: isMe 
            ? GameColors.accentNeon.withValues(alpha: 0.12)
            : GameColors.tacticalGray.withValues(alpha: 0.25),
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isMe 
                ? GameColors.accentNeon.withValues(alpha: 0.7)
                : GameColors.dividerColor,
            width: isMe ? 1.5 : 1.0,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: SizedBox(
          width: 50,
          child: Row(
            children: [
              // 순위 숫자 또는 메달
              if (medalIcon != null)
                Icon(medalIcon, color: rankColor, size: 18)
              else
                Text(
                  '$rank',
                  style: TextStyle(
                    color: rankColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              const Spacer(),
              // 요원 고유 컬러 글로우 도트
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: agentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: agentColor.withValues(alpha: 0.8),
                      blurRadius: 4.0,
                      spreadRadius: 1.0,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                profile.nickname,
                style: TextStyle(
                  color: isMe ? GameColors.accentNeon : GameColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isMe)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: ShapeDecoration(
                  color: GameColors.accentNeon,
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                child: Text(
                  '요원(나)',
                  style: TextStyle(
                    color: GameColors.tacticalBlack,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        trailing: Text(
          _formatRankingValue(rankingType, profile),
          style: TextStyle(
            color: isMe ? GameColors.accentNeon : GameColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  /// 랭킹 타입에 맞추어 유저 데이터를 가독성 높게 포맷팅
  String _formatRankingValue(String type, UserProfile profile) {
    if (type == RankingType.capturedTiles) {
      return '${profile.capturedTilesCount} 구역';
    } else {
      final double distance = type == RankingType.totalDistance 
          ? profile.totalDistance 
          : profile.dailyDistance;

      if (distance >= 1000.0) {
        return '${(distance / 1000.0).toStringAsFixed(2)} km';
      } else {
        return '${distance.toStringAsFixed(0)} m';
      }
    }
  }
}

/// 하단 플로팅 형태로 항시 고정되는 나의 전술 순위 패널
class _MyRankingFloatingBanner extends StatelessWidget {
  final RankingProvider ranking;
  final UserProfile myProfile;

  const _MyRankingFloatingBanner({
    required this.ranking,
    required this.myProfile,
  });

  @override
  Widget build(BuildContext context) {
    final int rank = ranking.myRanking;
    final String myColor = myProfile.colorHex;
    Color agentColor = GameColors.accentNeon;
    try {
      final hex = myColor.replaceFirst('#', '');
      agentColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: ShapeDecoration(
        color: GameColors.backgroundMedium,
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: GameColors.accentNeon.withValues(alpha: 0.4), width: 1.5),
        ),
        shadows: [
          BoxShadow(
            color: GameColors.accentNeon.withValues(alpha: 0.15),
            blurRadius: 15.0,
            spreadRadius: 2.0,
            offset: const Offset(0, -3),
          )
        ],
      ),
      child: Row(
        children: [
          // 내 순위 요약 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: ShapeDecoration(
              color: GameColors.accentNeon,
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              rank > 0 ? '$rank위' : '순위 미정',
              style: TextStyle(
                color: GameColors.tacticalBlack,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // 내 에이전트 아이디 및 프로필 컬러 글로우 도트
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: agentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: agentColor.withValues(alpha: 0.8),
                            blurRadius: 3,
                            spreadRadius: 0.5,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${myProfile.nickname} (나)',
                        style: TextStyle(
                          color: GameColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '상위 100위 랭킹 통계 정보',
                  style: TextStyle(
                    color: GameColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // 내 기록 가독화 출력
          Text(
            _formatMyValue(ranking.currentType),
            style: TextStyle(
              color: GameColors.accentNeon,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// 랭킹 타입에 대칭되는 내 프로필 데이터 가독화 출력
  String _formatMyValue(String type) {
    if (type == RankingType.capturedTiles) {
      return '${myProfile.capturedTilesCount} 구역';
    } else {
      final double distance = type == RankingType.totalDistance 
          ? myProfile.totalDistance 
          : myProfile.dailyDistance;

      if (distance >= 1000.0) {
        return '${(distance / 1000.0).toStringAsFixed(2)} km';
      } else {
        return '${distance.toStringAsFixed(0)} m';
      }
    }
  }
}
