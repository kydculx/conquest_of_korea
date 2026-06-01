import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../widgets/tactical_app_bar.dart';

/// 게임 플레이의 핵심적인 규칙과 시스템을 사용자에게
/// 아기자기하고 친근하게 안내하는 게임 설명서 화면입니다.
class GameGuideScreen extends StatelessWidget {
  /// 게임 설명서 화면 생성자입니다.
  const GameGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.tacticalBlack,
      appBar: TacticalAppBar(
        titleText: GameStrings.gameGuide,
        showBackButton: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: GameColors.cozyDarkGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 설명서 도입부 문구 카드
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  margin: const EdgeInsets.only(bottom: 24.0),
                  decoration: ShapeDecoration(
                    color: GameColors.backgroundMedium.withValues(alpha: 0.85),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: GameColors.accentNeon.withValues(alpha: 0.2),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        GameStrings.gameGuide,
                        style: GoogleFonts.fredoka(
                          color: GameColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        GameStrings.gameGuideSub,
                        style: GoogleFonts.quicksand(
                          color: GameColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // 가이드 카드 리스트
                _buildGuideCard(
                  title: GameStrings.guideOverviewTitle,
                  content: GameStrings.guideOverviewContent,
                ),
                _buildGuideCard(
                  title: GameStrings.guideAreaTitle,
                  content: GameStrings.guideAreaContent,
                ),
                _buildGuideCard(
                  title: GameStrings.guideCaptureTitle,
                  content: GameStrings.guideCaptureContent,
                ),
                _buildGuideCard(
                  title: GameStrings.guideMoveModeTitle,
                  content: GameStrings.guideMoveModeContent,
                ),
                _buildGuideCard(
                  title: GameStrings.guideRemoteModeTitle,
                  content: GameStrings.guideRemoteModeContent,
                ),
                _buildGuideCard(
                  title: GameStrings.guideHqTitle,
                  content: GameStrings.guideHqContent,
                ),
                _buildGuideCard(
                  title: GameStrings.guideRevealTitle,
                  content: GameStrings.guideRevealContent,
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 공통 가이드 카드 컴포넌트를 빌드합니다.
  Widget _buildGuideCard({
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: ShapeDecoration(
        color: GameColors.backgroundMedium.withValues(alpha: 0.65),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: GameColors.borderLight,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.fredoka(
              color: GameColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.quicksand(
              color: GameColors.textSecondary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
