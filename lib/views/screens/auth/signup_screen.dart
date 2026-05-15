import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
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
  
  Color _selectedColor = GameConstants.accentNeon;
  bool _isObscure = true;
  bool _isNicknameChecked = false;
  bool _isNicknameAvailable = false;
  bool _isCheckingNickname = false;

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

  Future<void> _checkNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요.')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorTranslator.translate(e))),
        );
      }
    } finally {
      setState(() => _isCheckingNickname = false);
    }
  }

  Future<void> _handleSignup() async {
    if (_nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요.')),
      );
      return;
    }

    if (!_isNicknameChecked || !_isNicknameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임 중복 확인을 해주세요.')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final colorHex = '#${_selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

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
            backgroundColor: GameConstants.tacticalGray,
            title: const Text('가입 승인 대기', style: TextStyle(color: GameConstants.accentNeon)),
            content: const Text(
              '회원가입 신청이 완료되었습니다.\n입력하신 이메일함에서 인증 링크를 클릭해야 계정이 활성화됩니다.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 팝업 닫기
                  Navigator.of(context).pop(); // 회원가입 화면 닫기
                },
                child: const Text('확인', style: TextStyle(color: GameConstants.accentNeon)),
              ),
            ],
          ),
        );
      }
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
      appBar: AppBar(
        title: const Text('대원 모집', style: TextStyle(letterSpacing: 2, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  '한국 정복에 참여하세요',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                        label: '닉네임',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 56,
                      child: TextButton(
                        onPressed: _isCheckingNickname ? null : _checkNickname,
                        style: TextButton.styleFrom(
                          backgroundColor: GameConstants.accentNeon.withOpacity(0.1),
                          foregroundColor: GameConstants.accentNeon,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        ),
                        child: _isCheckingNickname
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: GameConstants.accentNeon))
                            : const Text('중복 확인', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                if (_isNicknameChecked)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      _isNicknameAvailable ? '✓ 사용 가능한 닉네임입니다.' : '✕ 이미 존재하는 닉네임입니다.',
                      style: TextStyle(
                        color: _isNicknameAvailable ? Colors.green : Colors.red,
                        fontSize: 10,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

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
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    '• 최소 6자 이상의 비밀번호를 설정해주세요.',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 30),

                // Color Selection Section
                const Text(
                  '전술 컬러 선택',
                  style: TextStyle(
                    color: Colors.white54,
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
                            color: _selectedColor.withOpacity(0.5),
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
                            '#${_selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          OutlinedButton.icon(
                            onPressed: _generateRandomColor,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('색상 변경'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
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
                        backgroundColor: GameConstants.accentNeon,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
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
                              '대원 등록',
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
