import 'package:flutter/material.dart';

/// 약관 동의 화면에서 전달된 동의 시각 인자를 추출하고 검증하는 유틸리티 클래스.
///
/// [TermsHelper.extract]를 통해 [ModalRoute]의 arguments에서
/// termsAgreedAt, privacyAgreedAt, locationAgreedAt, marketingAgreedAt를 읽어
/// 필수 3개(terms, privacy, location)가 모두 존재하는지 검증한 후
/// [TermsAgreementArgs] 객체로 반환합니다.
class TermsHelper {
  /// 라우트 arguments로부터 약관 동의 시각 인자를 추출합니다.
  /// 필수 항목(terms, privacy, location)이 누락된 경우 null을 반환합니다.
  static TermsAgreementArgs? extract(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final termsAgreedAt = args?['termsAgreedAt'] as DateTime?;
    final privacyAgreedAt = args?['privacyAgreedAt'] as DateTime?;
    final locationAgreedAt = args?['locationAgreedAt'] as DateTime?;
    final marketingAgreedAt = args?['marketingAgreedAt'] as DateTime?;

    if (termsAgreedAt == null ||
        privacyAgreedAt == null ||
        locationAgreedAt == null) {
      return null;
    }

    return TermsAgreementArgs(
      termsAgreedAt: termsAgreedAt,
      privacyAgreedAt: privacyAgreedAt,
      locationAgreedAt: locationAgreedAt,
      marketingAgreedAt: marketingAgreedAt,
    );
  }
}

/// 약관 동의 시각 정보를 담는 데이터 클래스
class TermsAgreementArgs {
  final DateTime termsAgreedAt;
  final DateTime privacyAgreedAt;
  final DateTime locationAgreedAt;
  final DateTime? marketingAgreedAt;

  const TermsAgreementArgs({
    required this.termsAgreedAt,
    required this.privacyAgreedAt,
    required this.locationAgreedAt,
    this.marketingAgreedAt,
  });
}
