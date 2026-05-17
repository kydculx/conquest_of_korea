import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/error_translator.dart';
import '../../../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();

  Color _selectedColor = GameColors.accentNeon;
  bool _isObscure = true;
  bool _isNicknameChecked = false;
  bool _isNicknameAvailable = false;
  bool _isCheckingNickname = false;

  bool _isEmailChecked = false;
  bool _isEmailValid = false;
  bool _isCheckingEmail = false;

  @override
  void initState() {
    super.initState();
    _generateRandomColor();
    _nicknameController.addListener(() {
      if (_isNicknameChecked) {
        setState(() {
          _isNicknameChecked = false;
        });
      }
    });
    _emailController.addListener(() {
      if (_isEmailChecked) {
        setState(() {
          _isEmailChecked = false;
        });
      }
    });
  }

  void _generateRandomColor() {
    final random = Random();
    // 세련된 네온 계열 색상 추출을 위해 HSL 사용
    final double h = random.nextDouble() * 360;
    final double s = 0.8 + (random.nextDouble() * 0.2); // 80-100% 채도
    final double l = 0.5 + (random.nextDouble() * 0.2); // 50-70% 밝기

    setState(() {
      _selectedColor = HSLColor.fromAHSL(1.0, h, s, l).toColor();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _checkEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(GameStrings.enterEmail)));
      return;
    }

    setState(() => _isCheckingEmail = true);

    // 1. 이메일 정규식 검사
    final bool isValidFormat = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);

    if (!isValidFormat) {
      setState(() {
        _isEmailValid = false;
        _isEmailChecked = true;
        _isCheckingEmail = false;
      });
      return;
    }

    // 2. DB 중복 체크 (RPC 호출)
    try {
      final authProvider = context.read<AuthProvider>();
      final isAvailable = await authProvider.isEmailAvailable(email);

      if (mounted) {
        setState(() {
          _isEmailValid = isAvailable;
          _isEmailChecked = true;
        });
      }
    } catch (e) {
      // RPC 함수가 없을 경우 형식 검사 결과만 적용
      if (mounted) {
        setState(() {
          _isEmailValid = isValidFormat;
          _isEmailChecked = true;
        });
      }
    } finally {
      setState(() => _isCheckingEmail = false);
    }
  }

  Future<void> _checkNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(GameStrings.enterNickname)));
      return;
    }

    setState(() => _isCheckingNickname = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final available = await authProvider.isNicknameAvailable(nickname);

      setState(() {
        _isNicknameAvailable = available;
        _isNicknameChecked = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ErrorTranslator.translate(e))));
      }
    } finally {
      setState(() => _isCheckingNickname = false);
    }
  }

  Future<void> _handleSignup() async {
    if (_nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(GameStrings.enterNickname)));
      return;
    }

    if (!_isNicknameChecked || !_isNicknameAvailable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(GameStrings.errorNicknameCheckRequired)));
      return;
    }

    if (!_isEmailChecked || !_isEmailValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(GameStrings.errorEmailCheckRequired)));
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final colorHex =
        '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    try {
      await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nickname: _nicknameController.text.trim(),
        colorHex: colorHex,
        teamId: 'none',
      );
      if (mounted) {
        // 이메일 인증 안내 팝업 표시
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: GameColors.tacticalGray,
            title: Text(
              GameStrings.signupPending,
              style: TextStyle(color: GameColors.accentNeon),
            ),
            content: Text(
              GameStrings.signupCompleteMessage,
              style: TextStyle(color: GameColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 팝업 닫기
                  Navigator.of(context).pop(); // 회원가입 화면 닫기
                },
                child: Text(
                  GameStrings.confirm,
                  style: TextStyle(color: GameColors.accentNeon),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ErrorTranslator.translate(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          GameStrings.signup,
          style: TextStyle(letterSpacing: 2, fontSize: 16),
        ),
        backgroundColor: GameColors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  GameStrings.signupTitle,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: GameColors.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 40),

                // Nickname Field with Check Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _nicknameController,
                        label: GameStrings.nickname,
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 56,
                      child: TextButton(
                        onPressed: _isCheckingNickname ? null : _checkNickname,
                        style: TextButton.styleFrom(
                          backgroundColor: GameColors.accentNeon.withValues(alpha: 0.1),
                          foregroundColor: GameColors.accentNeon,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: _isCheckingNickname
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: GameColors.accentNeon,
                                ),
                              )
                            : const Text(
                                GameStrings.checkDuplicate,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                if (_isNicknameChecked)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      _isNicknameAvailable
                          ? '✓ ${GameStrings.nicknameAvailable}'
                          : '✕ ${GameStrings.errorNicknameExists}',
                      style: TextStyle(
                        color: _isNicknameAvailable ? GameColors.success : GameColors.error,
                        fontSize: 10,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // Email Field with Check Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _emailController,
                        label: GameStrings.emailAddress,
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 56,
                      child: TextButton(
                        onPressed: _isCheckingEmail ? null : _checkEmail,
                        style: TextButton.styleFrom(
                          backgroundColor: GameColors.accentNeon.withValues(alpha: 0.1),
                          foregroundColor: GameColors.accentNeon,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: _isCheckingEmail
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: GameColors.accentNeon,
                                ),
                              )
                            : const Text(
                                GameStrings.checkDuplicate,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                if (_isEmailChecked)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      _isEmailValid
                          ? '✓ ${GameStrings.emailAvailable}'
                          : '✕ ${GameStrings.emailInvalid}',
                      style: TextStyle(
                        color: _isEmailValid ? GameColors.success : GameColors.error,
                        fontSize: 10,
                      ),
                    ),
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
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    GameStrings.passwordHint,
                    style: TextStyle(color: GameColors.textMuted, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 30),

                // Color Selection Section
                Text(
                  GameStrings.selectTacticalColor,
                  style: TextStyle(
                    color: GameColors.textMuted,
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _selectedColor.withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                            style: TextStyle(
                              color: GameColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          OutlinedButton.icon(
                            onPressed: _generateRandomColor,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text(GameStrings.changeColor),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: GameColors.textSecondary,
                              side: BorderSide(color: GameColors.dividerColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),

                // Signup Button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameColors.accentNeon,
                        foregroundColor: GameColors.tacticalBlack,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
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
                              GameStrings.signup,
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
              ],
            ),
          ),
        ),
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
        labelStyle: TextStyle(
          color: GameColors.textMuted,
          fontSize: 12,
          letterSpacing: 1,
        ),
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
