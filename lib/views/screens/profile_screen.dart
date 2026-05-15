import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
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
        backgroundColor: GameConstants.tacticalBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person, size: 64, color: Colors.white24),
              const SizedBox(height: 20),
              const Text(
                '로그인이 필요한 페이지입니다.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameConstants.accentNeon,
                  foregroundColor: Colors.black,
                ),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      );
    }

    final teamColor = TacticalTheme.parseColor(profile.colorHex);

    return Scaffold(
      backgroundColor: GameConstants.tacticalBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '대원 프로필',
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
                  color: GameConstants.tacticalGray.withAlpha(150),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: teamColor.withAlpha(100),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: teamColor.withAlpha(30),
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
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.nickname,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        color: Colors.white.withAlpha(120),
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
                              '소속팀',
                              profile.colorHex.toUpperCase(),
                              teamColor,
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white12,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        _buildStatItem(
                          '점령 구역',
                          '${game.myCapturedCount}개',
                          GameConstants.accentNeon,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Text(
                '작전 설정',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),

              // 설정 메뉴 리스트
              _buildMenuCard([
                _buildMenuItem(
                  icon: Icons.palette,
                  title: '팀 색상 변경',
                  subtitle: '작전 구역 표시 색상 변경',
                  onTap: () => _showColorPicker(context, auth),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.notifications_active,
                  title: '푸시 알림',
                  subtitle: '점령 및 공습 알림 받기',
                  trailing: Switch(
                    value: game.isNotificationEnabled,
                    onChanged: (val) => game.toggleNotifications(),
                    activeColor: GameConstants.accentNeon,
                  ),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.security,
                  title: '보안 정책',
                  subtitle: '데이터 보호 및 이용 약관',
                  onTap: () {},
                ),
              ]),

              const SizedBox(height: 24),
              const Text(
                '계정 관리',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),

              _buildMenuCard([
                _buildMenuItem(
                  icon: Icons.logout,
                  title: '로그아웃',
                  titleColor: Colors.redAccent,
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
                    color: Colors.white.withAlpha(50),
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
          style: const TextStyle(color: Colors.white54, fontSize: 12),
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
        color: GameConstants.tacticalGray.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color titleColor = Colors.white,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: titleColor.withAlpha(180)),
      title: Text(
        title,
        style: TextStyle(color: titleColor, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: Colors.white24)
              : null),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.white.withAlpha(10),
      indent: 16,
      endIndent: 16,
    );
  }

  Future<bool?> _showLogoutConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameConstants.tacticalGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('작전 종료', style: TextStyle(color: Colors.white)),
        content: const Text(
          '정말로 로그아웃 하시겠습니까?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.redAccent),
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
    int r = currentColor.red;
    int g = currentColor.green;
    int b = currentColor.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final previewColor = Color.fromARGB(255, r, g, b);
          final hexString =
              '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
                  .toUpperCase();

          return AlertDialog(
            backgroundColor: GameConstants.tacticalGray,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              '팀 색상 커스텀',
              style: TextStyle(
                color: Colors.white,
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
                        color: previewColor.withAlpha(100),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.black,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  hexString,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // RGB 슬라이더
                _buildRGBSlider(
                  'R',
                  r,
                  Colors.redAccent,
                  (val) => setState(() => r = val.toInt()),
                ),
                _buildRGBSlider(
                  'G',
                  g,
                  Colors.greenAccent,
                  (val) => setState(() => g = val.toInt()),
                ),
                _buildRGBSlider(
                  'B',
                  b,
                  Colors.blueAccent,
                  (val) => setState(() => b = val.toInt()),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '취소',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await auth.updateProfileColor(hexString);
                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('팀 색상이 변경되었습니다.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: previewColor,
                  foregroundColor: (r + g + b) > 400
                      ? Colors.black
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '적용하기',
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
                inactiveTrackColor: Colors.white10,
                thumbColor: Colors.white,
                overlayColor: activeColor.withAlpha(50),
                valueIndicatorColor: activeColor,
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.black,
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
              style: const TextStyle(
                color: Colors.white30,
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
