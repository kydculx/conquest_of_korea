import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/error_translator.dart';
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

  /// 요원의 지도 렌더링에 매핑되는 고유 전술 색상입니다. (기본 파란색 고정)
  final Color _selectedColor = GameColors.info;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약관 동의 기록이 존재하지 않습니다. 다시 시도해 주세요.')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final colorHex =
        '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    // 현재 GPS 기준 현재타일을 구하여 내 기지로 지정
    final loc = context.read<LocationProvider>();
    final currentLocation = loc.currentLocation;

    String? mainBaseTileId;
    if (currentLocation != null) {
      final hex = HexService.latLngToHex(currentLocation);
      mainBaseTileId = 'hex_${hex['q']}_${hex['r']}';
    } else {
      // GPS 정보 미수신 시 안전 장치로 기본 맵 기준 좌표 적용
      final hex = HexService.latLngToHex(MapConfig.defaultPosition);
      mainBaseTileId = 'hex_${hex['q']}_${hex['r']}';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ErrorTranslator.translate(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget mainContent = Scaffold(
      appBar: TacticalAppBar(showBackButton: true),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. 하이테크 전술 배경 그리드 & 그라데이션
          Container(
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
          ),
          Positioned.fill(child: CustomPaint(painter: _TacticalGridPainter())),

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
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: GameColors.textPrimary,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    GameStrings.setupProfileSub,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: GameColors.accentNeon.withValues(alpha: 0.8),
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
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
                          style: TextStyle(color: GameColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: GameStrings.nickname,
                            labelStyle: TextStyle(
                              color: GameColors.textMuted,
                              fontSize: 12,
                              letterSpacing: 1,
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
                      const SizedBox(width: 15),
                      SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          onPressed: _isChecking ? null : _checkNickname,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _isChecking
                                  ? GameColors.dividerColor
                                  : GameColors.accentNeon.withValues(
                                      alpha: 0.5,
                                    ),
                            ),
                            backgroundColor: GameColors.accentNeon.withValues(
                              alpha: 0.05,
                            ),
                            foregroundColor: GameColors.accentNeon,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.8,
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
                      return ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GameColors.accentNeon,
                          foregroundColor: GameColors.tacticalBlack,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 6,
                          shadowColor: GameColors.accentNeon.withValues(
                            alpha: 0.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: auth.isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: GameColors.tacticalBlack,
                                ),
                              )
                            : Text(
                                GameStrings.setupComplete,
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

/// 전술 격자 배경을 그려주는 커스텀 페인터
class _TacticalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GameColors.dividerColor.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;

    const double step = 30.0;

    // 세로선 그리기
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 가로선 그리기
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
