import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/constants/strings.dart';
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
        backgroundColor: GameColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: GameColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GameColors.tacticalGray.withValues(alpha: 0.8),
              GameColors.tacticalBlack,
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
                Icon(
                  Icons.security,
                  size: 80,
                  color: GameColors.accentNeon,
                ),
                const SizedBox(height: 20),
                Text(
                  GameConstants.appName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: GameColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  GameStrings.tacticalMissionStart,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: GameColors.accentNeon,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
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
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameColors.accentNeon,
                        foregroundColor: GameColors.tacticalBlack,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        elevation: 5,
                        shadowColor: GameColors.accentNeon.withValues(alpha: 0.5),
                      ),
                      child: auth.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: GameColors.tacticalBlack,
                              ),
                            )
                          : const Text(
                              GameStrings.login,
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
                  children: [
                    Expanded(child: Divider(color: GameColors.dividerColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(GameStrings.or, style: TextStyle(color: GameColors.dividerColor, fontSize: 12)),
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
                        try {
                          await authProvider.signInWithGoogle();
                          if (mounted) Navigator.of(context).pop();
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorTranslator.translate(e))));
                        }
                      },
                      color: GameColors.tacticalWhite,
                      child: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (_, __, ___) => Text(
                          'G',
                          style: TextStyle(color: GameColors.tacticalBlack, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
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
                      color: GameColors.tacticalWhite,
                      child: Icon(Icons.apple, color: GameColors.tacticalBlack, size: 30),
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
                      color: GameColors.kakaoYellow,
                      child: Icon(Icons.chat_bubble, color: GameColors.kakaoText, size: 22),
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
  }

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
      style: TextStyle(color: GameColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: GameColors.textMuted, fontSize: 12, letterSpacing: 1),
        prefixIcon: Icon(icon, color: GameColors.accentNeon, size: 20),
        suffixIcon: suffixIcon,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: GameColors.dividerColor),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: GameColors.accentNeon),
        ),
        filled: true,
        fillColor: GameColors.tacticalWhite.withValues(alpha: 0.05),
      ),
    );
  }
}
