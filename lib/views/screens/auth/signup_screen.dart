import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/error_translator.dart';
import '../../../providers/auth_provider.dart';

/// 이메일과 비밀번호 기반의 자체 회원 계정을 생성하고, 서비스 내 고유 닉네임 및
/// 전술 색상을 최초로 연동하여 신규 가입을 처리하는 회원가입 화면 클래스입니다.
class SignupScreen extends StatefulWidget {
  /// 회원가입 화면의 생성자입니다.
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

/// [SignupScreen]의 상태 및 회원가입에 필요한 유효성 검증 로직을 관리하는 상태 클래스입니다.
class _SignupScreenState extends State<SignupScreen> {
  /// 입력받은 이메일 주소를 처리하는 텍스트 컨트롤러입니다.
  final _emailController = TextEditingController();

  /// 입력받은 비밀번호를 처리하는 텍스트 컨트롤러입니다.
  final _passwordController = TextEditingController();

  /// 입력받은 닉네임을 처리하는 텍스트 컨트롤러입니다.
  final _nicknameController = TextEditingController();

  /// 요원의 전술 영역 구분을 위한 고유 매핑 색상입니다.
  Color _selectedColor = GameColors.accentNeon;

  /// 비밀번호 입력란의 마스킹(숨김) 활성화 여부 플래그입니다.
  bool _isObscure = true;

  /// 닉네임 중복 체크 여부를 나타내는 플래그입니다.
  bool _isNicknameChecked = false;

  /// 중복 확인 결과 닉네임의 가용 여부를 나타내는 플래그입니다.
  bool _isNicknameAvailable = false;

  /// 닉네임의 서버 중복 검사가 비동기적으로 호출 중인지 나타내는 플래그입니다.
  bool _isCheckingNickname = false;

  /// 이메일의 중복 및 형식 체크 완료 여부를 나타내는 플래그입니다.
  bool _isEmailChecked = false;

  /// 이메일의 형식이 유효하고 사용 가능한 계정인지 여부를 나타내는 플래그입니다.
  bool _isEmailValid = false;

  /// 이메일 검사를 수행 중인 상태인지 나타내는 플래그입니다.
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

  /// 요원의 전술 영역 구분을 위한 밝고 채도 높은 무작위 색상을 HSL 좌표계를 활용하여 생성합니다.
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

  /// 사용자가 입력한 이메일의 정규식 규격 일치성 및 서버상의 존재 여부를 비동기적으로 검증합니다.
  Future<void> _checkEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(GameStrings.enterEmail)));
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

  /// 사용자가 입력한 닉네임의 서버 중복 여부를 비동기적으로 호출하여 검증합니다.
  Future<void> _checkNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(GameStrings.enterNickname)));
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

  /// 필수 서비스 이용 약관의 동의 정보를 기반으로 회원 가입 및 계정 생성을 요청합니다.
  Future<void> _handleSignup() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final termsAgreedAt = args?['termsAgreedAt'] as DateTime?;
    final privacyAgreedAt = args?['privacyAgreedAt'] as DateTime?;
    final locationAgreedAt = args?['locationAgreedAt'] as DateTime?;
    final marketingAgreedAt = args?['marketingAgreedAt'] as DateTime?;

    if (termsAgreedAt == null || privacyAgreedAt == null || locationAgreedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 정책 동의 정보가 누락되었습니다. 다시 시도해주세요.')),
      );
      Navigator.of(context).pop();
      return;
    }

    if (_nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(GameStrings.enterNickname)));
      return;
    }

    if (!_isNicknameChecked || !_isNicknameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(GameStrings.errorNicknameCheckRequired)),
      );
      return;
    }

    if (!_isEmailChecked || !_isEmailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(GameStrings.errorEmailCheckRequired)),
      );
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
        termsAgreedAt: termsAgreedAt,
        privacyAgreedAt: privacyAgreedAt,
        locationAgreedAt: locationAgreedAt,
        marketingAgreedAt: marketingAgreedAt,
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
        title: Text(
          GameStrings.signup,
          style: const TextStyle(letterSpacing: 2, fontSize: 16),
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
                          backgroundColor: GameColors.accentNeon.withValues(
                            alpha: 0.1,
                          ),
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
                            : Text(
                                GameStrings.checkDuplicate,
                                style: const TextStyle(
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
                        color: _isNicknameAvailable
                            ? GameColors.success
                            : GameColors.error,
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
                          backgroundColor: GameColors.accentNeon.withValues(
                            alpha: 0.1,
                          ),
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
                            : Text(
                                GameStrings.checkDuplicate,
                                style: const TextStyle(
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
                        color: _isEmailValid
                            ? GameColors.success
                            : GameColors.error,
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
                            label: Text(GameStrings.changeColor),
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
                          : Text(
                              GameStrings.signup,
                              style: const TextStyle(
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

  /// 회원가입 입력 필드 디자인의 통일성을 위한 커스텀 텍스트 폼 필드를 빌드하는 헬퍼 메서드입니다.
  /// 
  /// [controller]는 텍스트 입력을 제어하며, [label]은 입력란의 힌트/라벨 텍스트입니다.
  /// [icon]은 입력란 좌측의 접두사 아이콘이며, [isObscure]가 참이면 텍스트를 마스킹 처리합니다.
  /// [suffixIcon]은 입력란 우측에 들어갈 부가적인 아이콘 버튼(예: 패스워드 표시 토글)입니다.
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
