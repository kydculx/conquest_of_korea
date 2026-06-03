import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';

/// [신규] 상단 우측에 단독 배치되는 3D 보석 젤리 스타일의 프로필 아바타 단추
class ProfileFloatingButton extends StatefulWidget {
  final AuthProvider auth;

  const ProfileFloatingButton({required this.auth, super.key});

  @override
  State<ProfileFloatingButton> createState() => ProfileFloatingButtonState();
}

class ProfileFloatingButtonState extends State<ProfileFloatingButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isAuth = widget.auth.isAuthenticated;

    final gradientColors = isAuth
        ? [const Color(0xFF00E5FF), const Color(0xFF00838F)] // 활성: 사이버 네온 시안 젤리
        : [
            const Color(0xFF37474F),
            const Color(0xFF212121),
          ]; // 비활성: 다크 메탈릭 실버 젤리

    final shadowColor = isAuth ? const Color(0xFF00E5FF) : Colors.black;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Navigator.pushNamed(context, '/profile');
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: isAuth ? 0.35 : 0.12),
                blurRadius: isAuth ? 10 : 4,
                offset: const Offset(0, 2.5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 3D 젤리 반사광 오버레이
              Positioned(
                top: 2,
                left: 5,
                right: 5,
                height: 16,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.45),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Icon(
                  Icons.person_rounded,
                  color: isAuth
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.55),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
