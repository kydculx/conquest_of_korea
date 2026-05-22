import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';

/// 신규 가입 프로세스 개시 전, 서비스 이용약관, 개인정보 보호정책,
/// 위치정보 활용 동의 등의 법적 필수 정책 사항을 검토하고 동의를 수집하는 약관 동의 화면 클래스입니다.
class TermsAgreementScreen extends StatefulWidget {
  /// 약관 동의 화면의 생성자입니다.
  const TermsAgreementScreen({super.key});

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
      _agreeAge && _agreeTerms && _agreePrivacy && _agreeLocation && _agreeMarketing;

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                style: TextStyle(
                  color: GameColors.accentNeon,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    detailText,
                    style: TextStyle(
                      color: GameColors.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameColors.accentNeon,
                  foregroundColor: GameColors.tacticalBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text(
                  GameStrings.confirm,
                  style: const TextStyle(fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          GameStrings.termsAgreement,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  GameStrings.appName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: GameColors.accentNeon,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  GameStrings.signupTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: GameColors.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 30),

                // 전체 동의 타일
                Container(
                  decoration: BoxDecoration(
                    color: GameColors.tacticalWhite.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isAllAgreed
                          ? GameColors.accentNeon.withValues(alpha: 0.4)
                          : GameColors.dividerColor,
                      width: 1,
                    ),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      GameStrings.agreeAll,
                      style: TextStyle(
                        color: GameColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    value: _isAllAgreed,
                    onChanged: _toggleAgreeAll,
                    activeColor: GameColors.accentNeon,
                    checkColor: GameColors.tacticalBlack,
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
                        onChanged: (val) => setState(() => _agreeAge = val ?? false),
                      ),
                      _buildAgreementTile(
                        label: GameStrings.agreeTerms,
                        value: _agreeTerms,
                        onChanged: (val) => setState(() => _agreeTerms = val ?? false),
                        onViewDetail: () => _showDetailBottomSheet(
                          GameStrings.agreeTermsBottomSheetTitle,
                          GameStrings.agreeTermsDetail,
                        ),
                      ),
                      _buildAgreementTile(
                        label: GameStrings.agreePrivacy,
                        value: _agreePrivacy,
                        onChanged: (val) => setState(() => _agreePrivacy = val ?? false),
                        onViewDetail: () => _showDetailBottomSheet(
                          GameStrings.agreePrivacyBottomSheetTitle,
                          GameStrings.agreePrivacyDetail,
                        ),
                      ),
                      _buildAgreementTile(
                        label: GameStrings.agreeLocation,
                        value: _agreeLocation,
                        onChanged: (val) => setState(() => _agreeLocation = val ?? false),
                        onViewDetail: () => _showDetailBottomSheet(
                          GameStrings.agreeLocationBottomSheetTitle,
                          GameStrings.agreeLocationDetail,
                        ),
                      ),
                      _buildAgreementTile(
                        label: GameStrings.agreeMarketing,
                        value: _agreeMarketing,
                        onChanged: (val) => setState(() => _agreeMarketing = val ?? false),
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
                ElevatedButton(
                  onPressed: _isAllRequiredAgreed ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameColors.accentNeon,
                    foregroundColor: GameColors.tacticalBlack,
                    disabledBackgroundColor: GameColors.tacticalGray.withValues(alpha: 0.5),
                    disabledForegroundColor: GameColors.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    elevation: _isAllRequiredAgreed ? 8 : 0,
                    shadowColor: GameColors.accentNeon.withValues(alpha: 0.5),
                  ),
                  child: Text(
                    GameStrings.agreeAndContinue,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1,
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
        color: GameColors.tacticalWhite.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: value
              ? GameColors.accentNeon.withValues(alpha: 0.2)
              : GameColors.borderLight,
          width: 0.8,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          label,
          style: TextStyle(
            color: value ? GameColors.textPrimary : GameColors.textSecondary,
            fontSize: 12.5,
            fontWeight: value ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: isOptional
            ? null
            : Text(
                '(${GameStrings.confirm} 필수)',
                style: TextStyle(
                  color: value ? GameColors.accentNeon.withValues(alpha: 0.6) : GameColors.textMuted,
                  fontSize: 10,
                ),
              ),
        value: value,
        onChanged: onChanged,
        activeColor: GameColors.accentNeon,
        checkColor: GameColors.tacticalBlack,
        controlAffinity: ListTileControlAffinity.leading,
        secondary: onViewDetail != null
            ? TextButton(
                onPressed: onViewDetail,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  GameStrings.viewDetail,
                  style: TextStyle(
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
