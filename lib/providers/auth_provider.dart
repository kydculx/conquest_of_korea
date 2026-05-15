import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' show KakaoSdk;
import '../core/utils/error_translator.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  
  User? _user;
  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = _authService.currentUser;
    if (_user != null) {
      _loadProfile(_user!.id);
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

  Future<void> _loadProfile(String userId) async {
    _profile = await _authService.getUserProfile(userId);
    
    // 프로필 로드 시 개인 토픽 구독 (중복 구독은 FCM 내부적으로 처리됨)
    _notificationService.subscribeToTopic('user_$userId');
    
    // 만약 프로필이 없다면 (가입 시 권한 문제로 저장이 안 된 경우 등)
    if (_profile == null && _user != null) {
      final metadata = _user!.userMetadata;
      if (metadata != null && metadata.containsKey('nickname')) {
        debugPrint('ℹ️ 누락된 프로필 자동 생성 중...');
        await createProfile(
          nickname: metadata['nickname'] as String,
          colorHex: (metadata['color_hex'] as String?) ?? '#FFFFFF',
        );
      }
    }
    notifyListeners();
  }

  /// 회원가입
  Future<void> signUp({
    required String email,
    required String password,
    required String nickname,
    required String colorHex,
    String teamId = 'none',
  }) async {
    _setLoading(true);
    try {
      await _authService.signUp(
        email: email,
        password: password,
        nickname: nickname,
        colorHex: colorHex,
        teamId: teamId,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// 로그인
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
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
      final response = await _authService.signInWithGoogle();
      if (response.user != null) {
        _user = response.user;
        await _loadProfile(_user!.id);
      }
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
    String teamId = 'none',
  }) async {
    if (_user == null) return;
    
    _setLoading(true);
    try {
      final newProfile = UserProfile(
        id: _user!.id,
        nickname: nickname,
        colorHex: colorHex,
        teamId: teamId,
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

  /// 닉네임 중복 체크
  Future<bool> isNicknameAvailable(String nickname) async {
    return await _authService.isNicknameAvailable(nickname);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
