import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/toast_helper.dart';
import '../../core/utils/error_translator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/hex_service.dart';
import '../widgets/tactical_app_bar.dart';
import '../widgets/tactical_dialog.dart';
import '../widgets/profile_widgets.dart';
import 'language_settings_screen.dart';
import 'policy_webview_screen.dart';
import 'game_guide_screen.dart';

/// 로그인한 플레이어의 상세 프로필 상태(소속 테마 색상, 점령한 총 영토 수)를
/// 검토하고, 테마 색상 수정 및 본진 이전(Rebase), 로그아웃 등 설정을 관리하는 프로필 화면 클래스입니다.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _buildProfileHeader(BuildContext context, AuthProvider auth, GameProvider game) {
    final profile = auth.profile!;
    final user = auth.user;
    final teamColor = GameColors.myTileColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: ShapeDecoration(
        color: GameColors.backgroundMedium.withValues(alpha: 0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: GameColors.accentNeon.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: ShapeDecoration(
              color: teamColor.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: teamColor, width: 2.0),
              ),
            ),
            child: Center(
              child: Icon(Icons.person, size: 40, color: teamColor),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.nickname,
            style: GoogleFonts.fredoka(
              color: GameColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: GoogleFonts.quicksand(
              color: GameColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ProfileStatItem(
                label: GameStrings.capturedTiles,
                value: '${game.myCapturedCount}${GameStrings.countUnit}',
                color: GameColors.accentNeon,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSubSettings(BuildContext context, GameProvider game) {
    if (!game.isNotificationEnabled) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 12, bottom: 8, top: 4),
      color: GameColors.backgroundMedium.withValues(alpha: 0.2),
      child: Column(
        children: [
          ProfileSubMenuItem(
            title: GameStrings.notifTerritoryAttackTitle,
            subtitle: GameStrings.notifTerritoryAttackSub,
            value: game.isNotifTerritoryAttack,
            onChanged: (val) => game.toggleNotifTerritoryAttack(),
          ),
          const ProfileSubDivider(),
          ProfileSubMenuItem(
            title: GameStrings.notifSatelliteCompleteTitle,
            subtitle: GameStrings.notifSatelliteCompleteSub,
            value: game.isNotifSatelliteComplete,
            onChanged: (val) => game.toggleNotifSatelliteComplete(),
          ),
          const ProfileSubDivider(),
          ProfileSubMenuItem(
            title: GameStrings.notifSystemNoticeTitle,
            subtitle: GameStrings.notifSystemNoticeSub,
            value: game.isNotifSystemNotice,
            onChanged: (val) => game.toggleNotifSystemNotice(),
          ),
        ],
      ),
    );
  }

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
                _buildProfileHeader(context, auth, game)
              else
                const ProfileLoginPromptCard(),

              const SizedBox(height: 24),
              Text(
                GameStrings.operationSettings,
                style: TextStyle(
                  color: GameColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),

              // 설정 메뉴 리스트
              ProfileMenuCard(children: [
                // 게임 설명서
                ProfileMenuItem(
                  icon: Icons.menu_book_rounded,
                  title: GameStrings.gameGuide,
                  subtitle: GameStrings.gameGuideSub,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GameGuideScreen(),
                    ),
                  ),
                ),
                const ProfileMenuDivider(),



                // [로그인 플레이어 전용] 알림 설정
                if (isAuth) ...[
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
                    child: _buildNotificationSubSettings(context, game),
                  ),
                  const ProfileMenuDivider(),
                  ProfileMenuItem(
                    icon: Icons.my_location_rounded,
                    title: GameStrings.profileRebaseTitle,
                    subtitle: GameStrings.profileRebaseSubtitle,
                    onTap: () => _handleRebase(context, auth),
                  ),
                  const ProfileMenuDivider(),
                ],

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

                // 서비스 이용약관
                ProfileMenuItem(
                  icon: Icons.description_rounded,
                  title: GameStrings.termsOfService,
                  subtitle: GameStrings.termsOfServiceSub,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PolicyWebviewScreen(
                        title: GameStrings.termsOfService,
                        url: GameUrls.termsOfService,
                      ),
                    ),
                  ),
                ),
                const ProfileMenuDivider(),

                // 개인정보 처리방침
                ProfileMenuItem(
                  icon: Icons.privacy_tip_rounded,
                  title: GameStrings.privacyPolicy,
                  subtitle: GameStrings.privacyPolicySub,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PolicyWebviewScreen(
                        title: GameStrings.privacyPolicy,
                        url: GameUrls.privacyPolicy,
                      ),
                    ),
                  ),
                ),
              ]),

              // 계정 관리 섹션
              if (isAuth) ...[
                const SizedBox(height: 24),
                Text(
                  GameStrings.accountManagement,
                  style: TextStyle(
                    color: GameColors.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                ProfileMenuCard(children: [
                  ProfileMenuItem(
                    icon: Icons.logout,
                    title: GameStrings.logout,
                    titleColor: GameColors.error,
                    onTap: () async {
                      final confirm = await _showLogoutConfirm(context);
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
                      final confirm = await _showDeleteAccountConfirm(context);
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
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final versionText = snapshot.hasData
                      ? 'v${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                      : 'v1.0.0';
                  return Center(
                    child: Text(
                      '${GameStrings.appName} $versionText',
                      style: TextStyle(
                        color: GameColors.textMuted.withValues(alpha: 100 / 255),
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 다이얼로그 및 로직 메서드 ---

  Future<bool?> _showLogoutConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => TacticalDialog(
        title: GameStrings.logoutConfirmTitle,
        icon: Icons.warning_amber_rounded,
        accentColor: GameColors.error,
        content: Text(
          GameStrings.logoutConfirmMessage,
          style: TextStyle(color: GameColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: GameColors.textMuted),
            child: Text(GameStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: GameColors.error,
              foregroundColor: GameColors.tacticalWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              GameStrings.logout,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteAccountConfirm(BuildContext context) {
    bool isAgreed = false;
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return TacticalDialog(
              title: GameStrings.deleteAccountConfirmTitle,
              icon: Icons.dangerous_rounded,
              accentColor: GameColors.error,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    GameStrings.deleteAccountConfirmMessage,
                    style: TextStyle(
                      color: GameColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => setState(() => isAgreed = !isAgreed),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isAgreed,
                            onChanged: (v) => setState(() => isAgreed = v ?? false),
                            activeColor: GameColors.error,
                            checkColor: GameColors.tacticalWhite,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            side: BorderSide(color: GameColors.textMuted, width: 1.5),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              GameStrings.deleteAccountCheckboxLabel,
                              style: TextStyle(
                                color: GameColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(foregroundColor: GameColors.textMuted),
                  child: Text(GameStrings.cancel),
                ),
                ElevatedButton(
                  onPressed: isAgreed ? () => Navigator.pop(context, true) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameColors.error,
                    foregroundColor: GameColors.tacticalWhite,
                    disabledBackgroundColor: GameColors.textMuted.withValues(alpha: 0.15),
                    disabledForegroundColor: GameColors.textMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    GameStrings.deleteAccount,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleRebase(BuildContext context, AuthProvider auth) async {
    final loc = context.read<LocationProvider>();
    final game = context.read<GameProvider>();
    final currentLocation = loc.currentLocation;

    if (currentLocation == null) {
      ToastHelper.show(context: context, message: GameStrings.gpsSignalError, isSuccess: false);
      return;
    }

    final hex = HexService.latLngToHex(currentLocation);
    final tileId = HexService.tileId(hex['q']!, hex['r']!);

    final mainBaseId = auth.profile?.mainBaseTileId;
    if (mainBaseId == tileId) {
      await _showErrorDialog(context, GameStrings.rebaseSameLocationMessage);
      return;
    }

    final distance = game.getTileDistance(tileId);
    final requiredGold = distance * 10.0;

    if (requiredGold > game.currentGold) {
      await _showErrorDialog(
        context,
        GameStrings.rebaseGoldShortageMessage(
          requiredGold.toInt().toString(),
          game.currentGold.toInt().toString(),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => TacticalDialog(
        title: GameStrings.rebaseConfirmTitle,
        icon: Icons.my_location_rounded,
        accentColor: GameColors.accentNeon,
        content: Text(
          GameStrings.rebaseConfirmContent(
            tileId: tileId,
            cost: requiredGold.toInt().toString(),
            currentGold: game.currentGold.toInt().toString(),
          ),
          style: TextStyle(color: GameColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: GameColors.textMuted),
            child: Text(GameStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: GameColors.accentNeon,
              foregroundColor: GameColors.tacticalBlack,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(GameStrings.rebaseButton, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final success = await game.rebaseMainBase(tileId, requiredGold);
        if (success && context.mounted) {
          ToastHelper.show(context: context, message: GameStrings.rebaseSuccessAlert(tileId), isSuccess: true);
        } else if (context.mounted) {
          ToastHelper.show(context: context, message: GameStrings.errorUnknown, isSuccess: false);
        }
      } catch (e) {
        if (context.mounted) {
          ToastHelper.show(context: context, message: ErrorTranslator.translate(e), isSuccess: false);
        }
      }
    }
  }

  Future<void> _showErrorDialog(BuildContext context, String message) {
    return showDialog(
      context: context,
      builder: (context) => TacticalDialog(
        title: '[ 오류 ]',
        icon: Icons.error_outline_rounded,
        accentColor: GameColors.error,
        content: Text(message, style: TextStyle(color: GameColors.textSecondary, fontSize: 13)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: GameColors.error,
              foregroundColor: GameColors.tacticalWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(GameStrings.confirm, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
