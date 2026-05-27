import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/hex_service.dart';
import '../../core/utils/error_translator.dart';
import '../widgets/tactical_app_bar.dart';
import '../widgets/tactical_dialog.dart';

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

    final teamColor = TacticalTheme.parseColor(profile.colorHex);

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
                  icon: Icons.palette,
                  title: GameStrings.changeTacticalColor,
                  subtitle: GameStrings.changeTacticalColorSub,
                  onTap: () => _showColorPicker(context, auth),
                ),
                _buildDivider(),
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
                  icon: Icons.security,
                  title: GameStrings.securityPolicy,
                  subtitle: GameStrings.securityPolicySub,
                  onTap: () {},
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
              Center(
                child: Text(
                  'Conquest of Korea v1.0.0',
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
      builder: (context) => TacticalDialog(
        title: GameStrings.deleteAccountConfirmTitle,
        icon: Icons.dangerous_rounded,
        accentColor: GameColors.error,
        content: Text(
          GameStrings.deleteAccountConfirmMessage,
          style: TextStyle(
            color: GameColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
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
              GameStrings.deleteAccount,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// 사용자가 원하는 고유 전술 색상을 RGB 슬라이더 조작을 통해 직접 믹싱하고
  /// 서버 데이터에 영구 보존할 수 있도록 지원하는 컬러 피커 다이얼로그 팝업입니다.
  void _showColorPicker(BuildContext context, AuthProvider auth) {
    Color currentColor = TacticalTheme.parseColor(
      auth.profile?.colorHex ?? '#FFFFFF',
    );
    int r = (currentColor.r * 255.0).round().clamp(0, 255);
    int g = (currentColor.g * 255.0).round().clamp(0, 255);
    int b = (currentColor.b * 255.0).round().clamp(0, 255);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final previewColor = Color.fromARGB(255, r, g, b);
          final hexString =
              '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
                  .toUpperCase();

          return TacticalDialog(
            title: GameStrings.tacticalColorSetupTitle,
            icon: Icons.tune_rounded,
            accentColor: GameColors.accentNeon,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 색상 미리보기 (팔각 텍티컬 프레임 + 웅장한 네온 글로우)
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: ShapeDecoration(
                      color: previewColor.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(color: previewColor, width: 2.5),
                      ),
                      shadows: [
                        BoxShadow(
                          color: previewColor.withValues(alpha: 0.55),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.radar_rounded,
                      color: previewColor,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // RGB 슬라이더 카드형 배경
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: GameColors.tacticalWhite.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: GameColors.dividerColor.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildRGBSlider(
                        'RED',
                        r,
                        GameColors.error,
                        (val) => setState(() => r = val.toInt()),
                      ),
                      const SizedBox(height: 12),
                      _buildRGBSlider(
                        'GREEN',
                        g,
                        GameColors.success,
                        (val) => setState(() => g = val.toInt()),
                      ),
                      const SizedBox(height: 12),
                      _buildRGBSlider(
                        'BLUE',
                        b,
                        GameColors.info,
                        (val) => setState(() => b = val.toInt()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: GameColors.textMuted,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  GameStrings.cancel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await auth.updateProfileColor(hexString);
                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: GameColors.backgroundMedium,
                        content: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: GameColors.success,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              GameStrings.tacticalColorChanged,
                              style: TextStyle(
                                color: GameColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: GameColors.success.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: previewColor,
                  foregroundColor: (r + g + b) > 400
                      ? GameColors.tacticalBlack
                      : GameColors.tacticalWhite,
                  elevation: 8,
                  shadowColor: previewColor.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  GameStrings.apply,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// RGB 개별 색상 채널의 가중치를 미세 제어하기 위한 커스텀 슬라이더 위젯입니다.
  Widget _buildRGBSlider(
    String label,
    int value,
    Color activeColor,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: activeColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              value.toString(),
              style: TextStyle(
                color: GameColors.textPrimary,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '0',
              style: TextStyle(
                color: GameColors.textMuted.withValues(alpha: 0.5),
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3.0,
                  activeTrackColor: activeColor,
                  inactiveTrackColor: GameColors.dividerColor.withValues(
                    alpha: 40 / 255,
                  ),
                  thumbColor: GameColors.tacticalWhite,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6.0,
                  ),
                  overlayColor: activeColor.withValues(alpha: 40 / 255),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14.0,
                  ),
                  valueIndicatorColor: activeColor,
                  valueIndicatorTextStyle: TextStyle(
                    color: GameColors.tacticalBlack,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Slider(
                  value: value.toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  onChanged: onChanged,
                ),
              ),
            ),
            Text(
              '255',
              style: TextStyle(
                color: GameColors.textMuted.withValues(alpha: 0.5),
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 요원의 현 GPS 물리 위치를 기점으로 삼아 메인 본부 기지(HQ) 헥사곤 좌표를 재설정(이전)하도록 통제하는 비동기 메서드입니다.
  Future<void> _handleRebase(BuildContext context, AuthProvider auth) async {
    final loc = context.read<LocationProvider>();
    final currentLocation = loc.currentLocation;

    if (currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(GameStrings.gpsSignalError),
          backgroundColor: GameColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final hex = HexService.latLngToHex(currentLocation);
    final tileId = 'hex_${hex['q']}_${hex['r']}';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => TacticalDialog(
        title: GameStrings.rebaseConfirmTitle,
        icon: Icons.my_location_rounded,
        accentColor: GameColors.accentNeon,
        content: Text(
          GameStrings.rebaseConfirmContent(tileId),
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
        await auth.updateMainBase(tileId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(GameStrings.rebaseSuccessAlert(tileId)),
              backgroundColor: GameColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorTranslator.translate(e)),
              backgroundColor: GameColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
