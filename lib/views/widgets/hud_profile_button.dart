import 'package:flutter/material.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import 'tactical_press_button.dart';

/// [신규] 상단 우측에 단독 배치되는 3D 보석 젤리 스타일의 프로필 아바타 단추
class ProfileFloatingButton extends StatelessWidget {
  final AuthProvider auth;

  const ProfileFloatingButton({required this.auth, super.key});

  @override
  Widget build(BuildContext context) {
    final bool isAuth = auth.isAuthenticated;

    final gradientColors = isAuth
        ? const [Color(0xFF00E5FF), Color(0xFF00838F)] // 활성: 사이버 네온 시안 젤리
        : const [Color(0xFF37474F), Color(0xFF212121)]; // 비활성: 다크 메탈릭 실버 젤리

    final shadowColor = isAuth ? const Color(0xFF00E5FF) : Colors.black;
    final iconColor = isAuth
        ? Colors.white
        : Colors.white.withValues(alpha: 0.55);

    return TacticalPressButton(
      size: 44,
      onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
      gradientColors: gradientColors,
      shadowColor: shadowColor,
      shadowBlur: isAuth ? 10 : 4,
      child: Icon(Icons.person_rounded, color: iconColor, size: 20),
    );
  }
}
