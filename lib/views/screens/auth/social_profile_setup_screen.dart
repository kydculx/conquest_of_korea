import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/error_translator.dart';
import '../../../providers/auth_provider.dart';

/// 소셜 로그인을 성공적으로 마친 후, 서비스 내부에서 사용할 요원의 고유 닉네임과
/// 지도에 표시할 전술 컬러를 최초로 구성 및 등록하는 프로필 설정 화면 클래스입니다.
class SocialProfileSetupScreen extends StatefulWidget {
  /// 소셜 프로필 설정 화면의 생성자입니다.
  const SocialProfileSetupScreen({super.key});

  @override
  State<SocialProfileSetupScreen> createState() =>
      _SocialProfileSetupScreenState();
}

/// [SocialProfileSetupScreen]의 상태 및 사용자 입력 로직을 관리하는 상태 클래스입니다.
class _SocialProfileSetupScreenState extends State<SocialProfileSetupScreen> {
  /// 요원의 고유 닉네임 입력을 처리하는 텍스트 컨트롤러입니다.
  final _nicknameController = TextEditingController();

  /// 요원의 지도 렌더링에 매핑되는 고유 전술 색상입니다.
  Color _selectedColor = GameColors.accentNeon;

  /// 사용자가 닉네임 중복 체크를 완료했는지 여부를 나타내는 플래그입니다.
  bool _isNicknameChecked = false;

  /// 중복 확인 결과, 입력한 닉네임의 사용 가능 여부를 나타내는 플래그입니다.
  bool _isNicknameAvailable = false;

  /// 현재 닉네임 중복 상태 API를 호출 중인지 나타내는 플래그입니다.
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

  /// 요원의 전술 영역 구분을 위한 밝고 채도 높은 무작위 색상을 HSL 좌표계를 활용하여 생성합니다.
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

  /// 사용자가 입력한 닉네임의 중복성 검사를 위해 서버 API(Supabase)를 비동기 호출합니다.
  Future<void> _checkNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(GameStrings.enterNickname)));
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
            content: Text(
              available
                  ? GameStrings.nicknameAvailable
                  : GameStrings.errorNicknameExists,
            ),
            backgroundColor: available ? GameColors.success : GameColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ErrorTranslator.translate(e))));
      }
    } finally {
      setState(() => _isChecking = false);
    }
  }

  /// 닉네임 중복 확인 완료 후, 지정한 닉네임과 전술 색상 정보로 최종 프로필을 생성합니다.
  Future<void> _handleSave() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
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

    final authProvider = context.read<AuthProvider>();
    final colorHex =
        '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    try {
      await authProvider.createProfile(nickname: nickname, colorHex: colorHex);
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
                Text(
                  GameStrings.setupProfile,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: GameColors.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  GameStrings.setupProfileSub,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: GameColors.accentNeon,
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
                        style: TextStyle(color: GameColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: GameStrings.nickname,
                          labelStyle: TextStyle(
                            color: GameColors.textMuted,
                            fontSize: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: _isNicknameChecked
                                ? (_isNicknameAvailable
                                      ? GameColors.success
                                      : GameColors.error)
                                : GameColors.accentNeon,
                          ),
                          filled: true,
                          fillColor: GameColors.tacticalWhite.withValues(
                            alpha: 0.05,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: GameColors.dividerColor,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: GameColors.accentNeon,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 56,
                      child: TextButton(
                        onPressed: _isChecking ? null : _checkNickname,
                        style: TextButton.styleFrom(
                          backgroundColor: GameColors.accentNeon.withValues(
                            alpha: 0.1,
                          ),
                          foregroundColor: GameColors.accentNeon,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                        ),
                        child: _isChecking
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
                        color: _isNicknameAvailable
                            ? GameColors.success
                            : GameColors.error,
                        fontSize: 10,
                      ),
                    ),
                  ),
                const SizedBox(height: 30),

                Text(
                  GameStrings.myTacticalColor,
                  style: TextStyle(color: GameColors.textMuted, fontSize: 12),
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
                            color: _selectedColor.withValues(alpha: 0.4),
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
                        label: Text(GameStrings.generateNewColor),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: GameColors.textPrimary,
                          side: BorderSide(color: GameColors.dividerColor),
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
                        backgroundColor: GameColors.accentNeon,
                        foregroundColor: GameColors.tacticalBlack,
                        padding: const EdgeInsets.symmetric(vertical: 15),
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
                              GameStrings.setupComplete,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
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
