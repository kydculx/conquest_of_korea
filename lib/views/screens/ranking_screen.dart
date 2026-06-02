import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ranking_provider.dart';
import '../../models/user_profile.dart';
import '../widgets/tactical_app_bar.dart';

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

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
      decoration: BoxDecoration(
        color: GameColors.backgroundMedium.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Center(
              child: Text(
                GameStrings.rankingHeaderRank,
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              GameStrings.nickname,
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            GameStrings.rankingHeaderCapturedTiles,
            style: const TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ranking = context.watch<RankingProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: GameColors.tacticalBlack,
      appBar: TacticalAppBar(
        titleText: GameStrings.tacticalRankingBoard,
        showBackButton: true,
        backgroundColor: GameColors.tacticalBlack,
      ),
      body: Stack(
        children: [
          // 배경 은은한 전술 격자 라인 데코레이션 (Premium Tactical aesthetic)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TacticalGridPainter(),
              ),
            ),
          ),

          // 랭킹 리스트 영역
          Positioned.fill(
            child: ranking.isLoading && ranking.topRankings.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      color: GameColors.accentNeon,
                    ),
                  )
                : Column(
                    children: [
                      _buildHeaderRow(),
                      Expanded(
                        child: _RankingListView(
                          ranking: ranking,
                          currentUserId: auth.user?.id,
                        ),
                      ),
                    ],
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

/// 랭킹 화면 전용 프리미엄 은은한 가로세로 격자 백그라운드 페인터
class _TacticalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.02)
      ..strokeWidth = 0.5;

    const double step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



/// 1위부터 100위까지 랭킹 리스트를 렌더링하는 위젯
class _RankingListView extends StatelessWidget {
  final RankingProvider ranking;
  final String? currentUserId;

  const _RankingListView({required this.ranking, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final list = ranking.topRankings;
    if (list.isEmpty) {
      return Center(
        child: Text(
          GameStrings.noRankingData,
          style: TextStyle(color: GameColors.textMuted, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 4,
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
    // 1위, 2위, 3위 특별 미래지향적 메달 그라데이션 테마
    List<Color>? medalGradient;
    Color rankTextColor = Colors.white;

    if (rank == 1) {
      medalGradient = [const Color(0xFFFFD700), const Color(0xFFFFA500)]; // Gold
      rankTextColor = const Color(0xFF5D4037);
    } else if (rank == 2) {
      medalGradient = [const Color(0xFFE0E0E0), const Color(0xFF9E9E9E)]; // Silver
      rankTextColor = const Color(0xFF37474F);
    } else if (rank == 3) {
      medalGradient = [const Color(0xFFFF8A65), const Color(0xFFD84315)]; // Bronze
      rankTextColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: isMe
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.08)
                  : GameColors.backgroundMedium.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isMe
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
                    : const Color(0xFF00E5FF).withValues(alpha: 0.08),
                width: isMe ? 1.5 : 1.0,
              ),
              boxShadow: isMe
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.06),
                        blurRadius: 10,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: SizedBox(
                width: 42,
                height: 42,
                child: Center(
                  child: medalGradient != null
                      ? Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: medalGradient,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: medalGradient.first.withValues(alpha: 0.3),
                                blurRadius: 6,
                                spreadRadius: 0.5,
                                offset: const Offset(0, 1.5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$rank',
                              style: GoogleFonts.quicksand(
                                color: rankTextColor,
                                fontSize: 13.0,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: GameColors.tacticalGray.withValues(alpha: 0.3),
                            border: Border.all(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                              width: 0.8,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$rank',
                              style: GoogleFonts.quicksand(
                                color: GameColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      profile.nickname,
                      style: GoogleFonts.fredoka(
                        color: isMe ? const Color(0xFF00E5FF) : GameColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: Text(
                _formatRankingValue(rankingType, profile),
                style: GoogleFonts.quicksand(
                  color: isMe ? const Color(0xFF00E5FF) : GameColors.textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 랭킹 타입에 맞추어 유저 데이터를 가독성 높게 포맷팅
  String _formatRankingValue(String type, UserProfile profile) {
    return GameStrings.territoryUnit(profile.capturedTilesCount);
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: GameColors.backgroundMedium.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.05),
                blurRadius: 16.0,
                spreadRadius: 1.0,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 내 순위 요약 배지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF00E5FF), Color(0xFF00838F)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Text(
                  rank > 0 ? GameStrings.rankUnit(rank) : GameStrings.rankUnranked,
                  style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // 내 에이전트 아이디 (top100stats 문구 제거)
              Expanded(
                child: Text(
                  GameStrings.nicknameWithMe(myProfile.nickname),
                  style: GoogleFonts.fredoka(
                    color: GameColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 내 기록 가독화 출력
              Text(
                _formatMyValue(ranking.currentType),
                style: GoogleFonts.quicksand(
                  color: const Color(0xFF00E5FF),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 랭킹 타입에 대칭되는 내 프로필 데이터 가독화 출력
  String _formatMyValue(String type) {
    return GameStrings.territoryUnit(myProfile.capturedTilesCount);
  }
}
