import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
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

  int _userUniquePhotoTilesCount = 0;
  int get userUniquePhotoTilesCount => _userUniquePhotoTilesCount;

  List<String> _unlockedAchievementIds = [];
  bool _isLoading = false;
  bool _isChecking = false; // 연타 점령 시 비동기 경합(Race Condition)을 가드하는 락 플래그
  bool _hasPendingCheck = false; // 진행 중인 판정이 있을 때 후속 판정 요청을 임시 기록하는 플래그

  // 패턴별 상대 좌표 목록 캐시 (key: 패턴 ID, value: [ {q: 0, r: 0}, ... ])
  final Map<String, List<Map<String, int>>> _loadedPatterns = {};

  // 패턴별 메타데이터 캐시 (요구 타일 수, 바운딩 박스 편차 등)
  final Map<String, Map<String, dynamic>> _patternMeta = {};

  // 패턴 ID → 표시 이름 registry (미등록분은 ID 그대로 표시)
  final Map<String, String> _patternNames = {};
  bool _patternRegistryLoaded = false;

  /// 번들 내장 문자 패턴 ID 목록 (DB 미등록 시 파일 폴백용)
  static const List<String> _builtinPatternIds = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
  ];

  // 이미 업적 해금에 소비 완료된 영토 타일 ID 목록 캐시
  final Set<String> _consumedTileIds = {};

  // 업적별 소비(완성) 완료된 타일 ID 맵핑 캐시 (key: achievement_id, value: [tile_id, ...])
  final Map<String, List<String>> _achievementTiles = {};

  /// 최근 해금된 업적 정보를 실시간 중계하는 브로드캐스트 스트림
  final StreamController<Achievement> _unlockStreamController =
      StreamController<Achievement>.broadcast();

  /// 패턴 등록부 로드: DB 정의 + 번들 내장 문자(이름 폴백용).
  ///
  /// DB 행이 있으면 타일까지 캐싱하고, 번들 문자는 이름만 보장한 뒤
  /// 타일은 판정 시점에 파일에서 지연 로드한다.
  Future<void> loadPatternRegistry() async {
    if (_patternRegistryLoaded) return;
    _patternRegistryLoaded = true;
    try {
      final rows = await _supabase.fetchMapPatterns();
      for (final row in rows) {
        final id = row['id'] as String?;
        if (id == null || id.isEmpty) continue;
        final name = row['name'] as String?;
        _patternNames[id] = (name == null || name.isEmpty) ? id : name;
        final tilesJson = row['tiles'];
        if (tilesJson is List && tilesJson.isNotEmpty) {
          _cachePatternTiles(id, tilesJson);
        }
      }
    } catch (e) {
      debugPrint('⚠️ 패턴 등록부 로드 실패: $e');
    }
    for (final id in _builtinPatternIds) {
      _patternNames.putIfAbsent(id, () => id);
    }
  }

  /// 타일 좌표 목록을 패턴 캐시에 적재하고 메타데이터를 갱신한다.
  void _cachePatternTiles(String patternId, List<dynamic> tilesJson) {
    final List<Map<String, int>> tiles = [];
    int minQ = 999999;
    int maxQ = -999999;
    int minR = 999999;
    int maxR = -999999;

    for (final tile in tilesJson) {
      final tileMap = tile as Map;
      final int q = tileMap['q'] as int;
      final int r = tileMap['r'] as int;
      tiles.add({'q': q, 'r': r});

      if (q < minQ) minQ = q;
      if (q > maxQ) maxQ = q;
      if (r < minR) minR = r;
      if (r > maxR) maxR = r;
    }

    _loadedPatterns[patternId] = tiles;
    _patternMeta[patternId] = {
      'tileCount': tiles.length,
      'widthQ': maxQ - minQ,
      'widthR': maxR - minR,
    };
  }

  /// 패턴 JSON 에셋 파일을 안전하게 비동기 로드하고 q, r 상대 오프셋 데이터를 수집하여 캐싱합니다.
  Future<void> _ensurePatternLoaded(String patternId) async {
    if (_loadedPatterns.containsKey(patternId)) return;

    // 번들 내장 문자만 파일 폴백 (커스텀은 DB 타일이 전부)
    if (!_builtinPatternIds.contains(patternId)) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/$patternId.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> tilesJson = jsonMap['tiles'] as List<dynamic>;
      _cachePatternTiles(patternId, tilesJson);
    } catch (e) {
      debugPrint('⚠️ 패턴 파일 로드 실패 ($patternId.json): $e');
    }
  }

  /// 완성한 패턴 ID 집합 (`ACH_PATTERN_` 접두 기록 기준)
  Set<String> completedPatternIds() {
    return _unlockedAchievementIds
        .where((id) => id.startsWith('ACH_PATTERN_'))
        .map((id) => id.replaceFirst('ACH_PATTERN_', ''))
        .toSet();
  }

  /// 완성한 패턴 개수 (개수형 업적 판정용)
  int get completedPatternCount => completedPatternIds().length;

  /// 패턴 표시 이름 (미등록이면 ID 그대로)
  String patternName(String patternId) => _patternNames[patternId] ?? patternId;

  /// 등록된 패턴 ID 목록
  Iterable<String> get patternIds => _patternNames.keys;

  /// 특정 타일(startTileId)을 출발점으로 삼아 인접한 현재 플레이어 소유의 영토 타일들을 BFS로 수집하여 단일 클러스터 셋을 반환합니다.
  Set<String> _extractCluster(
    String startTileId,
    Map<String, HexTile> capturedTiles,
    String userId,
  ) {
    if (_consumedTileIds.contains(startTileId)) return {};
    final Set<String> cluster = {};
    final List<String> queue = [startTileId];
    cluster.add(startTileId);

    int head = 0;
    while (head < queue.length) {
      final currentId = queue[head++];
      final parsed = HexService.parseTileId(currentId);
      if (parsed == null) continue;
      final int q = parsed['q'] as int;
      final int r = parsed['r'] as int;

      for (final dir in HexService.hexDirections) {
        final int nq = q + dir[0];
        final int nr = r + dir[1];
        final String neighborId = HexService.tileId(nq, nr);

        if (!cluster.contains(neighborId) && !_consumedTileIds.contains(neighborId)) {
          final neighborTile = capturedTiles[neighborId];
          if (neighborTile != null && neighborTile.userId == userId) {
            cluster.add(neighborId);
            queue.add(neighborId);
          }
        }
      }
    }
    return cluster;
  }

  /// 앵커 좌표 역산 및 해시 맵 검색 최적화 기술을 사용하여 플레이어가 소유한 특정 타일 또는 구역 내에 지정 패턴이 만족하는지 판정합니다.
  List<String>? _checkPatternMatch(
    String char,
    Map<String, HexTile> capturedTiles,
    String userId, {
    String? newlyCapturedTileId,
  }) {
    final pattern = _loadedPatterns[char];
    final meta = _patternMeta[char];
    if (pattern == null || meta == null) return null;

    final int reqCount = meta['tileCount'] as int;
    final int widthQ = meta['widthQ'] as int;
    final int widthR = meta['widthR'] as int;

    // 점령 형상 매칭을 위한 대상 좌표 정보
    final Set<String> targetCoords = {}; // "q,r" 형태의 룩업 테이블
    final List<Map<String, int>> targetTiles = [];

    if (newlyCapturedTileId != null && capturedTiles.containsKey(newlyCapturedTileId)) {
      // 최적화: 최근 점령된 타일이 포함된 연결된 점령지 덩어리(Cluster)만 BFS로 추출하여 한정 탐색
      final Set<String> clusterIds = _extractCluster(newlyCapturedTileId, capturedTiles, userId);
      if (clusterIds.length < reqCount) return null;

      int minQ = 999999;
      int maxQ = -999999;
      int minR = 999999;
      int maxR = -999999;

      for (final id in clusterIds) {
        final parsed = HexService.parseTileId(id);
        if (parsed != null) {
          final int q = parsed['q'] as int;
          final int r = parsed['r'] as int;
          targetCoords.add('$q,$r');
          targetTiles.add({'q': q, 'r': r});

          if (q < minQ) minQ = q;
          if (q > maxQ) maxQ = q;
          if (r < minR) minR = r;
          if (r > maxR) maxR = r;
        }
      }

      // 바운딩 박스(AABB) 사전 필터링
      if ((maxQ - minQ) < widthQ || (maxR - minR) < widthR) {
        return null;
      }
    } else {
      // 폴백: 최근 캡처 타일 ID가 누락되었을 경우 플레이어가 점령한 전체 타일 중 이미 소비되지 않은 타일들을 대상으로 1회 일괄 검증
      final myTiles = capturedTiles.values
          .where((t) => t.userId == userId && !_consumedTileIds.contains(t.id))
          .toList();
      if (myTiles.length < reqCount) return null;

      int minQ = 999999;
      int maxQ = -999999;
      int minR = 999999;
      int maxR = -999999;

      for (final tile in myTiles) {
        final parsed = HexService.parseTileId(tile.id);
        if (parsed != null) {
          final int q = parsed['q'] as int;
          final int r = parsed['r'] as int;
          targetCoords.add('$q,$r');
          targetTiles.add({'q': q, 'r': r});

          if (q < minQ) minQ = q;
          if (q > maxQ) maxQ = q;
          if (r < minR) minR = r;
          if (r > maxR) maxR = r;
        }
      }

      // 전체 바운딩 박스(AABB) 사전 필터링
      if ((maxQ - minQ) < widthQ || (maxR - minR) < widthR) {
        return null;
      }
    }

    // 앵커 역산 매칭 알고리즘 적용
    if (pattern.isEmpty) return null;
    final anchor = pattern.first;
    final int anchorQ = anchor['q']!;
    final int anchorR = anchor['r']!;

    for (final T in targetTiles) {
      final int originQ = T['q']! - anchorQ;
      final int originR = T['r']! - anchorR;

      bool match = true;
      final List<String> matchedTileIds = [];

      for (final pTile in pattern) {
        final int pq = originQ + pTile['q']!;
        final int pr = originR + pTile['r']!;
        if (!targetCoords.contains('$pq,$pr')) {
          match = false;
          break;
        }
        matchedTileIds.add(HexService.tileId(pq, pr));
      }
      if (match) return matchedTileIds;
    }

    return null;
  }

  /// 특정 패턴 ID의 상대 좌표 리스트를 비동기로 불러와 캐싱한 뒤 반환합니다.
  Future<List<Map<String, int>>> getPatternCoordinates(String patternId) async {
    await loadPatternRegistry();
    await _ensurePatternLoaded(patternId);
    return _loadedPatterns[patternId] ?? [];
  }

  Stream<Achievement> get onAchievementUnlocked => _unlockStreamController.stream;

  /// 해금 완료된 업적 ID 목록 반환
  List<String> get unlockedAchievementIds => List.unmodifiable(_unlockedAchievementIds);

  /// 업적 해금에 소비된 타일 ID 목록 반환
  Set<String> get consumedTileIds => Set.unmodifiable(_consumedTileIds);

  /// 업적별로 소비된 타일 ID 맵핑 데이터 반환
  Map<String, List<String>> get achievementTiles => Map.unmodifiable(_achievementTiles);

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
        _consumedTileIds.clear();
        _achievementTiles.clear();
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
      final consumed = await _supabase.fetchConsumedTileIds(userId);
      _consumedTileIds.clear();
      _consumedTileIds.addAll(consumed);

      final achTiles = await _supabase.fetchAchievementTiles(userId);
      _achievementTiles.clear();
      _achievementTiles.addAll(achTiles);

      await loadPatternRegistry();

      if (_authProvider != null && _authProvider!.profile != null) {
        _userUniquePhotoTilesCount = _authProvider!.profile!.photoUploadCount;
      } else {
        _userUniquePhotoTilesCount = 0;
      }
    } catch (e) {
      debugPrint('⚠️ 해금 업적 및 소비 타일 조회 실패: $e');
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
    String? newlyCapturedTileId,
  }) async {
    final profile = _authProvider?.profile;
    final userId = _authProvider?.user?.id;
    if (profile == null || userId == null || _isLoading) return;

    // [추가] 인앱 프로필의 누적 사진 촬영 개수 실시간 동기화 및 notify
    if (_userUniquePhotoTilesCount != profile.photoUploadCount) {
      _userUniquePhotoTilesCount = profile.photoUploadCount;
      notifyListeners();
    }

    if (_isChecking) {
      _hasPendingCheck = true;
      return;
    }

    _isChecking = true;
    _hasPendingCheck = false;

    try {
      await _runCheckFlow(capturedTiles, newlyCapturedTileId, profile, userId);
    } finally {
      _isChecking = false;
      if (_hasPendingCheck) {
        _hasPendingCheck = false;
        Future.microtask(() => checkAndUnlock(
          capturedTiles: capturedTiles,
          newlyCapturedTileId: newlyCapturedTileId,
        ));
      }
    }
  }

  /// 미완성 등록 패턴을 전부 판정하고, 새로 완성된 것은 완성 기록으로 저장한다.
  ///
  /// 완성 기록은 기존과 같은 `ACH_PATTERN_` 접두 행 + 소비 타일로 유지하여
  /// 도감 버튼·이동·소비 규칙이 그대로 동작한다. 개수형 업적은 행 개수로 판정한다.
  Future<void> _detectPatternCompletions(
    Map<String, HexTile> capturedTiles,
    String userId, {
    String? newlyCapturedTileId,
  }) async {
    await loadPatternRegistry();
    final completed = completedPatternIds();
    for (final patternId in _patternNames.keys) {
      if (completed.contains(patternId)) continue;
      await _ensurePatternLoaded(patternId);
      final matched = _checkPatternMatch(
        patternId,
        capturedTiles,
        userId,
        newlyCapturedTileId: newlyCapturedTileId,
      );
      if (matched == null) continue;
      final recordId = 'ACH_PATTERN_$patternId';
      final success = await _supabase.unlockAchievement(
        userId,
        recordId,
        consumedTileIds: matched,
      );
      if (success) {
        _unlockedAchievementIds.add(recordId);
        _consumedTileIds.addAll(matched);
        _achievementTiles[recordId] = matched;
        completed.add(patternId);
        notifyListeners();
      }
    }
  }

  /// 실제 업적 검증 및 해금 API 동기화 플로우를 진행하는 비동기 내부 헬퍼 메서드
  Future<void> _runCheckFlow(
    Map<String, HexTile>? capturedTiles,
    String? newlyCapturedTileId,
    dynamic profile,
    String userId,
  ) async {
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
        case AchievementCategory.photoUpload:
          shouldUnlock = profile.photoUploadCount >= ach.threshold;
          break;
        case AchievementCategory.patternMatch:
          if (capturedTiles != null) {
            await _detectPatternCompletions(
              capturedTiles,
              userId,
              newlyCapturedTileId: newlyCapturedTileId,
            );
            shouldUnlock = completedPatternCount >= ach.threshold;
          }
          break;
      }

      if (shouldUnlock) {
        // 백엔드 데이터 동기화 시도
        final success = await _supabase.unlockAchievement(
          userId,
          ach.id,
        );
        if (success) {
          _unlockedAchievementIds.add(ach.id);
          _unlockStreamController.add(ach); // 해금 완료 이벤트 중계
          notifyListeners();
        }
      }
    }
  }
}
