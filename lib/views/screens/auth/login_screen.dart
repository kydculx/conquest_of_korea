import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/utils/error_translator.dart';
import '../../../providers/auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorTranslator.translate(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GameConstants.tacticalGray.withOpacity(0.8),
              GameConstants.tacticalBlack,
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
                const Icon(
                  Icons.security,
                  size: 80,
                  color: GameConstants.accentNeon,
                ),
                const SizedBox(height: 20),
                Text(
                  GameConstants.appName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '전술 미션 시작',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: GameConstants.accentNeon,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 50),

                // Email Field
                _buildTextField(
                  controller: _emailController,
                  label: '이메일 주소',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 20),

                // Password Field
                _buildTextField(
                  controller: _passwordController,
                  label: '비밀번호',
                  icon: Icons.lock_outline,
                  isObscure: _isObscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                  ),
                ),
                const SizedBox(height: 40),

                // Login Button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameConstants.accentNeon,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        elevation: 5,
                        shadowColor: GameConstants.accentNeon.withOpacity(0.5),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              '로그인',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 2,
                              ),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // OR Divider
                Row(
                  children: const [
                    Expanded(child: Divider(color: Colors.white24)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('또는', style: TextStyle(color: Colors.white24, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: Colors.white24)),
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
                        try {
                          await authProvider.signInWithGoogle();
                          if (mounted) Navigator.of(context).pop();
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorTranslator.translate(e))));
                        }
                      },
                      iconUrl: 'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                      color: Colors.white,
                    ),
                    // Apple
                    _buildSocialCircleButton(
                      onPressed: () async {
                        final authProvider = context.read<AuthProvider>();
                        try {
                          await authProvider.signInWithApple();
                          if (mounted) Navigator.of(context).pop();
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorTranslator.translate(e))));
                        }
                      },
                      icon: Icons.apple,
                      color: Colors.white,
                    ),
                    // Kakao
                    _buildSocialCircleButton(
                      onPressed: () async {
                        final authProvider = context.read<AuthProvider>();
                        try {
                          await authProvider.signInWithKakao();
                          if (mounted) Navigator.of(context).pop();
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorTranslator.translate(e))));
                        }
                      },
                      iconUrl: 'https://developers.kakao.com/assets/img/about/logos/kakaotalksharing/kakaolink_40.png',
                      color: const Color(0xFFFEE500),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Sign up Link
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: const Text(
                    '새로운 계정 만들기',
                    style: TextStyle(
                      color: Colors.white54,
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
  }

  Widget _buildSocialCircleButton({
    required VoidCallback onPressed,
    String? iconUrl,
    IconData? icon,
    required Color color,
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
              color: Colors.black26,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: iconUrl != null
            ? Image.network(iconUrl, errorBuilder: (_, __, ___) => const Icon(Icons.login, size: 20))
            : Icon(icon, color: Colors.black, size: 26),
      ),
    );
  }

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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1),
        prefixIcon: Icon(icon, color: GameConstants.accentNeon, size: 20),
        suffixIcon: suffixIcon,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: GameConstants.accentNeon),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
    );
  }
}
