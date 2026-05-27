import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart'
    show KakaoSdk;
import '../core/utils/error_translator.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../models/user_profile.dart';

/// 사용자 인증 상태와 프로필 데이터의 수명 주기를 관리하고 UI 레이어에 이벤트를 전파하는 인증 프로바이더 클래스
class AuthProvider extends ChangeNotifier {
  /// 인증 업무 처리를 담당하는 내부 인증 서비스
  final AuthService _authService = AuthService();

  /// 푸시 알림 Topic 구독 관리를 담당하는 내부 알림 서비스
  final NotificationService _notificationService = NotificationService();

  /// Supabase Auth 세션의 현재 사용자 정보
  User? _user;

  /// 사용자 정보 테이블(user_profiles)의 프로필 상세 모델
  UserProfile? _profile;

  /// API 통신 및 데이터 처리 중 여부를 나타내는 로딩 상태값
  bool _isLoading = false;

  /// 최근 발생한 에러 메시지
  String? _error;

  /// 현재 로그인된 Supabase User 객체를 반환합니다.
  User? get user => _user;

  /// 현재 사용자의 요원 프로필 상세 정보를 반환합니다.
  UserProfile? get profile => _profile;

  /// 현재 작업이 진행 중(로딩)인지 여부를 반환합니다.
  bool get isLoading => _isLoading;

  /// 가장 최근에 발생한 인증 관련 에러 메시지를 반환합니다.
  String? get error => _error;

  /// 사용자가 로그인되어 세션이 활성화된 상태인지 여부를 반환합니다.
  bool get isAuthenticated => _user != null;

  /// AuthProvider 생성자로, 앱 구동 시 내부 초기화 과정을 수행합니다.
  AuthProvider() {
    _init();
  }

  /// 초기 사용자의 인증 정보 및 세션 변경 흐름을 모니터링하기 위한 리스너를 바인딩합니다.
  void _init() {
    _user = _authService.currentUser;
    if (_user != null) {
      _loadProfile(_user!.id, isAppStart: true);
    }

    _authService.authStateChanges.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      _user = session?.user;

      if (event == AuthChangeEvent.signedIn && _user != null) {
        _loadProfile(_user!.id);
        _notificationService.subscribeToTopic('user_${_user!.id}');
      } else if (event == AuthChangeEvent.signedOut) {
        if (_user != null) {
          _notificationService.unsubscribeFromTopic('user_${_user!.id}');
        }
        _profile = null;
      }

      notifyListeners();
    });
  }

  /// 특정 사용자 ID를 기반으로 DB 프로필 정보를 로드하고 FCM 알림 토픽에 등록합니다.
  Future<void> _loadProfile(String userId, {bool isAppStart = false}) async {
    _setLoading(true);
    try {
      _profile = await _authService.getUserProfile(userId);

      // 프로필 로드 시 개인 토픽 구독 (중복 구독은 FCM 내부적으로 처리됨)
      _notificationService.subscribeToTopic('user_$userId');

      // 만약 프로필이 없다면 (가입 시 권한 문제로 저장이 안 된 경우 등)
      if (_profile == null && _user != null) {
        final metadata = _user!.userMetadata;
        if (metadata != null && metadata.containsKey('nickname')) {
          debugPrint('ℹ️ 누락된 프로필 자동 생성 중...');
          final now = DateTime.now();
          await createProfile(
            nickname: metadata['nickname'] as String,
            colorHex: (metadata['color_hex'] as String?) ?? '#FFFFFF',
            termsAgreedAt: now,
            privacyAgreedAt: now,
            locationAgreedAt: now,
          );
        } else if (isAppStart) {
          debugPrint('⚠️ 불완전한 소셜 가입 세션 감지 (앱 기동 단계): 로그아웃 처리합니다.');
          await signOut();
        }
      }
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 회원가입
  Future<void> signUp({
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
    _setLoading(true);
    try {
      await _authService.signUp(
        email: email,
        password: password,
        nickname: nickname,
        colorHex: colorHex,
        termsAgreedAt: termsAgreedAt,
        privacyAgreedAt: privacyAgreedAt,
        locationAgreedAt: locationAgreedAt,
        marketingAgreedAt: marketingAgreedAt,
        teamId: teamId,
        mainBaseTileId: mainBaseTileId,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// 로그인
  Future<void> signIn({required String email, required String password}) async {
    _setLoading(true);
    try {
      await _authService.signIn(email: email, password: password);
    } finally {
      _setLoading(false);
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    if (_user != null) {
      await _notificationService.unsubscribeFromTopic('user_${_user!.id}');
    }
    await _authService.signOut();
  }

  /// 구글 로그인
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      await _authService.signInWithGoogle();
      // 브라우저 로그인은 authStateChanges 리스너에서 세션 변화를 감지하여
      // 자동으로 프로필을 로드하고 UI를 갱신합니다.
    } catch (e) {
      debugPrint('❌ Google Login Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 애플 로그인
  Future<void> signInWithApple() async {
    _setLoading(true);
    try {
      await _authService.signInWithApple();
    } catch (e) {
      debugPrint('❌ Apple Login Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 카카오 로그인
  Future<void> signInWithKakao() async {
    _setLoading(true);
    _error = null;

    try {
      // 실제 앱에서 사용하는 키 해시 로그 출력 (디버깅용)
      final keyHash = await KakaoSdk.origin;
      debugPrint('🔑 실제 카카오 키 해시: $keyHash');

      final response = await _authService.signInWithKakao();
      if (response.user != null) {
        _user = response.user;
        await _loadProfile(_user!.id);
      }
    } catch (e) {
      _error = ErrorTranslator.translate(e);
      debugPrint('❌ 카카오 로그인 에러 상세: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 프로필 수동 생성 (SNS 최초 로그인용)
  Future<void> createProfile({
    required String nickname,
    required String colorHex,
    required DateTime termsAgreedAt,
    required DateTime privacyAgreedAt,
    required DateTime locationAgreedAt,
    DateTime? marketingAgreedAt,
    String teamId = 'none',
    String? mainBaseTileId,
  }) async {
    if (_user == null) return;

    _setLoading(true);
    try {
      final newProfile = UserProfile(
        id: _user!.id,
        nickname: nickname,
        colorHex: colorHex,
        teamId: teamId,
        mainBaseTileId: mainBaseTileId,
        termsAgreedAt: termsAgreedAt,
        privacyAgreedAt: privacyAgreedAt,
        locationAgreedAt: locationAgreedAt,
        marketingAgreedAt: marketingAgreedAt,
        createdAt: DateTime.now(),
      );
      await _authService.updateProfile(newProfile);
      _profile = newProfile;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// 프로필 색상 업데이트
  Future<void> updateProfileColor(String newColorHex) async {
    if (_profile == null) return;

    _setLoading(true);
    try {
      final updatedProfile = _profile!.copyWith(colorHex: newColorHex);
      await _authService.updateProfile(updatedProfile);
      _profile = updatedProfile;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// 메인 기지 설정/재설정
  Future<void> updateMainBase(String tileId) async {
    if (_profile == null) return;

    _setLoading(true);
    try {
      final updatedProfile = _profile!.copyWith(mainBaseTileId: tileId);
      await _authService.updateProfile(updatedProfile);
      _profile = updatedProfile;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// 닉네임 중복 체크
  Future<bool> isNicknameAvailable(String nickname) async {
    return await _authService.isNicknameAvailable(nickname);
  }

  /// 이메일 중복 체크
  Future<bool> isEmailAvailable(String email) async {
    return await _authService.isEmailAvailable(email);
  }

  /// 프로필 정보를 서버로부터 강제로 다시 로드하여 동기화합니다.
  Future<void> refreshProfile() async {
    if (_user != null) {
      await _loadProfile(_user!.id);
    }
  }

  /// 내부 로딩 상태를 설정하고 리스너들에게 상태 변경을 알립니다.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// 계정 영구 삭제 (회원 탈퇴) 프로세스를 총괄 조율합니다.
  Future<void> deleteAccount() async {
    if (_user == null) return;
    _setLoading(true);
    try {
      // 1. FCM 토픽 구독 해제
      await _notificationService.unsubscribeFromTopic('user_${_user!.id}');
      // 2. 백엔드 회원 정보 영구 삭제 호출
      await _authService.deleteAccount();
      // 3. 로컬 로그아웃 및 상태 전면 초기화
      await _authService.signOut();
      _user = null;
      _profile = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
}
