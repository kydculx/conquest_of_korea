import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../core/constants/strings.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// 현재 로그인된 사용자 정보 가져오기
  User? get currentUser => _client.auth.currentUser;

  /// 세션 스트림
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// 회원가입
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nickname,
    required String colorHex,
    String teamId = 'none',
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'com.watercherry.conquestofkorea://login-callback',
      data: {
        'nickname': nickname,
        'color_hex': colorHex,
        // 'team_id': teamId, // DB 컬럼 부재로 임시 주석 처리
      },
    );

    // Supabase 이메일 열거 방지(Prevent email enumeration) 정책 대응
    // 이미 존재하는 이메일로 가입 시도 시 에러 대신 가짜 User 객체를 반환하며 identities가 비어있음
    if (response.user != null &&
        response.user!.identities != null &&
        response.user!.identities!.isEmpty) {
      throw AuthException(
        GameStrings.emailAlreadyInUse,
        statusCode: '400',
      );
    }

    // 가입 성공 시 profiles 테이블에 추가 데이터 저장
    if (response.user != null) {
      try {
        await _client.from('profiles').upsert({
          'id': response.user!.id,
          'nickname': nickname,
          'color_hex': colorHex,
          // 'team_id': teamId, // DB 컬럼 부재로 임시 주석 처리
          'created_at': DateTime.now().toIso8601String(),
          'total_distance': 0.0,
          'daily_distance': 0.0,
        });
      } catch (e) {
        // 42501(권한 부족) 등의 오류는 이메일 인증 전이라 발생할 수 있음
        // 데이터는 이미 auth.users의 metadata에 저장되어 있으므로 로그만 남기고 진행
        debugPrint('⚠️ 프로필 테이블 저장 생략 (인증 대기 중일 수 있음): $e');
      }
    }

    return response;
  }

  /// 로그인
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// 구글 로그인 (네이티브)
  Future<void> signInWithGoogle() async {
    try {
      debugPrint('🚀 Native Google Sign In Start...');

      // GoogleSignIn 설정 (Web Client ID 필수)
      const webClientId =
          '99438286233-e5fpvqd6ngo56e7230vej7aj5efhjg31.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS
            ? '99438286233-62t2u5rmkpvtvhulta47ntk4dnnianqn.apps.googleusercontent.com'
            : null,
        serverClientId: webClientId,
      );

      // 1. 네이티브 로그인 창 표시
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('⚠️ Google Sign In cancelled by user');
        return;
      }

      // 2. 인증 정보 획득
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) throw GameStrings.idTokenFetchFailed;

      debugPrint('🔑 Native Google Auth Success. ID Token found.');

      // 3. Supabase에 ID Token으로 로그인 시도
      // 주의: Nonce mismatch 에러 발생 시 Supabase 대시보드에서 "Skip nonce checks"를 활성화해야 합니다.
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      debugPrint('✅ Supabase Native Google Login Success');
    } catch (e) {
      debugPrint('❌ Native Google Auth Error: $e');
      rethrow;
    }
  }

  /// 애플 로그인
  Future<void> signInWithApple() async {
    if (!kIsWeb && Platform.isIOS) {
      // iOS: 네이티브 Apple ID 인증 사용
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) throw 'No ID Token found.';

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );
    } else {
      // Android 및 기타: Supabase OAuth 브라우저 기반 로그인 사용
      await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'com.watercherry.conquestofkorea://login-callback/',
      );
    }
  }

  /// 카카오 로그인
  Future<AuthResponse> signInWithKakao() async {
    bool isInstalled = await kakao.isKakaoTalkInstalled();
    kakao.OAuthToken token;

    if (isInstalled) {
      token = await kakao.UserApi.instance.loginWithKakaoTalk();
    } else {
      token = await kakao.UserApi.instance.loginWithKakaoAccount();
    }

    // 카카오 로그인 시 ID Token이 없는 경우 처리 (OIDC 미설정 시)
    final idToken = token.idToken;
    if (idToken == null) {
      debugPrint(
        '❌ Kakao ID Token is null. Ensure OIDC is enabled in Kakao Console.',
      );
      throw GameStrings.kakaoOidcRequired;
    }

    debugPrint(
      '🔑 Kakao ID Token found. Audience: ${token.scopes?.contains('openid')}',
    );

    try {
      return await _client.auth.signInWithIdToken(
        provider: OAuthProvider.kakao,
        idToken: idToken,
        accessToken: token.accessToken,
      );
    } catch (e) {
      debugPrint('❌ Supabase Kakao Sign-In Error: $e');
      if (e.toString().contains('audience')) {
        debugPrint(
          '💡 TIP: Check if the Native App Key is registered as Client ID in Supabase Kakao Provider settings.',
        );
      }
      rethrow;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// 사용자 프로필 조회
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// 프로필 업데이트
  Future<void> updateProfile(UserProfile profile) async {
    // 1. profiles 테이블 업데이트
    await _client.from('profiles').upsert(profile.toJson());

    // 2. 이미 점령한 타일들의 색상도 사용자가 지정한 새로운 색상으로 동기화
    try {
      await _client
          .from('captured_tiles')
          .update({'color_hex': profile.colorHex})
          .eq('user_id', profile.id);
      debugPrint('🎨 사용자의 모든 타일 색상이 ${profile.colorHex}로 동기화되었습니다.');
    } catch (e) {
      debugPrint('⚠️ 타일 색상 동기화 중 오류 발생 (무시 가능): $e');
    }
  }

  /// 닉네임 중복 체크
  Future<bool> isNicknameAvailable(String nickname) async {
    final response = await _client
        .from('profiles')
        .select('nickname')
        .eq('nickname', nickname)
        .maybeSingle();

    return response == null;
  }

  /// 이메일 중복 체크 (RPC 호출)
  Future<bool> isEmailAvailable(String email) async {
    try {
      // Supabase RPC 함수 호출
      final bool exists = await _client.rpc(
        'check_email_exists',
        params: {'email_to_check': email},
      );
      return !exists; // 존재하면(true) 사용 불가능(false) 반환
    } catch (e) {
      debugPrint('⚠️ 이메일 중복 체크 중 오류 발생: $e');
      // RPC가 생성되지 않았을 경우를 대비해 기본적으로 true(사용가능)를 반환하거나
      // 사용자에게 설정을 요청하는 에러를 던질 수 있습니다.
      return true;
    }
  }

  /// 프로필 거리 정보 업데이트
  Future<void> updateProfileDistance(
    String userId,
    double totalDistance,
    double dailyDistance,
  ) async {
    await _client.from('profiles').update({
      'total_distance': totalDistance,
      'daily_distance': dailyDistance,
    }).eq('id', userId);
  }
}
