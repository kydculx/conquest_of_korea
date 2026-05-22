import '../constants/strings.dart';

/// 시스템 발생 오류 메시지를 사용자 친화적인 다국어 에러 메시지로 번역하는 유틸리티 클래스
class ErrorTranslator {
  /// 외부 Exception 또는 에러 문자열을 분석하여 [GameStrings]에 정의된 한글 번역 메시지로 변환합니다.
  static String translate(dynamic error) {
    String message = error.toString();
    
    // Supabase AuthException 처리
    try {
      if (error.runtimeType.toString().contains('AuthException')) {
        message = error.message ?? message;
      }
    } catch (_) {}

    // Supabase PostgrestException 처리
    try {
      if (error.runtimeType.toString().contains('PostgrestException')) {
        final String code = error.code ?? '';
        if (code == '23505') return GameStrings.errorDuplicateInfo;
        message = '${GameStrings.errorDatabase} ($code): ${error.message}';
      }
    } catch (_) {}

    // PlatformException 처리
    try {
      if (error.runtimeType.toString().contains('PlatformException')) {
        message = '${error.code}: ${error.message}';
      }
    } catch (_) {}

    final String lowerMsg = message.toLowerCase();

    // 데이터베이스 관련 키워드 통합 처리
    if (lowerMsg.contains('postgrest') || lowerMsg.contains('postgres') || lowerMsg.contains('database error')) {
      if (lowerMsg.contains('23505') || lowerMsg.contains('unique_violation')) {
        return GameStrings.errorDuplicateInfo;
      }
      return GameStrings.errorDatabase;
    }

    if (lowerMsg.contains('user already registered') || lowerMsg.contains('already registered')) {
      return GameStrings.errorDuplicateEmail;
    }
    if (lowerMsg.contains('invalid login credentials') || lowerMsg.contains('invalid credentials')) {
      return GameStrings.errorInvalidCredentials;
    }
    if (lowerMsg.contains('email not confirmed')) {
      return GameStrings.errorEmailNotConfirmed;
    }
    if (lowerMsg.contains('signup requires a valid password') || lowerMsg.contains('weak password')) {
      return GameStrings.errorWeakPassword;
    }
    if (lowerMsg.contains('unable to validate id_token')) {
      return GameStrings.errorInvalidAuth;
    }
    if (lowerMsg.contains('sign_in_failed') || lowerMsg.contains('api_exception: 10') || lowerMsg.contains('apiexception: 10')) {
      return GameStrings.errorGoogleConfig;
    }
    if (lowerMsg.contains('network_error') || lowerMsg.contains('socketexception') || lowerMsg.contains('network error')) {
      return GameStrings.errorNetwork;
    }
    if (lowerMsg.contains('google sign in aborted') || lowerMsg.contains('sign_in_canceled') || lowerMsg.contains('canceled')) {
      return GameStrings.errorLoginCanceled;
    }
    if (lowerMsg.contains('unacceptable audience')) {
      return GameStrings.errorKakaoConfig;
    }
    if (lowerMsg.contains('nickname_already_exists') || lowerMsg.contains('nickname already exists') || lowerMsg.contains('23505')) {
      return GameStrings.errorNicknameExists;
    }

    // 기본 오류 메시지 처리
    return '${GameStrings.errorUnknown}: $message';
  }
}
