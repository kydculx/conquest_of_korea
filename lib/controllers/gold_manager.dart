import 'dart:async';
import 'package:flutter/foundation.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../core/constants/game_config.dart';

/// 골드 재화의 상태, 타이머, 서버 동기화 및 영속화를 전담 관리하는 매니저 클래스.
/// GameProvider로부터 골드 관련 책임을 분리합니다.
class GoldManager {
  final SupabaseService _supabase;
  final AuthProvider? Function() _getAuthProvider;
  final VoidCallback _notifyListeners;

  double _currentGold = 0.0;
  double _goldRate = GameConfig.defaultGoldRate;
  Timer? _goldTimer;
  int _syncCounter = 0;

  /// 현재 보유 중인 골드 재화 잔액
  double get currentGold => _currentGold;

  /// 초당 골드 생산율
  double get goldRate => _goldRate;

  /// 골드 타이머 활성화 여부
  bool get isTimerActive => _goldTimer != null && _goldTimer!.isActive;

  GoldManager({
    required SupabaseService supabase,
    required AuthProvider? Function() getAuthProvider,
    required VoidCallback notifyListeners,
  })  : _supabase = supabase,
        _getAuthProvider = getAuthProvider,
        _notifyListeners = notifyListeners;

  AuthProvider? get _auth => _getAuthProvider();

  // --- 공개 API ---

  /// 로그아웃 시 골드 상태 초기화
  void reset() {
    _goldTimer?.cancel();
    _goldTimer = null;
    _currentGold = 0.0;
  }

  /// 골드 값을 직접 설정 (롤백 등)
  void setGold(double value) {
    _currentGold = value;
  }

  /// 낙관적 업데이트용 골드 차감 (UI 즉시 반영)
  double deductOptimistic(double amount) {
    _currentGold = (_currentGold - amount).clamp(0.0, double.infinity);
    return _currentGold;
  }

  /// 서버에 골드 업데이트 (profiles 테이블)
  Future<void> persistGoldUpdate(double gold, DateTime now, String userId) async {
    await _supabase.client.from('profiles').update({
      'gold': gold,
      'last_gold_updated_at': now.toUtc().toIso8601String(),
    }).eq('id', userId);
  }

  /// 골드 타이머 중지
  void stopTimer() {
    _goldTimer?.cancel();
    _goldTimer = null;
  }

  /// 서버와 골드 동기화 (오프라인 골드 정산 + 타이머 재시작)
  Future<void> syncWithServer() async {
    final auth = _auth;
    if (auth == null || !auth.isAuthenticated || auth.profile == null) return;

    try {
      final rate = await _supabase.fetchGoldRate();
      _goldRate = rate ?? GameConfig.defaultGoldRate;

      await auth.refreshProfile();
      final profile = auth.profile;
      if (profile != null) {
        final now = DateTime.now().toUtc();
        final lastUpdated = profile.lastGoldUpdatedAt ?? now;
        final diffSeconds = now.difference(lastUpdated).inSeconds;
        final elapsed = diffSeconds > 0 ? diffSeconds : 0;

        final myMainBaseId = profile.mainBaseTileId;
        int effectiveTilesCount = profile.capturedTilesCount;
        if (myMainBaseId != null && myMainBaseId.isNotEmpty) {
          if (effectiveTilesCount < 1) effectiveTilesCount = 1;
        }

        final double offlineGold =
            elapsed * effectiveTilesCount * (_goldRate / 3600.0);

        if (offlineGold > 0.0) {
          final newGold = profile.gold + offlineGold;
          await _supabase.client.from('profiles').update({
            'gold': newGold,
            'last_gold_updated_at': now.toIso8601String(),
          }).eq('id', profile.id);
          await auth.refreshProfile();
        }

        final updatedProfile = auth.profile ?? profile;
        _currentGold = updatedProfile.gold.toDouble();

        if (!isTimerActive) {
          _startTimer();
        }
      }
    } catch (e) {
      debugPrint('❌ 골드 동기화 실패: $e');
    }
    _notifyListeners();
  }

  /// 현재 골드를 서버에 영속화 (앱 lifecyle pause 시)
  Future<void> persistToServer() async {
    final auth = _auth;
    if (auth == null || !auth.isAuthenticated || auth.profile == null) return;

    try {
      final profile = auth.profile!;
      final now = DateTime.now().toUtc();
      await _supabase.client.from('profiles').update({
        'gold': _currentGold,
        'last_gold_updated_at': now.toIso8601String(),
      }).eq('id', profile.id);
      await auth.refreshProfile();
    } catch (e) {
      debugPrint('❌ 골드 정밀 서버 영속화 실패: $e');
    }
  }

  /// 리소스 해제
  void dispose() {
    _goldTimer?.cancel();
  }

  // --- 내부 메서드 ---

  /// 1초 주기 골드 누적 타이머 시작
  void _startTimer() {
    _goldTimer?.cancel();
    _syncCounter = 0;
    _goldTimer = Timer.periodic(
      const Duration(seconds: GameConfig.goldTimerIntervalSeconds),
      (timer) async {
      final auth = _auth;
      if (auth == null || !auth.isAuthenticated || auth.profile == null) {
        timer.cancel();
        return;
      }
      final profile = auth.profile!;

      final myMainBaseId = profile.mainBaseTileId;
      int effectiveTilesCount = profile.capturedTilesCount;
      if (myMainBaseId != null && myMainBaseId.isNotEmpty) {
        if (effectiveTilesCount < 1) effectiveTilesCount = 1;
      }

      final double earnedGoldPerSecond =
          effectiveTilesCount * (_goldRate / 3600.0);
      _currentGold += earnedGoldPerSecond;
      _notifyListeners();

      _syncCounter++;
      if (_syncCounter >= 10) {
        _syncCounter = 0;
        await persistToServer();
      }
    });
  }
}
