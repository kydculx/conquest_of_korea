import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/constants/strings.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';

class ProfileScreen extends StatelessWidget {
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_person, size: 64, color: GameColors.dividerColor),
              const SizedBox(height: 20),
              Text(
                GameStrings.loginRequiredPage,
                style: TextStyle(color: GameColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameColors.accentNeon,
                  foregroundColor: GameColors.tacticalBlack,
                ),
                child: Text(GameStrings.goBack),
              ),
            ],
          ),
        ),
      );
    }

    final teamColor = TacticalTheme.parseColor(profile.colorHex);

    return Scaffold(
      backgroundColor: GameColors.tacticalBlack,
      appBar: AppBar(
        backgroundColor: GameColors.transparent,
        elevation: 0,
        title: Text(
          GameStrings.agentProfile,
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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
                  shape: BeveledRectangleBorder(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    side: BorderSide(
                      color: GameColors.accentNeon.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  shadows: [
                    BoxShadow(
                      color: GameColors.accentNeon.withValues(alpha: 0.05),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 전술적 팔각 프로필 컨테이너
                    Container(
                      width: 80,
                      height: 80,
                      decoration: ShapeDecoration(
                        color: teamColor.withValues(alpha: 0.15),
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                      style: TextStyle(
                        color: GameColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        color: GameColors.textSecondary.withValues(
                          alpha: 120 / 255,
                        ),
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () => _showColorPicker(context, auth),
                          customBorder: BeveledRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: _buildStatItem(
                              GameStrings.myTeam,
                              profile.colorHex.toUpperCase(),
                              teamColor,
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: GameColors.dividerColor.withValues(
                            alpha: 80 / 255,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                        ),
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

              const SizedBox(height: 32),
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
                  title: GameStrings.changeTeamColor,
                  subtitle: GameStrings.changeTeamColorSub,
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
                      await auth.signOut();
                      if (context.mounted) Navigator.pop(context);
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

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: GameColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: ShapeDecoration(
        color: GameColors.backgroundMedium.withValues(alpha: 0.6),
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: GameColors.dividerColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(children: children),
    );
  }

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
        style: TextStyle(
          color: activeTitleColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: GameColors.textMuted,
                fontSize: 11,
                letterSpacing: 0.3,
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

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: GameColors.dividerColor.withValues(alpha: 30 / 255),
      indent: 16,
      endIndent: 16,
    );
  }

  Future<bool?> _showLogoutConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameColors.backgroundMedium,
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: GameColors.error.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: GameColors.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '[ SYSTEM // TERMINATE ]',
              style: TextStyle(
                color: GameColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
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
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(4),
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

          return AlertDialog(
            backgroundColor: GameColors.backgroundMedium,
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: GameColors.accentNeon.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            title: Text(
              '[ SYSTEM // TEAM COLOR ]',
              style: TextStyle(
                color: GameColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 색상 미리보기 (팔각 텍티컬 프레임)
                Container(
                  width: 80,
                  height: 80,
                  decoration: ShapeDecoration(
                    color: previewColor.withValues(alpha: 0.15),
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: previewColor, width: 2.5),
                    ),
                    shadows: [
                      BoxShadow(
                        color: previewColor.withValues(alpha: 0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(Icons.person, color: previewColor, size: 40),
                ),
                const SizedBox(height: 12),
                Text(
                  hexString,
                  style: TextStyle(
                    color: previewColor,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 24),

                // RGB 슬라이더
                _buildRGBSlider(
                  'R',
                  r,
                  GameColors.error,
                  (val) => setState(() => r = val.toInt()),
                ),
                _buildRGBSlider(
                  'G',
                  g,
                  GameColors.success,
                  (val) => setState(() => g = val.toInt()),
                ),
                _buildRGBSlider(
                  'B',
                  b,
                  GameColors.info,
                  (val) => setState(() => b = val.toInt()),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  GameStrings.cancel,
                  style: TextStyle(color: GameColors.textMuted),
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
                              GameStrings.teamColorChanged,
                              style: TextStyle(
                                color: GameColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
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
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  GameStrings.apply,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRGBSlider(
    String label,
    int value,
    Color activeColor,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              label,
              style: TextStyle(
                color: activeColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: activeColor,
                inactiveTrackColor: GameColors.dividerColor.withValues(
                  alpha: 50 / 255,
                ),
                thumbColor: GameColors.tacticalWhite,
                overlayColor: activeColor.withValues(alpha: 50 / 255),
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
                label: value.toString(),
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 35,
            child: Text(
              value.toString().padLeft(3, ' '),
              style: TextStyle(
                color: GameColors.textMuted.withValues(alpha: 150 / 255),
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
