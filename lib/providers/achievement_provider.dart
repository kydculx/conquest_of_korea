import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../models/achievement_model.dart';
import '../models/tile_model.dart';
import '../services/supabase_service.dart';
import '../services/hex_service.dart';
import 'auth_provider.dart';

/// 플레이어의 상태 정보를 주기적으로 판정하여 실시간으로 업적 해금을 보장하고 이력을 보관하는 프로바이더 클래스
class AchievementProvider extends ChangeNotifier {
  final SupabaseService _supabase;
  AuthProvider? _authProvider;
  String? _currentUserId;

  List<String> _unlockedAchievementIds = [];
  bool _isLoading = false;

  /// 최근 해금된 업적 정보를 실시간 중계하는 브로드캐스트 스트림
  final StreamController<Achievement> _unlockStreamController =
      StreamController<Achievement>.broadcast();
  Stream<Achievement> get onAchievementUnlocked => _unlockStreamController.stream;

  /// 해금 완료된 업적 ID 목록 반환
  List<String> get unlockedAchievementIds => List.unmodifiable(_unlockedAchievementIds);

  /// 업적 데이터베이스 로딩 여부
  bool get isLoading => _isLoading;

  /// AchievementProvider 생성자로 Supabase API 의존성을 주입받습니다.
  AchievementProvider({required SupabaseService supabase}) : _supabase = supabase;

  @override
  void dispose() {
    _unlockStreamController.close();
    super.dispose();
  }

  /// AuthProvider 의존성을 바인딩하며 로그인 상태에 맞춰 플레이어의 해금 업적 데이터를 연동합니다.
  void setAuthProvider(AuthProvider auth) {
    _authProvider = auth;
    if (auth.isAuthenticated && auth.profile != null) {
      final String newUserId = auth.profile!.id;
      // 인스턴스 참조가 아닌 실제 로그인된 유저 ID 변경 감지 방식으로 교정하여 프로필 갱신 완료 시의 로딩을 누락 없이 보장
      if (_currentUserId != newUserId) {
        _currentUserId = newUserId;
        _loadUnlockedAchievements(newUserId);
      }
    } else {
      if (_currentUserId != null) {
        _currentUserId = null;
        _unlockedAchievementIds = [];
        notifyListeners();
      }
    }
  }

  /// 원격 데이터베이스로부터 획득 완료한 업적 목록을 조회하여 로컬 메모리에 동기화합니다.
  Future<void> _loadUnlockedAchievements(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _unlockedAchievementIds = await _supabase.fetchUserAchievements(userId);
    } catch (e) {
      debugPrint('⚠️ 해금 업적 조회 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      // 기존 획득 업적 목록 조회가 끝난 직후, 이미 조건을 만족했으나 미등록 상태인 업적이 있다면 자가 즉시 판정/해금
      checkAndUnlock();
    }
  }

  /// 본부 기지(HQ)를 중심으로 1~4링(완전 점령) 구역의 요새화 도달 단계를 판정하여 반환합니다.
  int getHQFortificationLevel(
    String? hqTileId,
    String userId,
    Map<String, HexTile> capturedTiles,
  ) {
    if (hqTileId == null || hqTileId.isEmpty) return 0;
    final parsed = HexService.parseTileId(hqTileId);
    if (parsed == null) return 0;
    final int qCenter = parsed['q'];
    final int rCenter = parsed['r'];

    int maxRing = 0;
    // 1링부터 최대 4링까지 순차적으로 검증
    for (int k = 1; k <= 4; k++) {
      bool isAllMine = true;
      for (int q = -k; q <= k; q++) {
        final int rMin = math.max(-k, -q - k);
        final int rMax = math.min(k, -q + k);
        for (int r = rMin; r <= rMax; r++) {
          final targetQ = qCenter + q;
          final targetR = rCenter + r;
          final String tid = HexService.tileId(targetQ, targetR);
          final tile = capturedTiles[tid];
          if (tile == null || tile.userId != userId) {
            isAllMine = false;
            break;
          }
        }
        if (!isAllMine) break;
      }
      if (isAllMine) {
        maxRing = k;
      } else {
        break; // 내부 링이 뚫리면 외부 링 판정은 무의미하므로 즉시 종료
      }
    }
    return maxRing;
  }

  /// 플레이어의 최신 프로필 상태 및 실시간 점령 타일 데이터를 기준으로 미획득 업적의 임계값 충족 여부를 일괄 판정합니다.
  Future<void> checkAndUnlock({
    Map<String, HexTile>? capturedTiles,
  }) async {
    final profile = _authProvider?.profile;
    final userId = _authProvider?.user?.id;
    if (profile == null || userId == null || _isLoading) return;

    // 미획득 업적 목록만 추려 판정 대상 설정
    final List<Achievement> pending = Achievement.masterAchievements
        .where((a) => !_unlockedAchievementIds.contains(a.id))
        .toList();

    if (pending.isEmpty) return;

    // 본부 요새화 레벨 1회 한정 연산 (타일 정보가 넘어왔을 때만 연산 가동)
    final hqLevel = capturedTiles != null
        ? getHQFortificationLevel(profile.mainBaseTileId, userId, capturedTiles)
        : 0;

    for (final ach in pending) {
      bool shouldUnlock = false;

      switch (ach.category) {
        case AchievementCategory.capturedTiles:
          shouldUnlock = profile.capturedTilesCount >= ach.threshold;
          break;
        case AchievementCategory.enemyCapturedTiles:
          shouldUnlock = profile.enemyCapturedTilesCount >= ach.threshold;
          break;
        case AchievementCategory.totalMovedTiles:
          shouldUnlock = profile.totalMovedTilesCount >= ach.threshold;
          break;
        case AchievementCategory.dailyMovedTiles:
          shouldUnlock = profile.dailyMovedTilesCount >= ach.threshold;
          break;
        case AchievementCategory.satelliteCapture:
          shouldUnlock = profile.satelliteCaptureCount >= ach.threshold;
          break;
        case AchievementCategory.satelliteInfo:
          shouldUnlock = profile.satelliteScanCount >= ach.threshold;
          break;
        case AchievementCategory.hqFortification:
          // 타일 정보가 넘어왔을 때만 본부 요새화 링 판정을 가동
          if (capturedTiles != null) {
            shouldUnlock = hqLevel >= ach.threshold;
          }
          break;
        case AchievementCategory.goldAmount:
          shouldUnlock = profile.gold >= ach.threshold;
          break;
        case AchievementCategory.mainBaseMove:
          shouldUnlock = profile.mainBaseMoveCount >= ach.threshold;
          break;
      }

      if (shouldUnlock) {
        // 백엔드 데이터 동기화 시도
        final success = await _supabase.unlockAchievement(userId, ach.id);
        if (success) {
          _unlockedAchievementIds.add(ach.id);
          _unlockStreamController.add(ach); // 해금 완료 이벤트 중계
          notifyListeners();
        }
      }
    }
  }
}
