import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/error_translator.dart';
import '../../../core/utils/toast_helper.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../services/hex_service.dart';
import '../../../core/constants/map_config.dart';
import '../../widgets/tactical_app_bar.dart';

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



  /// 사용자가 닉네임 중복 체크를 완료했는지 여부를 나타내는 플래그입니다.
  bool _isNicknameChecked = false;

  /// 중복 확인 결과, 입력한 닉네임의 사용 가능 여부를 나타내는 플래그입니다.
  bool _isNicknameAvailable = false;

  /// 현재 닉네임 중복 상태 API를 호출 중인지 나타내는 플래그입니다.
  bool _isChecking = false;

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
      ToastHelper.show(
        context: context,
        message: GameStrings.enterNickname,
        isSuccess: false,
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
        ToastHelper.show(
          context: context,
          message: available
              ? GameStrings.nicknameAvailable
              : GameStrings.errorNicknameExists,
          isSuccess: available,
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
    } finally {
      setState(() => _isChecking = false);
    }
  }

  /// 닉네임 중복 확인 완료 후, 지정한 닉네임과 전술 색상 정보로 최종 프로필을 생성합니다.
  Future<void> _handleSave() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
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

    // 약관 동의 화면으로부터 넘어온 동의 시각 인자 획득
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final termsAgreedAt = args?['termsAgreedAt'] as DateTime?;
    final privacyAgreedAt = args?['privacyAgreedAt'] as DateTime?;
    final locationAgreedAt = args?['locationAgreedAt'] as DateTime?;
    final marketingAgreedAt = args?['marketingAgreedAt'] as DateTime?;

    if (termsAgreedAt == null ||
        privacyAgreedAt == null ||
        locationAgreedAt == null) {
      ToastHelper.show(
        context: context,
        message: GameStrings.termsAgreementRecordNotFound,
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
      await authProvider.createProfile(
        nickname: nickname,
        colorHex: colorHex,
        termsAgreedAt: termsAgreedAt,
        privacyAgreedAt: privacyAgreedAt,
        locationAgreedAt: locationAgreedAt,
        marketingAgreedAt: marketingAgreedAt,
        mainBaseTileId: mainBaseTileId,
      );
      if (mounted) {
        Navigator.of(context).pop(); // 프로필 설정이 완료되면 즉시 화면을 닫아 본래의 게임 화면으로 복귀
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
    final Widget mainContent = Scaffold(
      appBar: const TacticalAppBar(showBackButton: true),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. 아기자기한 다크 밤하늘 배경 그라데이션
          Container(
            decoration: const BoxDecoration(
              gradient: GameColors.cozyDarkGradient,
            ),
          ),

          // 2. 메인 스크롤 콘텐츠
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // 상단 전술 레이더 아이콘
                  Center(
                    child: Icon(
                      Icons.radar_outlined,
                      size: 76,
                      color: GameColors.accentNeon,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    GameStrings.setupProfile.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: GameColors.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    GameStrings.setupProfileSub,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: GameColors.accentNeon,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 45),

                  // 닉네임 입력 필드 및 중복 검사 버튼
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nicknameController,
                          style: GoogleFonts.quicksand(color: GameColors.textPrimary, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: GameStrings.nickname,
                            labelStyle: GoogleFonts.fredoka(
                              color: GameColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: _isNicknameChecked
                                  ? (_isNicknameAvailable
                                        ? GameColors.success
                                        : GameColors.error)
                                  : GameColors.accentNeon,
                              size: 20,
                            ),
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
                        ),
                      ),
                      const SizedBox(width: 15),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _isChecking ? null : _checkNickname,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _isChecking
                                  ? GameColors.dividerColor
                                  : GameColors.accentNeon.withValues(
                                      alpha: 0.35,
                                    ),
                              width: 1.2,
                            ),
                            backgroundColor: GameColors.accentNeon.withValues(
                              alpha: 0.1,
                            ),
                            foregroundColor: GameColors.accentNeon,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: _isChecking
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
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
                      padding: const EdgeInsets.only(top: 10, left: 4),
                      child: Text(
                        _isNicknameAvailable
                            ? '✓ ${GameStrings.nicknameAvailable}'
                            : '✕ ${GameStrings.errorNicknameExists}',
                        style: TextStyle(
                          color: _isNicknameAvailable
                              ? GameColors.success
                              : GameColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),

                  // 최종 등록 승인 버튼
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
                          onPressed: auth.isLoading ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GameColors.accentNeon,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  GameStrings.setupComplete,
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
        ],
      ),
    );

    // 린트 이슈 수정을 위한 현대적 PopScope 연동 (pop 시 이전 화면으로 유기적으로 pop되게 canPop: true 설정)
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        // canPop이 true이므로 시스템 뒤로가기 시 자연스럽게 pop이 실행되어 약관 동의 화면으로 돌아갑니다.
      },
      child: mainContent,
    );
  }
}
