import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/error_translator.dart';
import '../../../core/utils/terms_helper.dart';
import '../../../core/utils/toast_helper.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../services/hex_service.dart';
import '../../../core/constants/map_config.dart';
import '../../widgets/tactical_dialog.dart';
import '../../widgets/tactical_app_bar.dart';

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
      ToastHelper.show(
        context: context,
        message: GameStrings.enterEmail,
        isSuccess: false,
      );
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
      ToastHelper.show(
        context: context,
        message: GameStrings.enterNickname,
        isSuccess: false,
      );
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
        ToastHelper.show(
          context: context,
          message: ErrorTranslator.translate(e),
          isSuccess: false,
        );
      }
    } finally {
      setState(() => _isCheckingNickname = false);
    }
  }

  /// 필수 서비스 이용 약관의 동의 정보를 기반으로 회원 가입 및 계정 생성을 요청합니다.
  Future<void> _handleSignup() async {
    final termsArgs = TermsHelper.extract(context);
    if (termsArgs == null) {
      ToastHelper.show(
        context: context,
        message: GameStrings.requiredPolicyAgreementMissing,
        isSuccess: false,
      );
      Navigator.of(context).pop();
      return;
    }

    if (_nicknameController.text.isEmpty) {
      ToastHelper.show(
        context: context,
        message: GameStrings.enterNickname,
        isSuccess: false,
      );
      return;
    }

    if (!_isNicknameChecked || !_isNicknameAvailable) {
      ToastHelper.show(
        context: context,
        message: GameStrings.errorNicknameCheckRequired,
        isSuccess: false,
      );
      return;
    }

    if (!_isEmailChecked || !_isEmailValid) {
      ToastHelper.show(
        context: context,
        message: GameStrings.errorEmailCheckRequired,
        isSuccess: false,
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final colorHex = GameColors.myTileColorHex;

    // 현재 GPS 기준 현재타일을 구하여 내 기지로 지정
    final loc = context.read<LocationProvider>();
    final currentLocation = loc.currentLocation;

    String? mainBaseTileId;
    if (currentLocation != null) {
      final hex = HexService.latLngToHex(currentLocation);
      mainBaseTileId = HexService.tileId(hex['q']!, hex['r']!);
    } else {
      // GPS 정보 미수신 시 안전 장치로 기본 맵 기준 좌표 적용
      final hex = HexService.latLngToHex(MapConfig.defaultPosition);
      mainBaseTileId = HexService.tileId(hex['q']!, hex['r']!);
    }

    try {
      await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nickname: _nicknameController.text.trim(),
        colorHex: colorHex,
        termsAgreedAt: termsArgs.termsAgreedAt,
        privacyAgreedAt: termsArgs.privacyAgreedAt,
        locationAgreedAt: termsArgs.locationAgreedAt,
        marketingAgreedAt: termsArgs.marketingAgreedAt,
        teamId: 'none',
        mainBaseTileId: mainBaseTileId,
      );
      if (mounted) {
        // 이메일 인증 안내 팝업 표시
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => TacticalDialog(
            title: GameStrings.signupPending,
            icon: Icons.mark_email_unread_rounded,
            accentColor: GameColors.accentNeon,
            content: Text(
              GameStrings.signupCompleteMessage,
              style: TextStyle(color: GameColors.textSecondary, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 팝업 닫기
                  Navigator.of(context).pop(); // 회원가입 화면 닫기
                },
                child: Text(
                  GameStrings.confirm,
                  style: TextStyle(
                    color: GameColors.accentNeon,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TacticalAppBar(
        titleText: GameStrings.signup,
        showBackButton: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: GameColors.cozyDarkGradient,
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
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: GameColors.textPrimary,
                    letterSpacing: 0.5,
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
                            alpha: 0.15,
                          ),
                          foregroundColor: GameColors.accentNeon,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
                                style: GoogleFonts.fredoka(
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
                            alpha: 0.15,
                          ),
                          foregroundColor: GameColors.accentNeon,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
                                style: GoogleFonts.fredoka(
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
                const SizedBox(height: 40),

                // Signup Button
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
                        onPressed: auth.isLoading ? null : _handleSignup,
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
                                GameStrings.signup,
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
      style: GoogleFonts.quicksand(color: GameColors.textPrimary, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.fredoka(
          color: GameColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Icon(icon, color: GameColors.accentNeon, size: 20),
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
        fillColor: GameColors.tacticalGray.withValues(alpha: 0.5),
      ),
    );
  }
}
