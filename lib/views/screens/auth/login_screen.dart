import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/error_translator.dart';
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

  /// 이메일과 비밀번호 정보를 기반으로 Supabase 서버에 사용자 인증 로그인을 요청합니다.
  Future<void> _handleLogin() async {
    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ErrorTranslator.translate(e))));
      }
    }
  }

  /// 뒤로 가기(pop)를 시도할 때, 스택 뒤에 아무것도 없는 경우를 방지하여
  /// 안전하게 게임 화면(GameScreen)으로 복귀하는 헬퍼 메서드입니다.
  void _handleBackToGame() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => const GameScreen()),
      );
    }
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFFFF9C4),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo or Title
                const Icon(Icons.security, size: 80, color: Color(0xFFE57373)),
                const SizedBox(height: 20),
                Text(
                  GameStrings.appName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: GameColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  GameStrings.tacticalMissionStart,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    color: const Color(0xFFE57373),
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 50),

                // Email Field
                _buildTextField(
                  controller: _emailController,
                  label: GameStrings.emailAddress,
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 20),

                // Password Field
                _buildTextField(
                  controller: _passwordController,
                  label: GameStrings.password,
                  icon: Icons.lock_outline,
                  isObscure: _isObscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility_off : Icons.visibility,
                      color: GameColors.textMuted,
                    ),
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                  ),
                ),
                const SizedBox(height: 40),

                // Login Button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GameColors.accentNeon,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
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
                                  letterSpacing: 1.0,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // OR Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: GameColors.dividerColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        GameStrings.or,
                        style: TextStyle(
                          color: GameColors.dividerColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: GameColors.dividerColor)),
                  ],
                ),
                const SizedBox(height: 20),

                // Social Login Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Google
                    _buildSocialCircleButton(
                      onPressed: () async {
                        final authProvider = context.read<AuthProvider>();
                        final navigator = Navigator.of(context);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        try {
                          await authProvider.signInWithGoogle();
                          navigator.pop();
                        } catch (e) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(ErrorTranslator.translate(e)),
                            ),
                          );
                        }
                      },
                      color: GameColors.tacticalWhite,
                      child: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (_, _, _) => Text(
                          'G',
                          style: TextStyle(
                            color: GameColors.tacticalBlack,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Apple
                    if (!kIsWeb && Platform.isIOS)
                      _buildSocialCircleButton(
                        onPressed: () async {
                          final authProvider = context.read<AuthProvider>();
                          final navigator = Navigator.of(context);
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          try {
                            await authProvider.signInWithApple();
                            navigator.pop();
                          } catch (e) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(ErrorTranslator.translate(e)),
                              ),
                            );
                          }
                        },
                        color: GameColors.tacticalWhite,
                        child: Icon(
                          Icons.apple,
                          color: GameColors.tacticalBlack,
                          size: 30,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 30),

                // Register Link
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/terms-agreement'),
                  child: Text(
                    GameStrings.createAccount,
                    style: TextStyle(
                      color: GameColors.textMuted,
                      letterSpacing: 1,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
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
  ///
  /// [onPressed]는 버튼 탭 이벤트이며, [color]는 버튼의 배경 색상, [child]는 내부에 렌더링될 아이콘 위젯입니다.
  Widget _buildSocialCircleButton({
    required VoidCallback onPressed,
    required Color color,
    required Widget child,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: GameColors.tacticalBlack.withValues(alpha: 66 / 255),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  /// 로그인 화면의 입력 필드 디자인을 일관되게 규격화하는 커스텀 텍스트 필드 헬퍼 메서드입니다.
  ///
  /// [controller]는 입력을 수집하며, [label]은 입력 유도 문구이고, [icon]은 접두사 아이콘입니다.
  /// [isObscure]가 참이면 텍스트를 마스킹하고, [suffixIcon]은 입력란 우측에 덧붙여질 버튼 등입니다.
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
      style: GoogleFonts.quicksand(color: GameColors.textPrimary, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.fredoka(
          color: GameColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFFE57373), size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: GameColors.accentNeon.withValues(alpha: 0.5), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.6),
      ),
    );
  }
}
