import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

/// 랭킹 카테고리 지표 타입을 관리하기 위한 상수 정의 클래스
class RankingType {
  /// 점령 영토 수 기준 랭킹 키
  static const String capturedTiles = 'captured_tiles_count';
}

/// 요원들의 전술적 랭킹 상태 및 내 순위를 로딩하고 관리하는 상태 관리 프로바이더 클래스
class RankingProvider extends ChangeNotifier {
  final SupabaseService _supabase;
  AuthProvider? _authProvider;

  // --- 상태 필드 ---
  List<UserProfile> _topRankings = [];
  int _myRanking = 0;
  bool _isLoading = false;
  String _currentType = RankingType.capturedTiles;

  // --- Getters ---
  /// 상위 100위까지의 요원 프로필 목록
  List<UserProfile> get topRankings => List.unmodifiable(_topRankings);

  /// 현재 인증된 요원의 전체 랭킹 순위
  int get myRanking => _myRanking;

  /// 랭킹 정보 조회 진행 중 여부
  bool get isLoading => _isLoading;

  /// 현재 적용 중인 랭킹 기준 지표 타입
  String get currentType => _currentType;

  /// RankingProvider 생성자로 Supabase API 의존성을 주입받습니다.
  RankingProvider({required SupabaseService supabase}) : _supabase = supabase;

  /// AuthProvider 인증 참조 상태를 주입하고, 로그인 세션 전환 시 랭킹 데이터를 실시간 자동 갱신합니다.
  void setAuthProvider(AuthProvider auth) {
    if (_authProvider != auth) {
      _authProvider = auth;
      if (auth.isAuthenticated && auth.profile != null) {
        // 최초 의존성 바인딩 완료 시 첫 랭킹 목록 자동 로드 트리거
        loadRankings(type: _currentType);
      }
    }
  }

  /// 지정한 랭킹 타입 기준으로 상위 100위 목록과 로그인된 내 랭킹을 서버로부터 병렬 비동기 동기화합니다.
  Future<void> loadRankings({String? type}) async {
    if (type != null) {
      _currentType = type;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 1. 상위 100위 리스트 조회 비동기 시작
      final topRankingsFuture = _supabase.fetchTopRankings(_currentType);

      // 2. 내 순위 조회 비동기 설정
      Future<int> myRankingFuture = Future.value(0);
      final profile = _authProvider?.profile;
      final userId = _authProvider?.user?.id;

      if (profile != null && userId != null) {
        final double myValue = profile.capturedTilesCount.toDouble();
        myRankingFuture = _supabase.fetchMyRanking(
          userId,
          _currentType,
          myValue,
        );
      }

      // 3. 두 쿼리를 병렬 수행하여 대기 지연 최소화
      final results = await Future.wait([topRankingsFuture, myRankingFuture]);

      _topRankings = results[0] as List<UserProfile>;
      _myRanking = results[1] as int;
    } catch (e) {
      debugPrint('❌ 랭킹 프로바이더 동기화 중 오류 발생: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
