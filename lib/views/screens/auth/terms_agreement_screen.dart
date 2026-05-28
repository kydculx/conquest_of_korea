import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import 'social_profile_setup_screen.dart';
import '../../widgets/tactical_app_bar.dart';

/// 신규 가입 프로세스 개시 전, 서비스 이용약관, 개인정보 보호정책,
/// 위치정보 활용 동의 등의 법적 필수 정책 사항을 검토하고 동의를 수집하는 약관 동의 화면 클래스입니다.
class TermsAgreementScreen extends StatefulWidget {
  /// 소셜 로그인 최초 가입 프로세스로부터 리다이렉트되어 진입했는지 여부
  final bool isSocial;

  /// 약관 동의 화면의 생성자입니다.
  const TermsAgreementScreen({super.key, this.isSocial = false});

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

/// [TermsAgreementScreen]의 개별 약관 동의 여부 상태 및 바텀시트 동작을 관리하는 상태 클래스입니다.
class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  /// 만 14세 이상 이용가 동의 상태 플래그입니다.
  bool _agreeAge = false;

  /// 서비스 이용약관 동의 상태 플래그입니다. (필수)
  bool _agreeTerms = false;

  /// 개인정보 수집 및 이용 동의 상태 플래그입니다. (필수)
  bool _agreePrivacy = false;

  /// 위치기반 서비스 이용약관 동의 상태 플래그입니다. (필수)
  bool _agreeLocation = false;

  /// 마케팅 정보 수신 동의 상태 플래그입니다. (선택)
  bool _agreeMarketing = false;

  /// 회원 가입 진행에 필요한 필수 약관들이 모두 동의되었는지 여부를 확인합니다.
  bool get _isAllRequiredAgreed =>
      _agreeAge && _agreeTerms && _agreePrivacy && _agreeLocation;

  /// 필수 항목 및 마케팅 선택 항목을 포함하여 모든 목록의 동의 완료 상태를 반환합니다.
  bool get _isAllAgreed =>
      _agreeAge &&
      _agreeTerms &&
      _agreePrivacy &&
      _agreeLocation &&
      _agreeMarketing;

  /// '전체 동의' 체크 박스 활성화 상태에 맞추어 모든 개별 동의 필드들을 일괄 제어합니다.
  void _toggleAgreeAll(bool? value) {
    final bool target = value ?? false;
    setState(() {
      _agreeAge = target;
      _agreeTerms = target;
      _agreePrivacy = target;
      _agreeLocation = target;
      _agreeMarketing = target;
    });
  }

  /// 상세 약관 콘텐츠 전문을 보여주는 모달 바텀시트를 화면에 띄웁니다.
  ///
  /// [title]은 바텀시트 상단 타이틀이며, [detailText]는 표시될 세부 약관 문자열입니다.
  void _showDetailBottomSheet(String title, String detailText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GameColors.backgroundMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: GoogleFonts.fredoka(
                  color: GameColors.accentNeon,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    detailText,
                    style: GoogleFonts.quicksand(
                      color: GameColors.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameColors.accentNeon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  GameStrings.confirm,
                  style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 필수 약관 동의 검증을 거친 후, 각 동의 시점 로그를 동반하여 회원정보 입력(회원가입) 화면으로 라우팅시킵니다.
  void _handleContinue() {
    if (!_isAllRequiredAgreed) return;

    final now = DateTime.now();
    if (widget.isSocial) {
      // 소셜 가입일 경우, 닉네임 및 전술색 설정 화면으로 라우팅 (약관 동의 화면으로 이전 pop이 가능하게 push 처리)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SocialProfileSetupScreen(),
          settings: RouteSettings(
            arguments: {
              'termsAgreedAt': now,
              'privacyAgreedAt': now,
              'locationAgreedAt': now,
              'marketingAgreedAt': _agreeMarketing ? now : null,
            },
          ),
        ),
      );
    } else {
      // 이메일 가입일 경우, 기존 이메일 정보 입력 화면으로 라우팅
      Navigator.pushNamed(
        context,
        '/signup',
        arguments: {
          'termsAgreedAt': now,
          'privacyAgreedAt': now,
          'locationAgreedAt': now,
          'marketingAgreedAt': _agreeMarketing ? now : null,
        },
      );
    }
  }

  /// SNS 가입 프로세스 도중 이탈을 시도할 때 활성 임시 세션을 강제 파괴(로그아웃)하고 로그인 화면으로 리다이렉트합니다.
  Future<void> _handleCancelSocialSignup() async {
    final authProvider = context.read<AuthProvider>();
    // unmounted 에러 및 Navigator 스킵 방지를 위해 화면 전환을 선제적으로 실행합니다.
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
    // 그 후 백그라운드에서 임시 SNS 세션을 안전하게 해제합니다.
    await authProvider.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final Widget mainContent = Scaffold(
      appBar: TacticalAppBar(
        titleText: GameStrings.termsAgreement,
        showBackButton: true,
        leadingOnPressed: () async {
          if (widget.isSocial) {
            await _handleCancelSocialSignup();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: GameColors.cozyDarkGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  GameStrings.appName,
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: GameColors.accentNeon,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  GameStrings.signupTitle,
                  style: GoogleFonts.fredoka(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: GameColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 30),

                // 전체 동의 타일
                Container(
                  decoration: BoxDecoration(
                    color: GameColors.tacticalGray.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isAllAgreed
                          ? GameColors.accentNeon.withValues(alpha: 0.4)
                          : GameColors.dividerColor.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      GameStrings.agreeAll,
                      style: GoogleFonts.fredoka(
                        color: GameColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    value: _isAllAgreed,
                    onChanged: _toggleAgreeAll,
                    activeColor: GameColors.accentNeon,
                    checkColor: Colors.white,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                const SizedBox(height: 24),

                // 개별 동의 약관 리스트
                Expanded(
                  child: ListView(
                    children: [
                      _buildAgreementTile(
                        label: GameStrings.agreeAge,
                        value: _agreeAge,
                        onChanged: (val) =>
                            setState(() => _agreeAge = val ?? false),
                      ),
                      _buildAgreementTile(
                        label: GameStrings.agreeTerms,
                        value: _agreeTerms,
                        onChanged: (val) =>
                            setState(() => _agreeTerms = val ?? false),
                        onViewDetail: () => _showDetailBottomSheet(
                          GameStrings.agreeTermsBottomSheetTitle,
                          GameStrings.agreeTermsDetail,
                        ),
                      ),
                      _buildAgreementTile(
                        label: GameStrings.agreePrivacy,
                        value: _agreePrivacy,
                        onChanged: (val) =>
                            setState(() => _agreePrivacy = val ?? false),
                        onViewDetail: () => _showDetailBottomSheet(
                          GameStrings.agreePrivacyBottomSheetTitle,
                          GameStrings.agreePrivacyDetail,
                        ),
                      ),
                      _buildAgreementTile(
                        label: GameStrings.agreeLocation,
                        value: _agreeLocation,
                        onChanged: (val) =>
                            setState(() => _agreeLocation = val ?? false),
                        onViewDetail: () => _showDetailBottomSheet(
                          GameStrings.agreeLocationBottomSheetTitle,
                          GameStrings.agreeLocationDetail,
                        ),
                      ),
                      _buildAgreementTile(
                        label: GameStrings.agreeMarketing,
                        value: _agreeMarketing,
                        onChanged: (val) =>
                            setState(() => _agreeMarketing = val ?? false),
                        onViewDetail: () => _showDetailBottomSheet(
                          GameStrings.agreeMarketingBottomSheetTitle,
                          GameStrings.agreeMarketingDetail,
                        ),
                        isOptional: true,
                      ),
                    ],
                  ),
                ),

                // 계속 진행 버튼
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: _isAllRequiredAgreed
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: _isAllRequiredAgreed ? _handleContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GameColors.accentNeon,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: GameColors.tacticalGray.withValues(
                        alpha: 0.3,
                      ),
                      disabledForegroundColor: GameColors.textMuted,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      GameStrings.agreeAndContinue,
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );

    return PopScope(
      canPop: !widget.isSocial,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (widget.isSocial) {
          await _handleCancelSocialSignup();
        }
      },
      child: mainContent,
    );
  }

  /// 개별 약관의 동의 상태와 상세 내용 링크 버튼을 제공하는 약관 동의 체크박스 위젯을 렌더링합니다.
  ///
  /// [label]은 약관 명칭이며, [value]는 동의 여부 상태, [onChanged]는 상태 값 변화 콜백입니다.
  /// [onViewDetail]을 구현하면 우측에 상세 약관 뷰 팝업을 연동하는 버튼을 띄우며, [isOptional]이 참이면 선택 사항으로 식별합니다.
  Widget _buildAgreementTile({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    VoidCallback? onViewDetail,
    bool isOptional = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: GameColors.tacticalGray.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? GameColors.accentNeon.withValues(alpha: 0.3)
              : GameColors.borderLight,
          width: 0.8,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          label,
          style: GoogleFonts.fredoka(
            color: value ? GameColors.textPrimary : GameColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: isOptional
            ? null
            : Text(
                '(${GameStrings.confirm} 필수)',
                style: GoogleFonts.quicksand(
                  color: value
                      ? GameColors.accentNeon.withValues(alpha: 0.8)
                      : GameColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
        value: value,
        onChanged: onChanged,
        activeColor: GameColors.accentNeon,
        checkColor: Colors.white,
        controlAffinity: ListTileControlAffinity.leading,
        secondary: onViewDetail != null
            ? TextButton(
                onPressed: onViewDetail,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  GameStrings.viewDetail,
                  style: GoogleFonts.fredoka(
                    color: GameColors.accentNeon,
                    fontSize: 10.5,
                    decoration: TextDecoration.underline,
                    decorationColor: GameColors.accentNeon,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
