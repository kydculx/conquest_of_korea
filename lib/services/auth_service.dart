import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

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

    // 가입 성공 시 profiles 테이블에 추가 데이터 저장
    if (response.user != null) {
      try {
        await _client.from('profiles').upsert({
          'id': response.user!.id,
          'nickname': nickname,
          'color_hex': colorHex,
          // 'team_id': teamId, // DB 컬럼 부재로 임시 주석 처리
          'created_at': DateTime.now().toIso8601String(),
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

  /// 구글 로그인
  Future<AuthResponse> signInWithGoogle() async {
    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']; 
    final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID']; 

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: Platform.isIOS ? iosClientId : null,
      serverClientId: webClientId,
    );
    
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw 'Google sign in aborted';

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (idToken == null) throw 'No ID Token found.';
    if (accessToken == null) throw 'No Access Token found.';

    return await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
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

    return await _client.auth.signInWithIdToken(
      provider: OAuthProvider.kakao,
      idToken: token.idToken!, // Supabase Kakao 연동 설정 필요
      accessToken: token.accessToken,
    );
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
      await _client.from('captured_tiles').update({
        'color_hex': profile.colorHex,
      }).eq('user_id', profile.id);
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
}
