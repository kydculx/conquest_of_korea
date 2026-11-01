import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

/// 랭킹 카테고리 지표 타입을 관리하기 위한 상수 정의 클래스
class RankingType {
  /// 점령 영토 수 기준 랭킹 키
  static const String capturedTiles = 'captured_tiles_count';

  /// 일일 타일 이동 횟수 기준 랭킹 키
  static const String dailyMovedTiles = 'daily_moved_tiles_count';

  /// 누적 타일 이동 횟수 기준 랭킹 키
  static const String totalMovedTiles = 'total_moved_tiles_count';
}

/// 플레이어들의 랭킹 상태 및 내 순위를 로딩하고 관리하는 상태 관리 프로바이더 클래스
class RankingProvider extends ChangeNotifier {
  final SupabaseService _supabase;
  AuthProvider? _authProvider;
  String? _loadedUserId;

  // --- 상태 필드 ---
  final Map<String, List<UserProfile>> _rankingsByType = {};
  final Map<String, int> _myRankingByType = {};
  final Set<String> _loadingTypes = {};
  String _currentType = RankingType.capturedTiles;

  // --- Getters ---
  /// 현재 선택된 타입의 상위 100위까지의 플레이어 프로필 목록
  List<UserProfile> get topRankings => topRankingsFor(_currentType);

  /// 지정한 타입의 상위 100위까지의 플레이어 프로필 목록
  List<UserProfile> topRankingsFor(String type) =>
      List.unmodifiable(_rankingsByType[type] ?? const <UserProfile>[]);

  /// 현재 선택된 타입의 내 전체 랭킹 순위
  int get myRanking => myRankingFor(_currentType);

  /// 지정한 타입의 내 전체 랭킹 순위
  int myRankingFor(String type) => _myRankingByType[type] ?? 0;

  /// 현재 선택된 타입의 랭킹 조회 진행 중 여부
  bool get isLoading => isLoadingFor(_currentType);

  /// 지정한 타입의 랭킹 조회 진행 중 여부
  bool isLoadingFor(String type) => _loadingTypes.contains(type);

  /// 현재 적용 중인 랭킹 기준 지표 타입
  String get currentType => _currentType;

  /// RankingProvider 생성자로 Supabase API 의존성을 주입받습니다.
  RankingProvider({required SupabaseService supabase}) : _supabase = supabase;

  /// AuthProvider 인증 참조 상태를 주입하고, 로그인 세션 전환 시 랭킹 데이터를 실시간 자동 갱신합니다.
  void setAuthProvider(AuthProvider auth) {
    _authProvider = auth;
    final userId = auth.profile?.id;

    if (userId == _loadedUserId) return;

    _loadedUserId = userId;
    _rankingsByType.clear();
    _myRankingByType.clear();
    _loadingTypes.clear();

    if (userId != null) {
      loadRankings(type: _currentType, force: true);
    } else {
      notifyListeners();
    }
  }

  /// 지정한 랭킹 타입 기준으로 상위 100위 목록과 로그인된 내 랭킹을 서버로부터 병렬 비동기 동기화합니다.
  /// [select]가 false이면 현재 선택 타입을 바꾸지 않고 백그라운드로 미리 로드합니다.
  Future<void> loadRankings({
    String? type,
    bool force = false,
    bool select = true,
  }) async {
    final targetType = type ?? _currentType;
    if (select) {
      _currentType = targetType;
    }

    if (!force && _rankingsByType.containsKey(targetType)) {
      notifyListeners();
      return;
    }
    if (_loadingTypes.contains(targetType)) {
      if (select) notifyListeners();
      return;
    }

    final requestUserId = _loadedUserId;
    _loadingTypes.add(targetType);
    notifyListeners();

    try {
      // 1. 상위 100위 리스트 조회 비동기 시작
      final topRankingsFuture = _supabase.fetchTopRankings(targetType);

      // 2. 내 순위 조회 비동기 설정
      Future<int> myRankingFuture = Future.value(0);
      final profile = _authProvider?.profile;
      final userId = _authProvider?.user?.id;

      if (profile != null && userId != null) {
        double myValue = 0.0;
        if (targetType == RankingType.capturedTiles) {
          myValue = profile.capturedTilesCount.toDouble();
        } else if (targetType == RankingType.dailyMovedTiles) {
          myValue = profile.dailyMovedTilesCount.toDouble();
        } else if (targetType == RankingType.totalMovedTiles) {
          myValue = profile.totalMovedTilesCount.toDouble();
        }
        // 기록값이 0 이하이면 순위를 부여하지 않음 (번호 미표시)
        if (myValue > 0) {
          myRankingFuture = _supabase.fetchMyRanking(
            userId,
            targetType,
            myValue,
          );
        }
      }

      // 3. 두 쿼리를 병렬 수행하여 대기 지연 최소화
      final results = await Future.wait([topRankingsFuture, myRankingFuture]);
      if (requestUserId != _loadedUserId) return;

      _rankingsByType[targetType] = results[0] as List<UserProfile>;
      _myRankingByType[targetType] = results[1] as int;
    } catch (e) {
      debugPrint('❌ 랭킹 프로바이더 동기화 중 오류 발생: $e');
    } finally {
      if (requestUserId == _loadedUserId) {
        _loadingTypes.remove(targetType);
        notifyListeners();
      }
    }
  }
}
