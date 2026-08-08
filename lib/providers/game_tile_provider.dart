import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/game_config.dart';
import '../core/constants/map_config.dart';
import '../models/tile_model.dart';
import '../models/footprint_model.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../services/hex_service.dart';
import '../services/supabase_service.dart';
import '../services/preferences_service.dart';

/// 점령된 타일 데이터의 저장소, 실시간 스트림 구독, 침공 감지, 타일 정보 해제, 
/// 닉네임 캐싱 등 타일에 특화된 상태를 전담 관리하는 프로바이더.
/// 
/// [GameProvider]에서 타일 관련 책임을 분리하여 단일 책임 원칙을 강화합니다.
class GameTileProvider extends ChangeNotifier {
  final SupabaseService _supabase;
  AuthProvider? _authProvider;

  /// 초기화 완료 처리를 조율하는 Completer
  final Completer<void> _initCompleter = Completer<void>();
  bool _hasInitializedLocation = false;
  bool get hasInitializedLocation => _hasInitializedLocation;

  /// 점령된 타일 목록 (Key: 타일 ID, Value: 타일 상세 모델)
  final Map<String, HexTile> _capturedTiles = {};

  /// 플레이어의 발자취 타일 목록 (Key: 타일 ID, Value: 발자취 모델)
  final Map<String, FootprintTile> _footprints = {};

  /// 발자취 맵 getter
  Map<String, FootprintTile> get footprints => Map.unmodifiable(_footprints);

  /// 사진(갤러리)이 1개 이상 등록된 모든 타일 ID의 집합
  final Set<String> _photoTileIds = {};
  Set<String> get photoTileIds => Set.unmodifiable(_photoTileIds);

  /// 프로바이더 내부 데이터 초기화 완료 여부
  bool _isInitialized = false;

  /// 마지막으로 2km REST 조회를 진행했던 타일 ID
  String? _lastCheckedAreaTileId;

  /// 마지막으로 2km REST 조회를 수행한 시각
  DateTime? _lastAreaFetchTime;

  /// 위치 변경 감지 시 서버 부하 방지용 3초 딜레이 타이머의 마지막 체크 시각
  DateTime? _lastServerCheckTime;

  /// 정보가 보안 해제(Reveal)된 타일 ID와 해제 일시 맵
  final Map<String, DateTime> _revealedTileTimes = {};

  /// 유저 고유 ID를 닉네임으로 캐싱하는 메모리 버퍼
  final Map<String, String> _agentNicknames = {};

  // --- Callbacks ---
  /// 침공이 감지되었을 때 GameProvider가 알림/골드 동기화 등을 수행하도록 하는 콜백
  VoidCallback? onInvasionDetected;

  /// 타일 캡처/업데이트 시 추가 후처리를 위한 콜백
  void Function(String tileId, HexTile tile)? onTileUpdated;

  GameTileProvider({required SupabaseService supabase}) : _supabase = supabase;

  /// 모든 캐시 데이터를 청소합니다 (로그아웃/사용자 변경 시 호출).
  void reset() {
    _capturedTiles.clear();
    _footprints.clear();
    _photoTileIds.clear();
    _lastCheckedAreaTileId = null;
    _lastAreaFetchTime = null;
    _hasInitializedLocation = false;
    notifyListeners();
  }

  // --- AuthProvider 바인딩 ---
  void setAuthProvider(AuthProvider auth) {
    final oldUserId = _userId;
    _authProvider = auth;
    final newUserId = auth.user?.id;

    if (oldUserId != newUserId) {
      // 로그인 사용자 세션이 변경된 경우 캐시 전면 초기화
      reset();

      if (newUserId != null) {
        // 새 사용자의 발자취 데이터를 비동기로 로드
        loadFootprints(newUserId).catchError((e) {
          debugPrint('⚠️ 새 사용자 발자취 로드 실패: $e');
        });
        loadPhotoTileIds().catchError((e) {
          debugPrint('⚠️ 새 사용자 사진 타일 ID 로드 실패: $e');
        });
      }
    }
  }

  // --- 편의 getter (AuthProvider 캡슐화) ---
  String? get _userId => _authProvider?.user?.id;
  String? get _userMainBaseTileId => _authProvider?.profile?.mainBaseTileId;
  String? get _userColorHex => _authProvider?.profile?.colorHex;
  String? get _userNickname => _authProvider?.profile?.nickname;

  // --- 초기화 ---
  bool get isInitialized => _isInitialized;
  Future<void> get initializationFuture => _initCompleter.future;

  /// [개편] 서버 전체 로드 대신 최초 위치 획득 후 5km 선별 조회를 대기하도록 설정하며, 로그인 시 발자취 및 사진 등록 타일 목록을 백그라운드 로드합니다.
  Future<void> init() async {
    try {
      final myId = _userId;
      if (myId != null) {
        // 초기화 프로세스가 네트워크 대기에 블로킹되지 않도록 비동기 백그라운드 처리
        loadFootprints(myId).catchError((e) {
          debugPrint('⚠️ 초기 발자취 백그라운드 로드 실패: $e');
        });
        loadPhotoTileIds().catchError((e) {
          debugPrint('⚠️ 초기 사진 타일 ID 로드 실패: $e');
        });
      }
    } catch (e) {
      debugPrint('GameTileProvider 초기 데이터 로드 실패: $e');
    } finally {
      _isInitialized = true;
      if (!_initCompleter.isCompleted) _initCompleter.complete();
      notifyListeners();
    }
  }

  /// [신규] 사진이 등록된 모든 타일 ID 목록을 서버에서 일괄 로딩하여 로컬 캐시를 구성합니다.
  Future<void> loadPhotoTileIds() async {
    try {
      final ids = await _supabase.fetchPhotoTileIds();
      _photoTileIds.clear();
      _photoTileIds.addAll(ids);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 사진 등록 타일 ID 캐시 로드 실패: $e');
    }
  }

  /// [신규] 최초 위치(현재 GPS 또는 본진) 좌표가 획득되었을 때 지정된 반경의 타일을 최초로 선별 로딩합니다.
  Future<void> initializeWithLocation(LatLng location) async {
    if (!_isInitialized || _hasInitializedLocation) return;
    _hasInitializedLocation = true;
    final hex = HexService.latLngToHex(location);
    final centerQ = hex['q']!;
    final centerR = hex['r']!;
    
    debugPrint('🗺️ [GameTileProvider] 최초 위치 기반 ${MapConfig.mapLoadRadiusKm}km 이내 지도 타일 로딩 개시 (${location.latitude}, ${location.longitude})');
    await updateTilesInArea(centerQ, centerR, radiusKm: MapConfig.mapLoadRadiusKm, force: true);
  }

  // --- Footprint CRUD ---

  /// 서버에서 사용자의 발자취 데이터를 불러와 캐시를 구축합니다.
  /// [개선] 캐시 로딩 전에 로컬 대기열에 보관되어 있던 미동기화 발자취들을 비동기 동기화 진행합니다.
  Future<void> loadFootprints(String userId) async {
    // 백그라운드 미동기화 대기열 동기화 기동
    syncPendingFootprints(userId).catchError((e) {
      debugPrint('⚠️ 미동기화 발자취 동기화 실패: $e');
    });

    try {
      _footprints.clear();
      // Supabase DB 서버 데이터 비동기 조회하여 캐시 구축
      final list = await _supabase.fetchUserFootprints(userId);
      for (final tile in list) {
        _footprints[tile.tileId] = tile;
      }
      notifyListeners();
      debugPrint('📦 서버 발자취 ${list.length}개 동기화 완료');
    } catch (e) {
      debugPrint('❌ 발자취 로드 실패: $e');
    }
  }

  /// [신규] 로컬 대기열에 쌓여있는 미동기화 발자취들을 Supabase 서버로 일괄 백그라운드 동기화합니다.
  Future<void> syncPendingFootprints(String userId) async {
    final pendingList = await PreferencesService.getPendingFootprints();
    if (pendingList.isEmpty) return;

    debugPrint('🔄 미동기화 발자취 ${pendingList.length}건 동기화 시작...');
    final List<String> toRemove = [];

    for (final item in pendingList) {
      final parts = item.split('|');
      if (parts.length != 2) continue;
      final tileId = parts[0];
      final time = DateTime.parse(parts[1]);

      final success = await _supabase.recordFootprint(userId, tileId, time);
      if (success) {
        toRemove.add(tileId);
        debugPrint('✅ 미동기화 발자취 업로드 성공: $tileId');
      } else {
        debugPrint('⚠️ 미동기화 발자취 업로드 실패 (다음 재시도 대기): $tileId');
      }
    }

    // 성공한 항목들은 큐에서 삭제
    for (final tileId in toRemove) {
      await PreferencesService.removePendingFootprint(tileId);
    }
  }

  /// 새로운 발자취를 추가합니다. 이미 캐싱되어 있다면 서버 추가를 건너뜁니다.
  /// [개편] 로컬 메모리 캐시 및 로컬 대기열(SharedPreferences)에 즉시 임시 등록하여 
  /// UI의 즉각적인 반영을 보장하고, 서버 전송 성공 시 대기열에서 제거하는 동기화 메커니즘을 가동합니다.
  Future<void> addFootprint(String userId, String tileId, DateTime time) async {
    if (_footprints.containsKey(tileId)) return;

    // 년/월/일/시/분까지만 기록 (초 이하 00으로 절사)
    final truncatedTime = DateTime(
      time.year,
      time.month,
      time.day,
      time.hour,
      time.minute,
    );

    // 1. 로컬 즉시 반영
    final newFootprint = FootprintTile(
      tileId: tileId,
      recordedAt: truncatedTime,
    );
    _footprints[tileId] = newFootprint;
    notifyListeners();

    // 2. 로컬 영구 미동기화 대기열에 추가
    await PreferencesService.addPendingFootprint(tileId, truncatedTime);
    debugPrint('🐾 발자취 로드 메모리 즉시 반영 및 대기열 적재 완료: $tileId');

    // 3. 백그라운드로 서버 업로드 시작
    _supabase.recordFootprint(userId, tileId, truncatedTime).then((success) async {
      if (success) {
        // 서버 전송 완료 시 대기열에서 해제
        await PreferencesService.removePendingFootprint(tileId);
        debugPrint('✅ 발자취 서버 전송 성공 및 대기열 소거 완료: $tileId');
      } else {
        debugPrint('⚠️ 발자취 서버 전송 실패 (대기열 잔류): $tileId');
      }
    }).catchError((e) {
      debugPrint('❌ 발자취 백그라운드 서버 전송 도중 오류 발생: $e');
    });
  }

  // --- Tile CRUD ---
  /// 단일 타일을 갱신하거나 추가합니다.
  void updateTile(String id, HexTile tile) {
    _capturedTiles[id] = tile;
    notifyListeners();
  }

  /// 단일 타일을 제거합니다.
  void removeTile(String id) {
    _capturedTiles.remove(id);
    notifyListeners();
  }

  /// 여러 타일을 한 번에 갱신합니다 (스트림 업데이트 등).
  void setTiles(Map<String, HexTile> tiles) {
    _capturedTiles
      ..clear()
      ..addAll(tiles);
    notifyListeners();
  }

  /// 특정 타일 ID의 현재 정보를 반환합니다.
  HexTile? tileById(String id) => _capturedTiles[id];

  /// 마지막 서버 체크 시각을 갱신합니다.
  void updateLastServerCheckTime() {
    _lastServerCheckTime = DateTime.now();
  }

  /// 마지막 서버 체크 시각을 반환합니다.
  DateTime? get lastServerCheckTime => _lastServerCheckTime;

  // --- Public Getters ---
  /// 실시간 점령된 타일 정보를 담은 불변 Map을 반환합니다.
  /// 내 메인 기지는 가상으로 내 땅으로 강제 주입하여 반환합니다.
  Map<String, HexTile> get capturedTiles {
    final copy = Map<String, HexTile>.from(_capturedTiles);

    final myMainBaseId = _userMainBaseTileId;
    final myId = _userId;
    final myColor = _userColorHex;

    if (myMainBaseId != null &&
        myMainBaseId.isNotEmpty &&
        myId != null &&
        myColor != null) {
      try {
        final parts = myMainBaseId.split('_');
        if (parts.length == 3) {
          final q = int.tryParse(parts[1]) ?? 0;
          final r = int.tryParse(parts[2]) ?? 0;
          final existing = _capturedTiles[myMainBaseId];
          copy[myMainBaseId] = HexTile(
            id: myMainBaseId,
            q: q,
            r: r,
            userId: myId,
            colorHex: myColor,
            capturedAt: existing?.capturedAt ?? DateTime.now().toUtc(),
            captureCount: existing?.captureCount ?? 1,
          );
        }
      } catch (e) {
        debugPrint('⚠️ 내 메인기지 가상 타일 주입 오류: $e');
      }
    }

    return Map.unmodifiable(copy);
  }

  /// 본인 플레이어가 획득한 영토(타일)의 총 개수
  int get myCapturedCount {
    if (_userId == null) return 0;
    final myId = _userId!;
    final baseCount =
        _capturedTiles.values.where((t) => t.userId == myId).length;

    final myMainBaseId = _userMainBaseTileId;
    if (myMainBaseId != null && myMainBaseId.isNotEmpty) {
      return baseCount < 1 ? 1 : baseCount;
    }
    return baseCount;
  }

  /// 현재 GPS 위치에 대응하는 점령 타일 정보를 반환합니다.
  HexTile? currentTile(LocationProvider loc) {
    if (loc.currentLocation == null) return null;
    final hex = HexService.latLngToHex(loc.currentLocation!);
    final tileId = HexService.tileId(hex['q']!, hex['r']!);
    return capturedTiles[tileId];
  }

  /// 현재 위치한 타일이 이미 자신이 지배 중인 타일인지 여부
  bool isAlreadyCapturedByMe(LocationProvider loc) {
    if (_authProvider?.user == null) return false;
    return currentTile(loc)?.userId == _authProvider!.user!.id;
  }

  // --- 동기화 핸들러 ---



  /// 2km 사각형 범위 내의 타일 정보 머지 및 소거 처리
  void _handleAreaTilesUpdate(List<HexTile> tiles, int minQ, int maxQ, int minR, int maxR) {
    bool changed = false;

    // 1. 해당 영역 내에 속하는 기존 로컬 타일 ID 집합 추출
    final localIdsInArea = _capturedTiles.entries
        .where((e) => e.value.q >= minQ && e.value.q <= maxQ && e.value.r >= minR && e.value.r <= maxR)
        .map((e) => e.key)
        .toSet();

    // 2. 들어온 타일 ID 집합
    final incomingIds = tiles.map((t) => t.id).toSet();

    // 3. 영역 내에서 사라진 타일들 캐시 소거
    final removedIds = localIdsInArea.difference(incomingIds);
    for (final id in removedIds) {
      _capturedTiles.remove(id);
      changed = true;
    }

    // 4. 신규 및 변경 타일 반영
    for (final tile in tiles) {
      final oldTile = _capturedTiles[tile.id];
      if (oldTile == null ||
          oldTile.userId != tile.userId ||
          oldTile.colorHex != tile.colorHex ||
          oldTile.captureCount != tile.captureCount) {
        _capturedTiles[tile.id] = tile;
        changed = true;
        onTileUpdated?.call(tile.id, tile);
      }
    }

    if (changed) {
      notifyListeners();
    }
  }
  /// [개편] 서버 전체 갱신 대신, 플레이어의 현재 위치 또는 본진 위치를 기준으로 주변 지정 반경 영역을 강제로 다시 불러와 캐시를 갱신합니다.
  Future<void> refreshTilesFromServer({LatLng? customLocation}) async {
    if (!_isInitialized) return;
    try {
      LatLng? targetLoc = customLocation;
      if (targetLoc == null && _authProvider != null) {
        final mainBaseId = _userMainBaseTileId;
        if (mainBaseId != null) {
          final parsed = HexService.parseTileId(mainBaseId);
          if (parsed != null) {
            targetLoc = HexService.hexToLatLng(parsed['q']!, parsed['r']!);
          }
        }
      }
      
      if (targetLoc != null) {
        final hex = HexService.latLngToHex(targetLoc);
        await updateTilesInArea(hex['q']!, hex['r']!, radiusKm: MapConfig.mapLoadRadiusKm, force: true);
        debugPrint('📦 서버 주변 타일 강제 동기화 완료');
      }
    } catch (e) {
      debugPrint('❌ 주변 타일 서버 동기화 실패: $e');
    }
  }

  /// [개편] 내 현재 위치 또는 지도 중심 타일(q, r) 기준으로 지정된 반경(radiusKm) 영역의 타일을 서버에서 REST로 조회하여 갱신합니다.
  /// 
  /// 불필요한 서버 조회를 줄이기 위해 500m(타일 5칸) 이상 이동했거나 force가 true일 때만 백엔드 조회를 진행하며, 10초 쿨타임 가드가 적용됩니다.
  Future<void> updateTilesInArea(int centerQ, int centerR, {double radiusKm = MapConfig.mapLoadRadiusKm, bool force = false}) async {
    if (!_isInitialized) return;

    final currentId = HexService.tileId(centerQ, centerR);
    final now = DateTime.now();

    // 1. 이동 거리 및 시간 가드 체크 (force가 아닐 때만 작동)
    if (!force && _lastCheckedAreaTileId != null && _lastAreaFetchTime != null) {
      final parsed = HexService.parseTileId(_lastCheckedAreaTileId!);
      if (parsed != null) {
        final dist = HexService.hexDistance(centerQ, centerR, parsed['q']!, parsed['r']!);
        final timeDiff = now.difference(_lastAreaFetchTime!);
        
        // 500m (타일 5칸) 미만으로 움직였고, 마지막 조회 후 10초가 지나지 않았다면 불필요한 트래픽 유발 차단
        if (dist < 5 && timeDiff < const Duration(seconds: 10)) {
          return;
        }
      }
    }

    _lastCheckedAreaTileId = currentId;
    _lastAreaFetchTime = now;

    try {
      // 5km 기준 Hex 반경 오프셋 계산 (tileSize 100m 기준 5km는 50개 링. 안전 마진 추가하여 올림)
      final int k = ((radiusKm * 1000) / GameConfig.tileSize).ceil() + 5;
      final minQ = centerQ - k;
      final maxQ = centerQ + k;
      final minR = centerR - k;
      final maxR = centerR + k;

      debugPrint('🛰️ [GameTileProvider] 영역 타일 비동기 동적 수신: 중심 ($centerQ, $centerR), 오프셋 $k (약 ${radiusKm}km 범위)');
      final tiles = await _supabase.fetchCapturedTilesInArea(minQ, maxQ, minR, maxR);
      _handleAreaTilesUpdate(tiles, minQ, maxQ, minR, maxR);
    } catch (e) {
      debugPrint('❌ 주변 영역 타일 조회 실패 ($currentId): $e');
    }
  }

  Future<TileStatus> checkCurrentLocationTileStatusFromServer(
    LocationProvider loc,
    AuthProvider auth,
  ) async {
    if (loc.currentLocation == null || auth.user == null) {
      return TileStatus.empty;
    }

    final hex = HexService.latLngToHex(loc.currentLocation!);
    final tileId = HexService.tileId(hex['q']!, hex['r']!);

    final status = await _supabase.checkTileStatusFromServer(
      tileId,
      auth.user!.id,
    );

    if (status == TileStatus.enemy) {
      final serverTile = await _supabase.fetchTile(tileId);
      if (serverTile != null) {
        _capturedTiles[tileId] = serverTile;
        notifyListeners();
        debugPrint(
          '🎨 [상대방 구역 갱신] 타일($tileId)을 상대방 점령색(${serverTile.colorHex})으로 실시간 갱신 완료.',
        );
      }
    } else if (status == TileStatus.mine) {
      final serverTile = await _supabase.fetchTile(tileId);
      if (serverTile != null) {
        _capturedTiles[tileId] = serverTile;
        notifyListeners();
        debugPrint(
          '🎨 [내 구역 갱신] 타일($tileId)의 최신 상태를 실시간 동기화 완료.',
        );
      }
    } else if (status == TileStatus.empty) {
      if (_capturedTiles.containsKey(tileId)) {
        _capturedTiles.remove(tileId);
        notifyListeners();
        debugPrint('🎨 [중립 구역 갱신] 타일($tileId)이 빈 상태이므로 로컬에서 제거 완료.');
      }
    }

    return status;
  }

  // --- 타일 정보 해제 (Reveal) ---
  void addRevealedTile(String tileId, DateTime time) {
    _revealedTileTimes[tileId] = time;
    notifyListeners();
  }

  void removeRevealedTile(String tileId) {
    _revealedTileTimes.remove(tileId);
    notifyListeners();
  }

  /// 타일 정보가 열람 가능한 상태인지 판별합니다.
  bool isTileInfoRevealed(String tileId) {
    final myMainBaseId = _userMainBaseTileId;
    if (myMainBaseId != null &&
        myMainBaseId.isNotEmpty &&
        tileId == myMainBaseId) {
      return true;
    }

    final myId = _userId;
    final tile = capturedTiles[tileId];
    final isOwnTile = tile != null && tile.userId == myId;
    final isNeutral =
        tile == null || tile.userId == null || tile.userId == 'none';

    if (isOwnTile || isNeutral) {
      return true;
    }

    final revealedAt = _revealedTileTimes[tileId];
    if (revealedAt == null) return false;

    final expiration = revealedAt
        .add(const Duration(seconds: GameConfig.tileRevealDurationSeconds));
    final isValid = DateTime.now().toUtc().isBefore(expiration);

    if (!isValid) {
      _revealedTileTimes.remove(tileId);
      notifyListeners();
    }

    return isValid;
  }

  /// 보안 해제된 타일의 남은 만료 시각을 반환합니다.
  DateTime? getTileRevealExpiration(String tileId) {
    final revealedAt = _revealedTileTimes[tileId];
    if (revealedAt == null) return null;
    return revealedAt
        .add(const Duration(seconds: GameConfig.tileRevealDurationSeconds));
  }

  /// 특정 타일의 남은 쉴드 보호 시간(초)을 반환합니다.
  int getRemainingShieldSeconds(String tileId) {
    final tile = _capturedTiles[tileId];
    if (tile == null) return 0;
    final remaining = tile.shieldExpiration
        .difference(DateTime.now().toUtc())
        .inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  // --- 닉네임 캐싱 ---
  /// 유저 ID에 해당하는 닉네임을 반환합니다. (캐시 → DB 조회)
  Future<String> getAgentNickname(String userId) async {
    final myId = _userId;
    final myNick = _userNickname;

    if (myId == userId && myNick != null && myNick.isNotEmpty) {
      return myNick;
    }

    if (_agentNicknames.containsKey(userId)) {
      return _agentNicknames[userId]!;
    }

    try {
      final res = await _supabase.client
          .from('profiles')
          .select('nickname')
          .eq('id', userId)
          .maybeSingle();
      if (res != null && res['nickname'] != null) {
        final nick = res['nickname'] as String;
        _agentNicknames[userId] = nick;
        notifyListeners();
        return nick;
      }
    } catch (e) {
      debugPrint('⚠️ 닉네임 조회 실패: $e');
    }

    final masked =
        userId.length > 8 ? '${userId.substring(0, 6)}...' : userId;
    return masked;
  }

  /// 특정 타일 ID의 최신 정보를 서버에서 패치하여 캐시에 반영합니다.
  Future<void> fetchAndUpdateTile(String tileId) async {
    try {
      final serverTile = await _supabase.fetchTile(tileId);
      if (serverTile != null) {
        _capturedTiles[tileId] = serverTile;
      } else {
        _capturedTiles.remove(tileId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ 타일 정보 서버 패치 실패: $e');
    }
  }


}
