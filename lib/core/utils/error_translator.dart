class ErrorTranslator {
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
        if (code == '23505') return '이미 사용 중인 정보(닉네임 등)입니다.';
        message = '데이터베이스 오류 ($code): ${error.message}';
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
        return '이미 사용 중인 닉네임 또는 이메일입니다.';
      }
      return '서버 데이터베이스 오류가 발생했습니다.';
    }

    if (lowerMsg.contains('user already registered') || lowerMsg.contains('already registered')) {
      return '이미 가입된 이메일입니다.';
    }
    if (lowerMsg.contains('invalid login credentials') || lowerMsg.contains('invalid credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    }
    if (lowerMsg.contains('email not confirmed')) {
      return '이메일 인증이 완료되지 않았습니다.';
    }
    if (lowerMsg.contains('signup requires a valid password') || lowerMsg.contains('weak password')) {
      return '비밀번호는 최소 6자 이상이어야 합니다.';
    }
    if (lowerMsg.contains('unable to validate id_token')) {
      return '인증 정보가 유효하지 않습니다.';
    }
    if (lowerMsg.contains('sign_in_failed') || lowerMsg.contains('api_exception: 10') || lowerMsg.contains('apiexception: 10')) {
      return '구글 로그인 설정 오류가 발생했습니다. (SHA-1 등록 필요)';
    }
    if (lowerMsg.contains('network_error') || lowerMsg.contains('socketexception') || lowerMsg.contains('network error')) {
      return '네트워크 연결 상태를 확인해주세요.';
    }
    if (lowerMsg.contains('google sign in aborted') || lowerMsg.contains('sign_in_canceled') || lowerMsg.contains('canceled')) {
      return '로그인이 취소되었습니다.';
    }
    if (lowerMsg.contains('unacceptable audience')) {
      return '카카오 로그인 설정 오류가 발생했습니다. (Client ID 확인 필요)';
    }
    if (lowerMsg.contains('nickname_already_exists') || lowerMsg.contains('nickname already exists') || lowerMsg.contains('23505')) {
      return '이미 사용 중인 닉네임입니다.';
    }

    // 기본 오류 메시지 처리
    return '오류가 발생했습니다: $message';
  }
}
