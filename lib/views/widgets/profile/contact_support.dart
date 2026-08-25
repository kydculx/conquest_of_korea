import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/error_translator.dart';
import '../../../core/utils/toast_helper.dart';

/// 문의하기 이메일 클라이언트 실행을 처리합니다.
Future<void> handleContactSupport(BuildContext context) async {
  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    path: GameUrls.supportEmail,
    query: _encodeQueryParameters(<String, String>{
      'subject': GameStrings.supportEmailSubject,
      'body': GameStrings.supportEmailBody,
    }),
  );

  try {
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (context.mounted) {
        ToastHelper.show(
          context: context,
          message: GameStrings.cannotOpenMailApp(GameUrls.supportEmail),
          isSuccess: false,
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ToastHelper.show(
        context: context,
        message: ErrorTranslator.translate(e),
        isSuccess: false,
      );
    }
  }
}

String? _encodeQueryParameters(Map<String, String> params) {
  return params.entries
      .map((MapEntry<String, String> e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
}
