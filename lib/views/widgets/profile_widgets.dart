import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';

/// 비로그인 상태에서 로그인을 유도하는 프로필 상단 카드 위젯
class ProfileLoginPromptCard extends StatelessWidget {
  final VoidCallback? onLoginTap;

  const ProfileLoginPromptCard({super.key, this.onLoginTap});

  @override
  Widget build(BuildContext context) {
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
              color: GameColors.textMuted.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: GameColors.textMuted.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: GameColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            GameStrings.loginRequiredOperation,
            style: GoogleFonts.fredoka(
              color: GameColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onLoginTap ?? () => Navigator.pushNamed(context, AppRoutes.login),
              style: ElevatedButton.styleFrom(
                backgroundColor: GameColors.accentNeon,
                foregroundColor: GameColors.tacticalBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                GameStrings.login,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 프로필 상단 카드에 표기될 핵심 통계 수치 항목 위젯
class ProfileStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const ProfileStatItem({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.quicksand(
            color: GameColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
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
}

/// 부드러운 둥근 모서리 설정 메뉴 리스트 컨테이너 위젯
class ProfileMenuCard extends StatelessWidget {
  final List<Widget> children;

  const ProfileMenuCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
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
}

/// 개별 설정 메뉴 아이템 타일 위젯
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              subtitle!,
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
}

/// 카드 내 메뉴 항목 구분선 위젯
class ProfileMenuDivider extends StatelessWidget {
  const ProfileMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: GameColors.dividerColor.withValues(alpha: 30 / 255),
      indent: 16,
      endIndent: 16,
    );
  }
}

/// 개별 서브 알림 항목 On/Off 토글 슬림형 서브 메뉴 아이템 위젯
class ProfileSubMenuItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ProfileSubMenuItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // Tactical Link line
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
}

/// 개별 서브 알림 사이를 구분하는 세밀한 라인
class ProfileSubDivider extends StatelessWidget {
  const ProfileSubDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 6,
      color: GameColors.dividerColor.withValues(alpha: 15 / 255),
      indent: 14,
    );
  }
}
