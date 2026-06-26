import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/game_config.dart';
import '../../core/utils/toast_helper.dart';
import '../../core/utils/error_translator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/hex_service.dart';
import '../../services/preferences_service.dart';
import '../widgets/tactical_app_bar.dart';
import '../widgets/tactical_dialog.dart';
import '../widgets/profile_widgets.dart';
import 'language_settings_screen.dart';
import 'policy_webview_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.nickname,
                style: GoogleFonts.fredoka(
                  color: GameColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showChangeNicknameDialog(context, auth, game),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: GameColors.accentNeon,
                  ),
                ),
              ),
            ],
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

              // [로그인 플레이어 전용] 게임 설정 섹션
              if (isAuth) ...[
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
                    child: _buildNotificationSubSettings(context, game),
                  ),
                  const ProfileMenuDivider(),
                  ProfileMenuItem(
                    icon: Icons.my_location_rounded,
                    title: GameStrings.profileRebaseTitle,
                    subtitle: GameStrings.profileRebaseSubtitle,
                    onTap: () => _handleRebase(context, auth),
                  ),
                ]),
              ],

              // 시스템 설정 섹션
              const SizedBox(height: 24),
              Text(
                GameStrings.systemSettings,
                style: TextStyle(
                  color: GameColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
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
                  onTap: () => _handleContactSupport(context),
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
        title: GameStrings.errorTitle,
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

  Future<void> _handleContactSupport(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: GameUrls.supportEmail,
      query: _encodeQueryParameters(<String, String>{
        'subject': GameStrings.supportEmailSubject,
        'body': GameStrings.supportEmailBody,
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (context.mounted) {
          ToastHelper.show(
            context: context,
            message: GameStrings.cannotOpenMailApp(GameUrls.supportEmail),
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.show(
          context: context,
          message: ErrorTranslator.translate(e),
          isSuccess: false,
        );
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _showChangeNicknameDialog(
      BuildContext context, AuthProvider auth, GameProvider game) {
    final nicknameController = TextEditingController(text: auth.profile?.nickname ?? '');
    final formKey = GlobalKey<FormState>();
    
    bool isNicknameChecked = false;
    bool isNicknameAvailable = false;
    bool isChecking = false;
    bool isSaving = false;
    
    final currentNickname = auth.profile?.nickname ?? '';
    const double cost = GameConfig.nicknameChangeCost;
    final bool hasEnoughGold = game.currentGold >= cost;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> checkNickname() async {
              final newNickname = nicknameController.text.trim();
              if (newNickname.isEmpty) {
                ToastHelper.show(context: context, message: GameStrings.enterNickname, isSuccess: false);
                return;
              }
              if (newNickname.contains(' ')) {
                ToastHelper.show(context: context, message: GameStrings.errorNicknameContainsSpace, isSuccess: false);
                return;
              }
              if (newNickname == currentNickname) {
                ToastHelper.show(context: context, message: GameStrings.nicknameChangeSame, isSuccess: false);
                return;
              }
              setState(() => isChecking = true);
              try {
                final available = await auth.isNicknameAvailable(newNickname);
                setState(() {
                  isNicknameAvailable = available;
                  isNicknameChecked = true;
                });
                if (context.mounted) {
                  ToastHelper.show(
                    context: context,
                    message: available ? GameStrings.nicknameAvailable : GameStrings.errorNicknameExists,
                    isSuccess: available,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ToastHelper.show(context: context, message: ErrorTranslator.translate(e), isSuccess: false);
                }
              } finally {
                setState(() => isChecking = false);
              }
            }

            Future<void> handleSave() async {
              final newNickname = nicknameController.text.trim();
              if (newNickname.contains(' ')) {
                ToastHelper.show(context: context, message: GameStrings.errorNicknameContainsSpace, isSuccess: false);
                return;
              }
              if (newNickname == currentNickname) {
                Navigator.pop(context);
                return;
              }
              if (!isNicknameChecked || !isNicknameAvailable) {
                ToastHelper.show(context: context, message: GameStrings.errorNicknameCheckRequired, isSuccess: false);
                return;
              }
              if (!hasEnoughGold) {
                ToastHelper.show(context: context, message: GameStrings.nicknameChangeGoldShortage, isSuccess: false);
                return;
              }
              setState(() => isSaving = true);
              try {
                await auth.changeNickname(
                  newNickname: newNickname,
                  currentGold: game.currentGold,
                  cost: cost,
                );
                await game.syncGoldWithServer();
                if (context.mounted) {
                  ToastHelper.show(context: context, message: GameStrings.nicknameChangeSuccess, isSuccess: true);
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ToastHelper.show(context: context, message: ErrorTranslator.translate(e), isSuccess: false);
                }
              } finally {
                setState(() => isSaving = false);
              }
            }

            nicknameController.addListener(() {
              final val = nicknameController.text.trim();
              setState(() {
                if (isNicknameChecked && val != currentNickname) {
                  isNicknameChecked = false;
                  isNicknameAvailable = false;
                }
              });
            });

            Color getBorderColor() {
              if (isNicknameChecked) {
                return isNicknameAvailable ? GameColors.success : GameColors.error;
              }
              return GameColors.borderNeon;
            }

            final activeBorderColor = getBorderColor();

            return TacticalDialog(
              title: GameStrings.changeNickname,
              icon: Icons.edit_rounded,
              accentColor: GameColors.accentNeon,
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      GameStrings.changeNicknameSub,
                      style: TextStyle(color: GameColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nicknameController,
                      style: GoogleFonts.quicksand(color: GameColors.textPrimary, fontWeight: FontWeight.bold),
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      decoration: InputDecoration(
                        hintText: GameStrings.enterNickname,
                        hintStyle: TextStyle(color: GameColors.textMuted),
                        filled: true,
                        fillColor: GameColors.backgroundMedium.withValues(alpha: 0.5),
                        contentPadding: const EdgeInsets.only(left: 16, right: 8, top: 14, bottom: 14),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                        suffixIcon: isChecking
                            ? const Padding(
                                padding: EdgeInsets.only(right: 16),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF00E5FF),
                                  ),
                                ),
                              )
                            : isNicknameChecked
                                ? Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: Icon(
                                      isNicknameAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                      color: isNicknameAvailable ? GameColors.success : GameColors.error,
                                      size: 20,
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: TextButton(
                                      onPressed: nicknameController.text.trim().isEmpty ||
                                              nicknameController.text.trim() == currentNickname
                                          ? null
                                          : checkNickname,
                                      style: TextButton.styleFrom(
                                        foregroundColor: GameColors.accentNeon,
                                        disabledForegroundColor: GameColors.textMuted.withValues(alpha: 0.4),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      child: Text(
                                        GameStrings.checkDuplicate,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: activeBorderColor, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: activeBorderColor, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isNicknameChecked ? activeBorderColor : GameColors.accentNeon,
                            width: 2.0,
                          ),
                        ),
                      ),
                      maxLength: 10,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          GameStrings.nicknameChangeCost(
                            cost.toInt().toString(),
                            game.currentGold.toInt().toString(),
                          ),
                          style: TextStyle(
                            color: hasEnoughGold ? GameColors.textMuted : GameColors.error,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: GameColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(GameStrings.cancel),
                ),
                ElevatedButton(
                  onPressed: (isNicknameChecked && isNicknameAvailable && hasEnoughGold && !isSaving) ? handleSave : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameColors.accentNeon,
                    foregroundColor: GameColors.tacticalBlack,
                    disabledBackgroundColor: GameColors.accentNeon.withValues(alpha: 0.15),
                    disabledForegroundColor: GameColors.textMuted.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 0,
                  ),
                  child: isSaving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: GameColors.tacticalBlack,
                          ),
                        )
                      : Text(GameStrings.confirm, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
