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
                child: const Text(GameStrings.goBack),
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
        title: const Text(
          GameStrings.agentProfile,
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
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
                decoration: BoxDecoration(
                  color: GameColors.tacticalGray.withValues(alpha: 150 / 255),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: GameColors.tacticalWhite.withValues(alpha: 20 / 255),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameColors.tacticalBlack.withValues(alpha: 50 / 255),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: teamColor,
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: GameColors.tacticalBlack,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.nickname,
                      style: TextStyle(
                        color: GameColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        color: GameColors.textSecondary.withValues(alpha: 120 / 255),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () => _showColorPicker(context, auth),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: _buildStatItem(
                              GameStrings.myTeam,
                              profile.colorHex.toUpperCase(),
                              GameColors.accentNeon,
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: GameColors.dividerColor,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
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
      decoration: BoxDecoration(
        color: GameColors.tacticalGray.withValues(alpha: 100 / 255),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GameColors.dividerColor.withValues(alpha: 50 / 255)),
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
        style: TextStyle(color: activeTitleColor, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: GameColors.textMuted, fontSize: 12),
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
      color: GameColors.dividerColor.withValues(alpha: 50 / 255),
      indent: 16,
      endIndent: 16,
    );
  }

  Future<bool?> _showLogoutConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameColors.tacticalGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          GameStrings.terminateOperation,
          style: TextStyle(color: GameColors.textPrimary),
        ),
        content: Text(
          GameStrings.logoutConfirmMessage,
          style: TextStyle(color: GameColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(GameStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              GameStrings.logout,
              style: TextStyle(color: GameColors.error),
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
            backgroundColor: GameColors.tacticalGray,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              GameStrings.customTeamColor,
              style: TextStyle(
                color: GameColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 색상 미리보기
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: previewColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: previewColor.withValues(alpha: 100 / 255),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: GameColors.dividerColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: GameColors.tacticalBlack,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  hexString,
                  style: TextStyle(
                    color: GameColors.textSecondary,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
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
                      const SnackBar(
                        content: Text(GameStrings.teamColorChanged),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: previewColor,
                  foregroundColor: (r + g + b) > 400
                      ? GameColors.tacticalBlack
                      : GameColors.tacticalWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  GameStrings.apply,
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                inactiveTrackColor: GameColors.dividerColor.withValues(alpha: 50 / 255),
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
