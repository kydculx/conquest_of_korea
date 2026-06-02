import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/error_translator.dart';
import '../../../core/utils/toast_helper.dart';
import '../../../providers/auth_provider.dart';
import '../game_screen.dart';
import '../../widgets/tactical_app_bar.dart';

/// 이메일/패스워드 기반 로그인 및 다양한 외부 소셜 계정 연동 로그인을 제공하는
/// 사용자 인증 및 진입 화면 클래스입니다.
class LoginScreen extends StatefulWidget {
  /// 로그인 화면의 생성자입니다.
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// [LoginScreen]의 로그인 입력 폼 및 소셜 연동 동작을 관리하는 상태 클래스입니다.
class _LoginScreenState extends State<LoginScreen> {
  /// 입력된 이메일 계정 텍스트를 처리하는 컨트롤러입니다.
  final _emailController = TextEditingController();

  /// 입력된 비밀번호 텍스트를 처리하는 컨트롤러입니다.
  final _passwordController = TextEditingController();

  /// 비밀번호 입력란의 가시성 상태(마스킹 여부)를 제어하는 플래그입니다.
  bool _isObscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 로그인 성공 및 화면 복귀 처리를 공통으로 수행하는 라우팅 헬퍼입니다.
  void _handleLoginSuccess() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => const GameScreen()),
      );
    }
  }

  /// 이메일과 비밀번호 정보를 기반으로 Supabase 서버에 사용자 인증 로그인을 요청합니다.
  Future<void> _handleLogin() async {
    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _handleLoginSuccess();
    } catch (e) {
      if (mounted) {
        ToastHelper.show(
          context: context,
          message: ErrorTranslator.translate(e),
          isSuccess: false,
        );
      }
    }
  }

  /// 뒤로 가기(pop)를 시도할 때, 스택 뒤에 아무것도 없는 경우를 방지하여
  /// 안전하게 게임 화면(GameScreen)으로 복귀하는 헬퍼 메서드입니다.
  void _handleBackToGame() {
    _handleLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final Widget mainContent = Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TacticalAppBar(
        showCloseButton: true,
        leadingOnPressed: _handleBackToGame,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: GameColors.cozyDarkGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cozy 3D 파스텔 젤리 깃발 로고 스택
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 네온 블루 글로우 백그라운드
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: GameColors.accentNeon.withValues(
                                alpha: 0.15,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: GameColors.accentNeon.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                          // 귀여운 젤리 클라우드 쉐이프
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0x33FFFFFF), Color(0x0FFFFFFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 부드러운 지도 베이스
                                  Icon(
                                    Icons.map_rounded,
                                    size: 44,
                                    color: GameColors.textSecondary.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                  // 솜사탕 핑크 레드 깃발
                                  Transform.translate(
                                    offset: const Offset(4, -4),
                                    child: const Icon(
                                      Icons.flag_rounded,
                                      size: 44,
                                      color: Color(0xFFE57373),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 영롱한 그라데이션 타이틀
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          GameColors.accentNeon,
                          const Color(0xFFE57373),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        GameStrings.appName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Cozy한 서브 텍스트
                    Text(
                      GameStrings.tacticalMissionStart,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        color: const Color(0xFFFFB74D), // 솜사탕 옐로우 오렌지
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email Field
                    _buildTextField(
                      controller: _emailController,
                      label: GameStrings.emailAddress,
                      icon: Icons.email_rounded,
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    _buildTextField(
                      controller: _passwordController,
                      label: GameStrings.password,
                      icon: Icons.lock_rounded,
                      isObscure: _isObscure,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: GameColors.textMuted,
                        ),
                        onPressed: () =>
                            setState(() => _isObscure = !_isObscure),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Login Button
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return Container(
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                GameColors.accentNeon,
                                const Color(
                                  0xFF81C784,
                                ), // 솜사탕 네온 블루 -> 초록 그라데이션
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: GameColors.accentNeon.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    GameStrings.login,
                                    style: GoogleFonts.fredoka(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // OR Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: GameColors.dividerColor),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            GameStrings.or,
                            style: GoogleFonts.fredoka(
                              color: GameColors.textMuted.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: GameColors.dividerColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Social Login Buttons (Google, Apple)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google
                        _buildSocialCircleButton(
                          onPressed: () async {
                            final authProvider = context.read<AuthProvider>();
                            try {
                              await authProvider.signInWithGoogle();
                              _handleLoginSuccess();
                            } catch (e) {
                              if (context.mounted) {
                                ToastHelper.show(
                                  context: context,
                                  message: ErrorTranslator.translate(e),
                                  isSuccess: false,
                                );
                              }
                            }
                          },
                          color: Colors.white,
                          child: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                            width: 24,
                            height: 24,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.g_mobiledata_rounded,
                              size: 32,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (!kIsWeb && Platform.isIOS) ... [
                          const SizedBox(width: 20),
                          // Apple
                          _buildSocialCircleButton(
                            onPressed: () async {
                              final authProvider = context.read<AuthProvider>();
                              try {
                                await authProvider.signInWithApple();
                                _handleLoginSuccess();
                              } catch (e) {
                                if (context.mounted) {
                                  ToastHelper.show(
                                    context: context,
                                    message: ErrorTranslator.translate(e),
                                    isSuccess: false,
                                  );
                                }
                              }
                            },
                            color: Colors.white,
                            child: const Icon(
                              Icons.apple,
                              color: Colors.black,
                              size: 28,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Register Link
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/terms-agreement'),
                      style: TextButton.styleFrom(
                        foregroundColor: GameColors.textMuted,
                      ),
                      child: Text(
                        GameStrings.createAccount,
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // 시스템 백버튼 가로채기를 통해 뒤로 갈 때 무조건 게임 맵 화면으로 안전 회귀 보장
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _handleBackToGame();
      },
      child: mainContent,
    );
  }

  /// 구글, 애플, 카카오 등의 소셜 로그인 버튼을 공통 원형 디자인으로 구성하는 헬퍼 메서드입니다.
  Widget _buildSocialCircleButton({
    required VoidCallback onPressed,
    required Color color,
    required Widget child,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(27),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  /// 로그인 화면의 입력 필드 디자인을 일관되게 규격화하는 커스텀 텍스트 필드 헬퍼 메서드입니다.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isObscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: GoogleFonts.quicksand(
        color: GameColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.fredoka(
          color: GameColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFFE57373), size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: GameColors.accentNeon.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
      ),
    );
  }
}
