import 'package:flutter/material.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import 'tactical_press_button.dart';
import '../../core/constants/colors.dart';

/// [신규] 상단 우측에 단독 배치되는 3D 보석 젤리 스타일의 프로필 아바타 단추
class ProfileFloatingButton extends StatelessWidget {
  final AuthProvider auth;
  final VoidCallback? onProfileClosed;

  const ProfileFloatingButton({
    required this.auth,
    this.onProfileClosed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAuth = auth.isAuthenticated;

    final gradientColors = isAuth
        ? const [Palette.accentCyan, Palette.cyanDeep] // 활성: 사이버 네온 시안 젤리
        : const [Palette.slateBlue, Palette.graphite]; // 비활성: 다크 메탈릭 실버 젤리

    final shadowColor = isAuth ? Palette.accentCyan : Colors.black;
    final iconColor = isAuth
        ? Colors.white
        : Colors.white.withValues(alpha: 0.55);

    return TacticalPressButton(
      size: 44,
      onTap: () async {
        if (isAuth) {
          final result = await Navigator.pushNamed(context, AppRoutes.profile);
          if (result == true) {
            onProfileClosed?.call();
          }
        } else {
          Navigator.pushNamed(context, AppRoutes.login);
        }
      },
      gradientColors: gradientColors,
      shadowColor: shadowColor,
      shadowBlur: isAuth ? 10 : 4,
      child: Icon(Icons.person_rounded, color: iconColor, size: 20),
    );
  }
}
