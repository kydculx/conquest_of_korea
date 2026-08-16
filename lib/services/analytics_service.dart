import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics를 통한 핵심 통계(앱 설치 및 회원가입)를 추적하는 서비스 클래스
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// 회원가입 완료 이벤트 추적
  /// [method]: 'email', 'google', 'apple', 'kakao' 등
  static Future<void> logSignUp({required String method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      debugPrint('📊 [Analytics] 회원가입 이벤트 기록 완료 (방법: $method)');
    } catch (e) {
      debugPrint('⚠️ [Analytics] logSignUp 에러: $e');
    }
  }

  /// 회원 탈퇴(계정 삭제) 이벤트 추적
  static Future<void> logAccountDelete() async {
    try {
      await _analytics.logEvent(name: 'account_deleted');
      debugPrint('📊 [Analytics] 회원 탈퇴 이벤트 기록 완료');
    } catch (e) {
      debugPrint('⚠️ [Analytics] logAccountDelete 에러: $e');
    }
  }

  /// 로그인된 사용자 ID 연동 (탈퇴/로그아웃 시 null)
  static Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('⚠️ [Analytics] setUserId 에러: $e');
    }
  }
}
