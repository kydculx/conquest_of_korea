import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  /// 중복 로그인 방지를 위한 로컬 세션 고유 식별자
  late String _localSessionId;

  /// 중복 로그인 발생으로 인해 강제 로그아웃되었는지 여부
  bool _isDuplicateLoggedOut = false;

  /// profiles 테이블 실시간 감지용 스트림 구독 객체
  StreamSubscription<List<Map<String, dynamic>>>? _profileSubscription;

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

  /// 로컬 세션 ID 게터
  String get localSessionId => _localSessionId;

  /// 중복 로그인 감지 플래그 게터
  bool get isDuplicateLoggedOut => _isDuplicateLoggedOut;

  /// AuthProvider 생성자로, 앱 구동 시 내부 초기화 과정을 수행합니다.
  AuthProvider() {
    _localSessionId = _generateSessionId();
    _init();
  }

  /// 고유 세션 ID 생성
  String _generateSessionId() {
    final rand = Random().nextInt(999999);
    return '${DateTime.now().millisecondsSinceEpoch}_$rand';
  }

  /// 초기 사용자의 인증 정보 및 세션 변경 흐름을 모니터링하기 위한 리스너를 바인딩합니다.
  void _init() {
    _user = _authService.currentUser;
    if (_user != null) {
      _loadProfile(_user!.id, isAppStart: true);
      _updateSessionIdInDatabase(_user!.id);
      _subscribeProfileRealtime(_user!.id);
    }

    _authService.authStateChanges.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      _user = session?.user;

      if (event == AuthChangeEvent.signedIn && _user != null) {
        _isDuplicateLoggedOut = false;
        _updateSessionIdInDatabase(_user!.id).then((_) {
          _loadProfile(_user!.id);
          _subscribeProfileRealtime(_user!.id);
        });
        _notificationService.setCurrentUserId(_user!.id);
        _notificationService.subscribeToTopic('user_${_user!.id}');
      } else if (event == AuthChangeEvent.signedOut) {
        _profileSubscription?.cancel();
        _profileSubscription = null;
        _notificationService.setCurrentUserId(null);
        if (_user != null) {
          _notificationService.unsubscribeFromTopic('user_${_user!.id}');
        }
        _profile = null;
      }

      notifyListeners();
    });
  }

  /// DB profiles 테이블의 last_session_id 필드를 로컬 세션 ID로 업데이트합니다.
  Future<void> _updateSessionIdInDatabase(String userId) async {
    _localSessionId = _generateSessionId();
    
    // Supabase Auth 토큰이 HTTP 클라이언트 헤더에 완전히 동기화되도록 미세한 지연을 가집니다.
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final response = await _authService.client
          .from('profiles')
          .update({'last_session_id': _localSessionId})
          .eq('id', userId)
          .select();
      debugPrint('🔑 로컬 세션 ID ($_localSessionId) DB 갱신 성공: $response');
    } catch (e) {
      debugPrint('❌ DB last_session_id 갱신 에러: $e');
    }
  }

  /// profiles 테이블의 변화를 실시간으로 리스닝하여 중복 로그인을 체크합니다.
  void _subscribeProfileRealtime(String userId) {
    _profileSubscription?.cancel();
    
    // 첫 번째 이벤트는 DB의 기존 상태(구독 시점의 캐시 데이터)이므로 비교를 스킵합니다.
    bool isFirstEvent = true;

    _profileSubscription = _authService.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen((data) {
          if (data.isNotEmpty) {
            final updatedProfile = UserProfile.fromJson(data.first);
            final serverSessionId = updatedProfile.lastSessionId;

            if (isFirstEvent) {
              isFirstEvent = false;
              debugPrint('ℹ️ 실시간 세션 감시 시작 (최초 세션 ID: $serverSessionId)');
              return;
            }

            // 서버 세션 ID가 존재하고, 로컬 세션 ID와 다른 경우 중복 로그인 발생
            if (serverSessionId != null && serverSessionId != _localSessionId) {
              _handleDuplicateLogin();
            }
          }
        }, onError: (e) {
          debugPrint('⚠️ 프로필 실시간 구독 에러 (무시 가능): $e');
        });
  }

  /// 중복 로그인 감지 시 로그아웃 및 상태 초기화를 진행합니다.
  Future<void> _handleDuplicateLogin() async {
    debugPrint('🚨 중복 로그인 감지 - 접속을 종료합니다.');
    _isDuplicateLoggedOut = true;

    _profileSubscription?.cancel();
    _profileSubscription = null;

    await signOut();
    notifyListeners();
  }

  /// 중복 로그인 플래그를 초기화합니다.
  void clearDuplicateLogoutFlag() {
    _isDuplicateLoggedOut = false;
    notifyListeners();
  }

  /// 특정 사용자 ID를 기반으로 DB 프로필 정보를 로드하고 FCM 알림 토픽에 등록합니다.
  Future<void> _loadProfile(String userId, {bool isAppStart = false}) async {
    _setLoading(true);
    try {
      _profile = await _authService.getUserProfile(userId);

      // 프로필 로드 시 개인 토픽 구독 (중복 구독은 FCM 내부적으로 처리됨)
      _notificationService.setCurrentUserId(userId);
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
    _isDuplicateLoggedOut = false;
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
      _notificationService.setCurrentUserId(null);
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
      final updatedProfile = _profile!.copyWith(
        colorHex: newColorHex,
        lastSessionId: _localSessionId,
      );
      await _authService.updateProfile(updatedProfile);
      _profile = updatedProfile;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// 4대 알림 수신 동의 상태 일괄 업데이트
  Future<void> updateGranularNotifications({
    required bool isMasterEnabled,
    required bool territoryAttack,
    required bool satelliteComplete,
    required bool systemNotice,
  }) async {
    if (_profile == null) return;

    _setLoading(true);
    try {
      final updatedProfile = _profile!.copyWith(
        isNotificationsEnabled: isMasterEnabled,
        notifTerritoryAttack: territoryAttack,
        notifSatelliteComplete: satelliteComplete,
        notifSystemNotice: systemNotice,
        lastSessionId: _localSessionId,
      );
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
      final updatedProfile = _profile!.copyWith(
        mainBaseTileId: tileId,
        lastSessionId: _localSessionId,
      );
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
