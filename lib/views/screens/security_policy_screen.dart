import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../widgets/tactical_app_bar.dart';

/// 사용자가 가입 후에도 언제든 서비스 이용약관, 개인정보처리방침, 위치정보 활용 동의 등의
/// 정책 전문을 열람할 수 있도록 지원하는 서비스 이용안내 화면 클래스입니다.
class SecurityPolicyScreen extends StatelessWidget {
  /// 서비스 이용안내 화면의 생성자입니다.
  const SecurityPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.tacticalBlack,
      appBar: TacticalAppBar(
        titleText: GameStrings.securityPolicy,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                GameStrings.securityPolicySub,
                style: TextStyle(
                  color: GameColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),

              // 정책 카드 리스트
              Container(
                decoration: ShapeDecoration(
                  color: GameColors.backgroundMedium.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: GameColors.dividerColor.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    _buildPolicyItem(
                      context: context,
                      title: GameStrings.agreeTermsBottomSheetTitle,
                      detailTitle: GameStrings.agreeTermsBottomSheetTitle,
                      detailText: GameStrings.agreeTermsDetail,
                    ),
                    _buildDivider(),
                    _buildPolicyItem(
                      context: context,
                      title: GameStrings.agreePrivacyBottomSheetTitle,
                      detailTitle: GameStrings.agreePrivacyBottomSheetTitle,
                      detailText: GameStrings.agreePrivacyDetail,
                    ),
                    _buildDivider(),
                    _buildPolicyItem(
                      context: context,
                      title: GameStrings.agreeLocationBottomSheetTitle,
                      detailTitle: GameStrings.agreeLocationBottomSheetTitle,
                      detailText: GameStrings.agreeLocationDetail,
                    ),
                    _buildDivider(),
                    _buildPolicyItem(
                      context: context,
                      title: GameStrings.agreeMarketingBottomSheetTitle,
                      detailTitle: GameStrings.agreeMarketingBottomSheetTitle,
                      detailText: GameStrings.agreeMarketingDetail,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              Center(
                child: Text(
                  '${GameStrings.appName} ${GameStrings.securityPolicy}',
                  style: TextStyle(
                    color: GameColors.textMuted.withValues(alpha: 100 / 255),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 개별 정책 항목 타일을 빌드하고 탭 시 상세 바텀시트를 호출합니다.
  Widget _buildPolicyItem({
    required BuildContext context,
    required String title,
    required String detailTitle,
    required String detailText,
  }) {
    return ListTile(
      onTap: () => _showDetailBottomSheet(context, detailTitle, detailText),
      leading: Icon(
        Icons.verified_user_rounded,
        color: GameColors.accentNeon.withValues(alpha: 180 / 255),
      ),
      title: Text(
        title,
        style: GoogleFonts.fredoka(
          color: GameColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.2,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: GameColors.dividerColor),
    );
  }

  /// 카드 내 메뉴 항목들을 선명하게 구분해주는 간결한 구분선 위젯입니다.
  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: GameColors.dividerColor.withValues(alpha: 30 / 255),
      indent: 16,
      endIndent: 16,
    );
  }

  /// 상세 약관 전문을 보여주는 모달 바텀시트를 Cozy Midnight 디자인 톤에 맞춰 호출합니다.
  void _showDetailBottomSheet(BuildContext context, String title, String detailText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GameColors.backgroundMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: GoogleFonts.fredoka(
                    color: GameColors.accentNeon,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      detailText,
                      style: GoogleFonts.quicksand(
                        color: GameColors.textSecondary,
                        fontSize: 13,
                        height: 1.6,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameColors.accentNeon,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    GameStrings.confirm,
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
