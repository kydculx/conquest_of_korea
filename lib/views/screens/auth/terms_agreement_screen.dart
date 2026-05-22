import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/constants/strings.dart';

class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  bool _agreeAge = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeLocation = false;
  bool _agreeMarketing = false;

  bool get _isAllRequiredAgreed =>
      _agreeAge && _agreeTerms && _agreePrivacy && _agreeLocation;

  bool get _isAllAgreed =>
      _agreeAge && _agreeTerms && _agreePrivacy && _agreeLocation && _agreeMarketing;

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
