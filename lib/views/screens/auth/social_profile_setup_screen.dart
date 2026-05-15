import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/utils/error_translator.dart';
import '../../../providers/auth_provider.dart';

class SocialProfileSetupScreen extends StatefulWidget {
  const SocialProfileSetupScreen({super.key});

  @override
  State<SocialProfileSetupScreen> createState() => _SocialProfileSetupScreenState();
}

class _SocialProfileSetupScreenState extends State<SocialProfileSetupScreen> {
  final _nicknameController = TextEditingController();
  Color _selectedColor = GameConstants.accentNeon;
  bool _isNicknameChecked = false;
  bool _isNicknameAvailable = false;
  bool _isChecking = false;

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
    final double h = random.nextDouble() * 360;
    final double s = 0.8 + (random.nextDouble() * 0.2);
    final double l = 0.5 + (random.nextDouble() * 0.2);
    
    setState(() {
      _selectedColor = HSLColor.fromAHSL(1.0, h, s, l).toColor();
    });
  }

  @override
  void dispose() {
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

    setState(() => _isChecking = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final available = await authProvider.isNicknameAvailable(nickname);
      
      setState(() {
        _isNicknameAvailable = available;
        _isNicknameChecked = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(available ? '사용 가능한 닉네임입니다.' : '이미 사용 중인 닉네임입니다.'),
            backgroundColor: available ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorTranslator.translate(e))),
        );
      }
    } finally {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _handleSave() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
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
      await authProvider.createProfile(
        nickname: nickname,
        colorHex: colorHex,
      );
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
                const Text(
                  '프로필 초기 설정',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '당신의 전술 식별 정보를 설정하세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: GameConstants.accentNeon,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 50),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nicknameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: '닉네임',
                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: _isNicknameChecked 
                                ? (_isNicknameAvailable ? Colors.green : Colors.red) 
                                : GameConstants.accentNeon,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: GameConstants.accentNeon)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 56,
                      child: TextButton(
                        onPressed: _isChecking ? null : _checkNickname,
                        style: TextButton.styleFrom(
                          backgroundColor: GameConstants.accentNeon.withOpacity(0.1),
                          foregroundColor: GameConstants.accentNeon,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                        ),
                        child: _isChecking
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
                const SizedBox(height: 30),

                const Text(
                  '나만의 전술 색상',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: _selectedColor.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _generateRandomColor,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('새로운 색상 생성'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),

                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameConstants.accentNeon,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('설정 완료', style: TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
