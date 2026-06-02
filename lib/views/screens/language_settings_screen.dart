import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/toast_helper.dart';
import '../widgets/tactical_app_bar.dart';

/// 앱의 표시 언어(한국어, 영어 등)를 변경하고 실시간으로 다국어를 적용할 수 있도록
/// 지원하는 앱 언어 설정 화면 클래스입니다.
class LanguageSettingsScreen extends StatelessWidget {
  /// 언어 설정 화면의 생성자입니다.
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = EasyLocalization.of(context)!.locale;

    return Scaffold(
      backgroundColor: GameColors.tacticalBlack,
      appBar: TacticalAppBar(
        titleText: GameStrings.languageSettings,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                GameStrings.selectLanguage,
                style: TextStyle(
                  color: GameColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),

              // 언어 선택 카드 목록
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
                    _buildLanguageItem(
                      context: context,
                      title: GameStrings.languageKorean,
                      locale: const Locale('ko'),
                      isSelected: currentLocale.languageCode == 'ko',
                    ),
                    Divider(
                      height: 1,
                      color: GameColors.dividerColor.withValues(alpha: 30 / 255),
                      indent: 16,
                      endIndent: 16,
                    ),
                    _buildLanguageItem(
                      context: context,
                      title: GameStrings.languageEnglish,
                      locale: const Locale('en'),
                      isSelected: currentLocale.languageCode == 'en',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              Center(
                child: Text(
                  GameStrings.appO10NSystem,
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

  /// 개별 언어 선택 항목 타일을 빌드합니다.
  Widget _buildLanguageItem({
    required BuildContext context,
    required String title,
    required Locale locale,
    required bool isSelected,
  }) {
    final activeColor = isSelected ? GameColors.accentNeon : GameColors.textPrimary;

    return ListTile(
      onTap: () async {
        if (!isSelected) {
          final targetMessage = locale.languageCode == 'ko'
              ? GameStrings.languageChangedToKorean
              : GameStrings.languageChangedToEnglish;

          await EasyLocalization.of(context)!.setLocale(locale);
          if (context.mounted) {
            ToastHelper.show(
              context: context,
              message: targetMessage,
              isSuccess: true,
            );
          }
        }
      },
      leading: Icon(
        Icons.language_rounded,
        color: activeColor.withValues(alpha: 180 / 255),
      ),
      title: Text(
        title,
        style: GoogleFonts.fredoka(
          color: activeColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.2,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle_outline_rounded,
              color: GameColors.accentNeon,
            )
          : null,
    );
  }
}
