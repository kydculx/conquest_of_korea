import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../core/constants/strings.dart';
import '../core/app_config.dart';

/// Supabase Auth 서비스와 소셜 로그인(구글, 애플) 연동을 총괄하는 인증 관리 서비스 클래스
class AuthService {
  /// Supabase SDK 클라이언트 객체
  final SupabaseClient _client = Supabase.instance.client;

  /// Supabase 클라이언트 인스턴스 게터
  SupabaseClient get client => _client;

  /// 현재 로그인 완료 상태인 사용자(User) 정보를 반환합니다. 비로그인 시 null을 반환합니다.
  User? get currentUser => _client.auth.currentUser;

  /// 사용자 로그인/로그아웃 등 세션 상태 변화를 실시간으로 수신하는 스트림을 제공합니다.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// 신규 에이전트 계정 등록(이메일 가입)과 함께 서비스 약관 동의 내역 및 초기 프로필 정보를 등록합니다.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nickname,
    required String colorHex,
    required DateTime termsAgreedAt,
    required DateTime privacyAgreedAt,
    required DateTime locationAgreedAt,
    DateTime? marketingAgreedAt,
    String teamId = 'none',
    String? mainBaseTileId,
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
    if (response.user != null &&
        response.user!.identities != null &&
        response.user!.identities!.isEmpty) {
      throw AuthException(GameStrings.emailAlreadyInUse, statusCode: '400');
    }

    if (response.user != null) {
      try {
        await _client.from('profiles').upsert({
          'id': response.user!.id,
          'nickname': nickname,
          'color_hex': colorHex,
          // 'team_id': teamId, // DB 컬럼 부재로 임시 주석 처리
          'main_base_tile_id': mainBaseTileId,
          'created_at': DateTime.now().toIso8601String(),
          'terms_agreed_at': termsAgreedAt.toIso8601String(),
          'privacy_agreed_at': privacyAgreedAt.toIso8601String(),
          'location_agreed_at': locationAgreedAt.toIso8601String(),
          'marketing_agreed_at': marketingAgreedAt?.toIso8601String(),
        });
      } catch (e) {
        debugPrint('⚠️ 프로필 테이블 저장 생략 (인증 대기 중일 수 있음): $e');
      }
    }

    return response;
  }

  /// 이메일 주소 및 패스워드를 기반으로 로그인을 비동기 시도합니다.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// 구글 IDP 및 GoogleSignIn 네이티브 SDK를 이용해 구글 계정으로 로그인을 시도합니다.
  Future<void> signInWithGoogle() async {
    try {
      debugPrint('🚀 Native Google Sign In Start...');

      final webClientId = AppConfig.googleWebClientId;

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? AppConfig.googleIosClientId : null,
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('⚠️ Google Sign In cancelled by user');
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) throw GameStrings.idTokenFetchFailed;

      debugPrint('🔑 Native Google Auth Success. ID Token found.');

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

  /// 애플 계정을 활용하여 플랫폼 네이티브 크레덴셜 혹은 Supabase OAuth 웹 인증 로그인을 시도합니다.
  Future<void> signInWithApple() async {
    if (!kIsWeb && Platform.isIOS) {
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
      await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'com.watercherry.conquestofkorea://login-callback/',
      );
    }
  }

  /// 현재 활성화된 세션을 로그아웃 처리하여 종료합니다.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// 특정 사용자 ID에 매핑된 상세 [UserProfile] 객체를 조회하여 반환합니다. 없을 시 null을 반환합니다.
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

  /// 사용자 프로필 정보를 업데이트하고 기 점령 영토의 타일 컬러도 동일 색상으로 동기화 갱신합니다.
  Future<void> updateProfile(UserProfile profile) async {
    await _client.from('profiles').upsert(profile.toUpdateJson());

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

  /// 지정한 닉네임이 다른 사용자들에 의해 이미 점유되어 있는지 가용성 여부를 검사합니다.
  Future<bool> isNicknameAvailable(String nickname) async {
    final response = await _client
        .from('profiles')
        .select('nickname')
        .eq('nickname', nickname)
        .maybeSingle();

    return response == null;
  }

  /// 지정한 이메일 주소가 다른 계정에 의해 이미 점유되어 있는지 가용성 여부를 검사합니다 (RPC 연동).
  Future<bool> isEmailAvailable(String email) async {
    try {
      final bool exists = await _client.rpc(
        'check_email_exists',
        params: {'email_to_check': email},
      );
      return !exists;
    } catch (e) {
      debugPrint('⚠️ 이메일 중복 체크 중 오류 발생: $e');
      return true;
    }
  }

  /// 현재 로그인된 사용자의 프로필과 계정을 영구 삭제(회원 탈퇴)합니다.
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    // 1. 해당 사용자가 점령한 타일 데이터(captured_tiles) 영구 삭제
    try {
      await _client.from('captured_tiles').delete().eq('user_id', user.id);
      debugPrint('🗺️ 탈퇴 회원의 점령 타일 데이터가 정상 삭제되었습니다.');
    } catch (e) {
      debugPrint('⚠️ 점령 타일 삭제 중 오류 발생: $e');
    }

    // [추가] 해당 사용자의 업적 이력(user_achievements) 영구 삭제
    try {
      await _client.from('user_achievements').delete().eq('user_id', user.id);
      debugPrint('🏆 탈퇴 회원의 업적 데이터가 정상 삭제되었습니다.');
    } catch (e) {
      debugPrint('⚠️ 업적 데이터 삭제 중 오류 발생: $e');
    }

    // 2. DB profiles 테이블에서 본인 데이터 삭제 시도
    // (보통 profiles 테이블에 ON DELETE CASCADE 트리거가 설정되어 auth.users까지 연동 소멸되도록 구성됩니다.)
    await _client.from('profiles').delete().eq('id', user.id);

    // 3. 만약을 위해 delete_user_account RPC가 있을 수 있으므로 연계 호출 (에러는 안전하게 무시)
    try {
      await _client.rpc('delete_user_account');
    } catch (e) {
      debugPrint('⚠️ delete_user_account RPC 호출 실패 (대체 트리거 가동 감지): $e');
    }
  }

  /// 플레이어의 본진 이동 횟수를 1 증가시킵니다.
  Future<bool> incrementMainBaseMove(String userId) async {
    try {
      final response = await _client.rpc('increment_main_base_move', params: {'p_user_id': userId});
      return response as bool? ?? false;
    } catch (e) {
      debugPrint('❌ 본진 이동 카운트 증가 실패: $e');
      return false;
    }
  }
}
