import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/toast_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/hex_service.dart';
import '../../core/utils/error_translator.dart';
import '../widgets/tactical_app_bar.dart';
import '../widgets/tactical_dialog.dart';
import 'language_settings_screen.dart';
import 'security_policy_screen.dart';

/// 로그인한 요원의 상세 프로필 상태(소속 전술 색상, 점령한 총 영토 수)를
/// 검토하고, 전술 색상 수정 및 본진 이전(Rebase), 로그아웃 등 작전 설정을 관리하는 프로필 화면 클래스입니다.
class ProfileScreen extends StatelessWidget {
  /// 프로필 화면의 생성자입니다.
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final profile = auth.profile;
    final user = auth.user;

    if (!auth.isAuthenticated || profile == null) {
      return Scaffold(
        backgroundColor: GameColors.tacticalBlack,
        body: const SizedBox.shrink(),
      );
    }

    final teamColor = GameColors.myTileColor;

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
              Container(
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
                    // 전술적 둥근 프로필 컨테이너
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
                        _buildStatItem(
                          GameStrings.capturedTiles,
                          '${game.myCapturedCount}${GameStrings.countUnit}',
                          GameColors.accentNeon,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

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
              _buildMenuCard([
                _buildMenuItem(
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
                  child: game.isNotificationEnabled
                      ? Container(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 12,
                            bottom: 8,
                            top: 4,
                          ),
                          color: GameColors.backgroundMedium.withValues(
                            alpha: 0.2,
                          ),
                          child: Column(
                            children: [
                              _buildSubMenuItem(
                                title: GameStrings.notifTerritoryAttackTitle,
                                subtitle: GameStrings.notifTerritoryAttackSub,
                                value: game.isNotifTerritoryAttack,
                                onChanged: (val) =>
                                    game.toggleNotifTerritoryAttack(),
                              ),
                              _buildSubDivider(),
                              _buildSubMenuItem(
                                title: GameStrings.notifSatelliteCompleteTitle,
                                subtitle: GameStrings.notifSatelliteCompleteSub,
                                value: game.isNotifSatelliteComplete,
                                onChanged: (val) =>
                                    game.toggleNotifSatelliteComplete(),
                              ),
                              _buildSubDivider(),
                              _buildSubMenuItem(
                                title: GameStrings.notifSystemNoticeTitle,
                                subtitle: GameStrings.notifSystemNoticeSub,
                                value: game.isNotifSystemNotice,
                                onChanged: (val) =>
                                    game.toggleNotifSystemNotice(),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.my_location_rounded,
                  title: GameStrings.profileRebaseTitle,
                  subtitle: GameStrings.profileRebaseSubtitle,
                  onTap: () => _handleRebase(context, auth),
                ),
                _buildDivider(),
                _buildMenuItem(
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
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.security,
                  title: GameStrings.securityPolicy,
                  subtitle: GameStrings.securityPolicySub,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SecurityPolicyScreen(),
                    ),
                  ),
                ),
              ]),

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

              _buildMenuCard([
                _buildMenuItem(
                  icon: Icons.logout,
                  title: GameStrings.logout,
                  titleColor: GameColors.error,
                  onTap: () async {
                    final confirm = await _showLogoutConfirm(context);
                    if (confirm == true) {
                      if (context.mounted) Navigator.pop(context);
                      await auth.signOut();
                    }
                  },
                ),
                _buildMenuItem(
                  icon: Icons.delete_forever,
                  title: GameStrings.deleteAccount,
                  titleColor: GameColors.error,
                  onTap: () async {
                    final confirm = await _showDeleteAccountConfirm(context);
                    if (confirm == true) {
                      if (context.mounted) Navigator.pop(context);
                      await auth.deleteAccount();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(GameStrings.deleteAccountSuccess),
                          ),
                        );
                      }
                    }
                  },
                ),
              ]),

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

  /// 프로필 상단 카드에 표기될 핵심 통계 수치 항목을 빌드하는 도우미 위젯입니다.
  ///
  /// [label]은 항목명, [value]는 기록값, [color]는 강조 텍스트 색상입니다.
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.quicksand(color: GameColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.fredoka(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 부드러운 둥근 모서리(Rounded)의 외부 테두리를 적용하여 설정 메뉴 항목들의 컨테이너를 이루는 위젯입니다.
  Widget _buildMenuCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  /// 개별 설정 속성에 알맞은 타이틀, 부가 설명 및 우측 컨트롤러를 나타내는 메뉴 아이템 타일입니다.
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    final activeTitleColor = titleColor ?? GameColors.textPrimary;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: activeTitleColor.withValues(alpha: 180 / 255)),
      title: Text(
        title,
        style: GoogleFonts.fredoka(
          color: activeTitleColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.2,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.quicksand(
                color: GameColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.1,
              ),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: GameColors.dividerColor)
              : null),
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

  /// 개별 서브 알림 항목의 On/Off를 미려하게 토글할 수 있는 슬림형 전술 서브 메뉴 아이템 위젯
  Widget _buildSubMenuItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // 들여쓰기 가이드라인 라인 연출 (Tactical Link line)
          Container(
            width: 2,
            height: 32,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: GameColors.accentNeon.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: GameColors.textPrimary.withValues(alpha: 0.95),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(color: GameColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: GameColors.accentNeon,
              activeTrackColor: GameColors.accentNeon.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  /// 개별 서브 알림 사이를 구분해주는 세밀한 라인 연출
  Widget _buildSubDivider() {
    return Divider(
      height: 6,
      color: GameColors.dividerColor.withValues(alpha: 15 / 255),
      indent: 14,
    );
  }

  /// 로그아웃 처리를 하기 전 사용자에게 확인 의사를 재차 검증하는 경고 팝업 창을 띄웁니다.
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

  /// 계정 영구 삭제 처리를 하기 전 사용자에게 확인 의사를 재차 검증하는 경고 팝업 창을 띄웁니다.
  Future<bool?> _showDeleteAccountConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        bool isChecked = false;
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
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isChecked = !isChecked;
                      });
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: isChecked,
                            onChanged: (val) {
                              setState(() {
                                isChecked = val ?? false;
                              });
                            },
                            activeColor: GameColors.error,
                            checkColor: GameColors.tacticalWhite,
                            side: BorderSide(
                              color: GameColors.textMuted.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            GameStrings.deleteAccountCheckboxLabel,
                            style: TextStyle(
                              color: isChecked
                                  ? GameColors.textPrimary
                                  : GameColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
                  onPressed: isChecked ? () => Navigator.pop(context, true) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameColors.error,
                    foregroundColor: GameColors.tacticalWhite,
                    disabledBackgroundColor: GameColors.error.withValues(alpha: 0.25),
                    disabledForegroundColor: GameColors.tacticalWhite.withValues(alpha: 0.35),
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



  /// 요원의 현 GPS 물리 위치를 기점으로 삼아 메인 본부 기지(HQ) 헥사곤 좌표를 재설정(이전)하도록 통제하는 비동기 메서드입니다.
  Future<void> _handleRebase(BuildContext context, AuthProvider auth) async {
    final loc = context.read<LocationProvider>();
    final game = context.read<GameProvider>();
    final currentLocation = loc.currentLocation;

    if (currentLocation == null) {
      ToastHelper.show(
        context: context,
        message: GameStrings.gpsSignalError,
        isSuccess: false,
      );
      return;
    }

    final hex = HexService.latLngToHex(currentLocation);
    final tileId = 'hex_${hex['q']}_${hex['r']}';

    // 1. 동일 위치 검증 및 에러 팝업
    final mainBaseId = auth.profile?.mainBaseTileId;
    if (mainBaseId == tileId) {
      await showDialog(
        context: context,
        builder: (context) => TacticalDialog(
          title: '[ 본진 재설정 오류 ]',
          icon: Icons.error_outline_rounded,
          accentColor: GameColors.error,
          content: Text(
            GameStrings.rebaseSameLocationMessage,
            style: TextStyle(color: GameColors.textSecondary, fontSize: 13),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: GameColors.error,
                foregroundColor: GameColors.tacticalWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                GameStrings.confirm,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // 2. 소요 재화 산정 및 검증
    final distance = game.getTileDistance(tileId);
    final requiredGold = distance * 10.0;

    if (requiredGold > game.currentGold) {
      await showDialog(
        context: context,
        builder: (context) => TacticalDialog(
          title: '[ 재화 부족 ]',
          icon: Icons.warning_amber_rounded,
          accentColor: GameColors.error,
          content: Text(
            GameStrings.rebaseGoldShortageMessage(
              requiredGold.toInt().toString(),
              game.currentGold.toInt().toString(),
            ),
            style: TextStyle(color: GameColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: GameColors.error,
                foregroundColor: GameColors.tacticalWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                GameStrings.confirm,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // 3. 재설정 동의 다이얼로그 호출
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              GameStrings.rebaseButton,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final success = await game.rebaseMainBase(tileId, requiredGold);
        if (success && context.mounted) {
          ToastHelper.show(
            context: context,
            message: GameStrings.rebaseSuccessAlert(tileId),
            isSuccess: true,
          );
        } else if (context.mounted) {
          ToastHelper.show(
            context: context,
            message: GameStrings.errorUnknown,
            isSuccess: false,
          );
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
  }
}
