import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/version_config.dart';
import '../../core/utils/device_platform.dart';
import '../../core/utils/toast_helper.dart';
import '../../models/inquiry_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../widgets/profile/contact_support.dart';
import '../widgets/tactical_app_bar.dart';

const List<String> _inquiryCategories = ['bug', 'feature', 'account', 'etc'];

/// 앱 안에서 문의 제목과 내용을 작성해 접수하고,
/// 지난 문의와 관리자 답변을 함께 확인하는 화면 클래스입니다.
class InquiryScreen extends StatefulWidget {
  const InquiryScreen({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen>
    with WidgetsBindingObserver {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _category = 'etc';
  bool _submitting = false;
  bool _loadingHistory = true;
  List<UserInquiry> _history = const [];
  bool _emailPrefilled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadHistory();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_emailPrefilled) return;
    final String? email = context.read<AuthProvider>().user?.email;
    if (email != null && email.isNotEmpty) {
      _emailController.text = email;
      _emailPrefilled = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _contentController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _loadingHistory = true);
    final List<UserInquiry> inquiries = await context
        .read<SupabaseService>()
        .fetchMyInquiries();
    if (!mounted) return;
    setState(() {
      _history = inquiries;
      _loadingHistory = false;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final String title = _titleController.text.trim();
    final String content = _contentController.text.trim();
    final String email = _emailController.text.trim();

    if (title.length < 2 || content.length < 5) {
      ToastHelper.show(
        context: context,
        message: GameStrings.inquiryValidationRequired,
        isSuccess: false,
      );
      return;
    }
    if (!_isValidEmail(email)) {
      ToastHelper.show(
        context: context,
        message: GameStrings.inquiryValidationEmail,
        isSuccess: false,
      );
      return;
    }

    setState(() => _submitting = true);
    final InquirySubmitResult result = await context
        .read<SupabaseService>()
        .submitInquiry(
          category: _category,
          title: title,
          content: content,
          email: email,
          locale: _localeCode(Localizations.localeOf(context)),
          appVersion: '${VersionConfig.version} (${VersionConfig.buildNumber})',
          platform: detectDevicePlatform(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!result.success) {
      ToastHelper.show(
        context: context,
        message: _errorMessage(result.errorCode),
        isSuccess: false,
      );
      return;
    }

    _titleController.clear();
    _contentController.clear();
    FocusScope.of(context).unfocus();
    ToastHelper.show(context: context, message: GameStrings.inquirySent);
    await _loadHistory();
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }

  String _errorMessage(String? errorCode) {
    switch (errorCode) {
      case 'rate_limited':
        return GameStrings.inquiryErrorRateLimited;
      case 'invalid_email':
        return GameStrings.inquiryValidationEmail;
      case 'invalid_title':
      case 'invalid_content':
      case 'invalid_body':
      case 'invalid_category':
        return GameStrings.inquiryValidationRequired;
      default:
        return GameStrings.inquiryErrorGeneric;
    }
  }

  String _localeCode(Locale locale) {
    if (locale.languageCode == 'zh') {
      final String? country = locale.countryCode;
      return country == 'TW' || country == 'HK' ? 'zh_TW' : 'zh';
    }
    return locale.languageCode;
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'bug':
        return GameStrings.inquiryCategoryBug;
      case 'feature':
        return GameStrings.inquiryCategoryFeature;
      case 'account':
        return GameStrings.inquiryCategoryAccount;
      default:
        return GameStrings.inquiryCategoryEtc;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'answered':
        return GameStrings.inquiryStatusAnswered;
      case 'closed':
        return GameStrings.inquiryStatusClosed;
      default:
        return GameStrings.inquiryStatusOpen;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'answered':
        return GameColors.success;
      case 'closed':
        return GameColors.textMuted;
      default:
        return GameColors.warning;
    }
  }

  String _intlLocale(BuildContext context) {
    final String tag = Localizations.localeOf(
      context,
    ).toLanguageTag().replaceAll('-', '_');
    try {
      DateFormat.yMMMd(tag).format(DateTime.utc(2026, 1, 1));
      return tag;
    } catch (_) {
      return 'en';
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    return DateFormat.yMMMd(_intlLocale(context)).add_Hm().format(date);
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      labelStyle: TextStyle(color: GameColors.textMuted, fontSize: 13),
      hintStyle: TextStyle(
        color: GameColors.textMuted.withValues(alpha: 0.7),
        fontSize: 13,
      ),
      counterStyle: TextStyle(color: GameColors.textMuted, fontSize: 11),
      filled: true,
      fillColor: GameColors.tacticalBlack.withValues(alpha: 0.55),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: GameColors.dividerColor.withValues(alpha: 0.35),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: GameColors.accentNeon.withValues(alpha: 0.65),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: GameColors.backgroundMedium.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: GameColors.dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          color: GameColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: GameColors.tacticalBlack,
      appBar: TacticalAppBar(
        titleText: GameStrings.contactSupport,
        showBackButton: true,
      ),
      body: RefreshIndicator(
        color: GameColors.accentNeon,
        backgroundColor: GameColors.backgroundMedium,
        onRefresh: _loadHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20.0 + media.padding.left,
              20.0,
              20.0 + media.padding.right,
              32.0 + media.padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  GameStrings.inquiryFormIntro,
                  style: TextStyle(
                    color: GameColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                _buildForm(),
                const SizedBox(height: 28),
                _sectionTitle(GameStrings.inquiryHistoryTitle),
                _buildHistory(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            GameStrings.inquiryCategoryLabel,
            style: TextStyle(
              color: GameColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _inquiryCategories.map((String category) {
              final bool selected = _category == category;
              return ChoiceChip(
                label: Text(_categoryLabel(category)),
                selected: selected,
                onSelected: _submitting
                    ? null
                    : (_) => setState(() => _category = category),
                labelStyle: TextStyle(
                  color: selected
                      ? GameColors.tacticalBlack
                      : GameColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                selectedColor: GameColors.accentNeon,
                backgroundColor: GameColors.tacticalBlack.withValues(
                  alpha: 0.5,
                ),
                side: BorderSide(
                  color: selected
                      ? GameColors.accentNeon
                      : GameColors.dividerColor.withValues(alpha: 0.4),
                ),
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _titleController,
            enabled: !_submitting,
            maxLength: 120,
            style: TextStyle(color: GameColors.textPrimary, fontSize: 14),
            decoration: _fieldDecoration(
              label: GameStrings.inquiryTitleLabel,
              hint: GameStrings.inquiryTitleHint,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _contentController,
            enabled: !_submitting,
            maxLength: 5000,
            maxLines: 7,
            minLines: 5,
            style: TextStyle(
              color: GameColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: _fieldDecoration(
              label: GameStrings.inquiryContentLabel,
              hint: GameStrings.inquiryContentHint,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _emailController,
            enabled: !_submitting,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            style: TextStyle(color: GameColors.textPrimary, fontSize: 14),
            decoration: _fieldDecoration(
              label: GameStrings.inquiryEmailLabel,
              hint: GameStrings.inquiryEmailHint,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: GameColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  GameStrings.inquiryPrivacyNote,
                  style: TextStyle(
                    color: GameColors.textMuted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: GameColors.accentNeon,
                foregroundColor: GameColors.tacticalBlack,
                disabledBackgroundColor: GameColors.accentNeon.withValues(
                  alpha: 0.35,
                ),
                disabledForegroundColor: GameColors.tacticalBlack.withValues(
                  alpha: 0.6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _submitting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: GameColors.tacticalBlack,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          GameStrings.inquirySending,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      GameStrings.inquirySend,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: _submitting
                  ? null
                  : () => handleContactSupport(context),
              icon: Icon(
                Icons.mail_outline_rounded,
                size: 16,
                color: GameColors.textMuted,
              ),
              label: Text(
                GameStrings.inquiryMailFallback,
                style: TextStyle(color: GameColors.textMuted, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(BuildContext context) {
    if (_loadingHistory) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: GameColors.accentNeon,
            ),
          ),
        ),
      );
    }

    if (_history.isEmpty) {
      return _card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              GameStrings.inquiryHistoryEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(color: GameColors.textMuted, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _history.map((UserInquiry inquiry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildHistoryItem(context, inquiry),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryItem(BuildContext context, UserInquiry inquiry) {
    final Color statusColor = _statusColor(inquiry.status);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: GameColors.accentNeon.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _categoryLabel(inquiry.category),
                  style: TextStyle(
                    color: GameColors.accentNeon,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(context, inquiry.createdAt),
                style: TextStyle(color: GameColors.textMuted, fontSize: 11),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel(inquiry.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            inquiry.title,
            style: TextStyle(
              color: GameColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            inquiry.content,
            style: TextStyle(
              color: GameColors.textSecondary,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          if (inquiry.hasAnswer) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: GameColors.dividerColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.subdirectory_arrow_right_rounded,
                  size: 14,
                  color: GameColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  GameStrings.inquiryAnswerLabel,
                  style: TextStyle(
                    color: GameColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (inquiry.answeredAt != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(context, inquiry.answeredAt!),
                    style: TextStyle(color: GameColors.textMuted, fontSize: 10),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GameColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GameColors.success.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                inquiry.answer!,
                style: TextStyle(
                  color: GameColors.textPrimary,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
