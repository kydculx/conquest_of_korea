import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/version_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../services/preferences_service.dart';
import '../widgets/tactical_app_bar.dart';
import '../widgets/profile_widgets.dart';
import '../widgets/profile/account_dialogs.dart';
import '../widgets/profile/contact_support.dart';
import '../widgets/profile/gps_accuracy_dialog.dart';
import '../widgets/profile/notification_sub_settings.dart';
import '../widgets/profile/nickname_change_dialog.dart';
import '../widgets/profile/profile_header_card.dart';
import '../widgets/profile/rebase_flow.dart';
import 'language_settings_screen.dart';
import 'policy_webview_screen.dart';

/// 로그인한 플레이어의 상세 프로필 상태(소속 테마 색상, 점령한 총 영토 수)를
/// 검토하고, 테마 색상 수정 및 본진 이전(Rebase), 로그아웃 등 설정을 관리하는 프로필 화면입니다.
///
/// 섹션 위젯과 다이얼로그는 `views/widgets/profile/` 하위 모듈로 분리되어 있으며,
/// 이 클래스는 전체 구성(Composition)만 담당합니다.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final profile = auth.profile;
    final bool isAuth = auth.isAuthenticated && profile != null;

    return Scaffold(
      backgroundColor: GameColors.tacticalBlack,
      appBar: TacticalAppBar(
        titleText: GameStrings.agentProfile,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 상단 카드
              if (isAuth)
                ProfileHeaderCard(
                  auth: auth,
                  game: game,
                  onEditNickname: () =>
                      showNicknameChangeDialog(context, auth: auth, game: game),
                )
              else
                const ProfileLoginPromptCard(),

              // [로그인 플레이어 전용] 게임 설정 섹션
              if (isAuth) ...[
                const SizedBox(height: 24),
                _sectionLabel(GameStrings.operationSettings),
                const SizedBox(height: 12),
                ProfileMenuCard(children: [
                  ProfileMenuItem(
                    icon: Icons.notifications_active,
                    title: GameStrings.pushNotifications,
                    subtitle: GameStrings.pushNotificationsSub,
                    trailing: Switch(
                      value: game.isNotificationEnabled,
                      onChanged: (val) => game.toggleNotifications(),
                      activeThumbColor: GameColors.accentNeon,
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: NotificationSubSettings(game: game),
                  ),
                  const ProfileMenuDivider(),
                  ProfileMenuItem(
                    icon: Icons.my_location_rounded,
                    title: GameStrings.profileRebaseTitle,
                    subtitle: GameStrings.profileRebaseSubtitle,
                    onTap: () => handleRebase(context, auth),
                  ),
                ]),
              ],

              // 시스템 설정 섹션
              const SizedBox(height: 24),
              _sectionLabel(GameStrings.systemSettings),
              const SizedBox(height: 12),
              ProfileMenuCard(children: [
                // 가이드 다시보기
                ProfileMenuItem(
                  icon: Icons.help_outline_rounded,
                  title: GameStrings.tutorialReplayTitle,
                  subtitle: GameStrings.tutorialReplaySubtitle,
                  onTap: () async {
                    await PreferencesService.setSeenOnboarding(false);
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                ),
                const ProfileMenuDivider(),

                // 언어 설정
                ProfileMenuItem(
                  icon: Icons.translate_rounded,
                  title: GameStrings.languageSettings,
                  subtitle: GameStrings.languageSettingsSub,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LanguageSettingsScreen(),
                    ),
                  ),
                ),
                const ProfileMenuDivider(),

                // GPS 정확도 설정
                ProfileMenuItem(
                  icon: Icons.gps_fixed_rounded,
                  title: GameStrings.gpsAccuracySettings,
                  subtitle: GameStrings.gpsAccuracySettingsSub,
                  onTap: () => showGpsAccuracyDialog(context, game: game),
                ),
                const ProfileMenuDivider(),

                // 서비스 이용약관
                ProfileMenuItem(
                  icon: Icons.description_rounded,
                  title: GameStrings.termsOfService,
                  subtitle: GameStrings.termsOfServiceSub,
                  onTap: () {
                    final lang = context.locale.languageCode == 'ko' ? 'ko' : 'en';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PolicyWebviewScreen(
                          title: GameStrings.termsOfService,
                          url: '${GameUrls.termsOfService}?lang=$lang',
                        ),
                      ),
                    );
                  },
                ),
                const ProfileMenuDivider(),

                // 개인정보 처리방침
                ProfileMenuItem(
                  icon: Icons.privacy_tip_rounded,
                  title: GameStrings.privacyPolicy,
                  subtitle: GameStrings.privacyPolicySub,
                  onTap: () {
                    final lang = context.locale.languageCode == 'ko' ? 'ko' : 'en';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PolicyWebviewScreen(
                          title: GameStrings.privacyPolicy,
                          url: '${GameUrls.privacyPolicy}?lang=$lang',
                        ),
                      ),
                    );
                  },
                ),
                const ProfileMenuDivider(),

                // 문의하기
                ProfileMenuItem(
                  icon: Icons.mail_outline_rounded,
                  title: GameStrings.contactSupport,
                  subtitle: GameStrings.contactSupportSub,
                  onTap: () => handleContactSupport(context),
                ),
              ]),

              // 계정 관리 섹션
              if (isAuth) ...[
                const SizedBox(height: 24),
                _sectionLabel(GameStrings.accountManagement),
                const SizedBox(height: 12),
                ProfileMenuCard(children: [
                  ProfileMenuItem(
                    icon: Icons.logout,
                    title: GameStrings.logout,
                    titleColor: GameColors.error,
                    onTap: () async {
                      final confirm = await showLogoutConfirmDialog(context);
                      if (confirm == true) {
                        await auth.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                  ),
                  ProfileMenuItem(
                    icon: Icons.delete_forever,
                    title: GameStrings.deleteAccount,
                    titleColor: GameColors.error,
                    onTap: () async {
                      final confirm = await showDeleteAccountConfirmDialog(context);
                      if (confirm == true) {
                        await auth.deleteAccount();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(GameStrings.deleteAccountSuccess)),
                          );
                          Navigator.of(context).pop();
                        }
                      }
                    },
                  ),
                ]),
              ],

              const SizedBox(height: 40),
              Center(
                child: Text(
                  '${GameStrings.appName} v${VersionConfig.version} (${VersionConfig.buildNumber})',
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

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: GameColors.textMuted,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }
}
