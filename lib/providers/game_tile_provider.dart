import 'dart:async';
import 'package:flutter/widgets.dart';
import '../core/constants/game_config.dart';
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

  /// 점령된 타일 목록 (Key: 타일 ID, Value: 타일 상세 모델)
  final Map<String, HexTile> _capturedTiles = {};

  /// 플레이어의 발자취 타일 목록 (Key: 타일 ID, Value: 발자취 모델)
  final Map<String, FootprintTile> _footprints = {};

  /// 발자취 맵 getter
  Map<String, FootprintTile> get footprints => Map.unmodifiable(_footprints);

  /// 실시간 점령 타일 목록 스트림 구독 객체
  StreamSubscription<List<HexTile>>? _tilesStreamSub;

  /// 프로바이더 내부 데이터 초기화 완료 여부
  bool _isInitialized = false;

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

  // --- AuthProvider 바인딩 ---
  void setAuthProvider(AuthProvider auth) {
    _authProvider = auth;
  }

  // --- 편의 getter (AuthProvider 캡슐화) ---
  String? get _userId => _authProvider?.user?.id;
  String? get _userMainBaseTileId => _authProvider?.profile?.mainBaseTileId;
  String? get _userColorHex => _authProvider?.profile?.colorHex;
  String? get _userNickname => _authProvider?.profile?.nickname;

  // --- 초기화 ---
  bool get isInitialized => _isInitialized;
  Future<void> get initializationFuture => _initCompleter.future;

  /// 서버에서 모든 점령 타일을 불러오고 실시간 스트림을 연결하며, 로그인된 경우 발자취 데이터도 함께 불러옵니다.
  Future<void> init() async {
    try {
      final tiles = await _supabase.fetchAllCapturedTiles();
      for (final tile in tiles) {
        _capturedTiles[tile.id] = tile;
      }

      final myId = _userId;
      if (myId != null) {
        // 초기화 프로세스가 발자취 네트워크 대기에 블로킹되지 않도록 비동기 백그라운드 처리
        loadFootprints(myId).catchError((e) {
          debugPrint('⚠️ 초기 발자취 백그라운드 로드 실패: $e');
        });
      }
    } catch (e) {
      debugPrint('GameTileProvider 초기 데이터 로드 실패: $e');
    } finally {
      _isInitialized = true;
      if (!_initCompleter.isCompleted) _initCompleter.complete();
      notifyListeners();
    }
    _tilesStreamSub = _supabase.capturedTilesStream.listen(
      _onTilesUpdated,
      onError: (e) => debugPrint('⚠️ 점령 타일 스트림 에러: $e'),
    );
  }

  // --- Footprint CRUD ---

  /// 서버 및 로컬 캐시에서 사용자의 발자취 데이터를 불러와 캐시를 구축합니다.
  Future<void> loadFootprints(String userId) async {
    try {
      // 1. 로컬 SharedPreferences 백업 데이터를 먼저 읽어와 캐시에 사전 탑재
      final localMap = await PreferencesService.getLocalFootprints();
      for (final entry in localMap.entries) {
        final time = DateTime.tryParse(entry.value) ?? DateTime.now();
        _footprints[entry.key] = FootprintTile(
          tileId: entry.key,
          recordedAt: time,
        );
      }
      notifyListeners();
      debugPrint('📦 로컬 발자취 ${localMap.length}개 로드 완료');

      // 2. Supabase DB 서버 데이터 비동기 조회하여 캐시 병합 및 동기화
      final list = await _supabase.fetchUserFootprints(userId);
      for (final tile in list) {
        _footprints[tile.tileId] = tile;
      }
      notifyListeners();

      // 3. 최신 병합 상태를 로컬 SharedPreferences에 다시 영구 백업
      final Map<String, String> toSaveMap = {};
      _footprints.forEach((k, v) {
        toSaveMap[k] = v.recordedAt.toUtc().toIso8601String();
      });
      await PreferencesService.saveLocalFootprints(toSaveMap);

      debugPrint('📦 서버 발자취 ${list.length}개 동기화 완료 (총: ${_footprints.length}개)');
    } catch (e) {
      debugPrint('❌ 발자취 로드 실패: $e');
    }
  }

  /// 새로운 발자취를 추가합니다. 이미 캐싱되어 있다면 서버/로컬 추가를 건너뜁니다.
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

    final newFootprint = FootprintTile(
      tileId: tileId,
      recordedAt: truncatedTime,
    );

    // 1. 로컬 캐시에 즉각 추가하여 빠른 반응 속도 확보
    _footprints[tileId] = newFootprint;
    notifyListeners();

    // 2. 로컬 SharedPreferences 백업 즉각 업데이트 (서버 실패나 지연 시에도 디바이스에 보존되도록)
    try {
      final localMap = await PreferencesService.getLocalFootprints();
      localMap[tileId] = truncatedTime.toUtc().toIso8601String();
      await PreferencesService.saveLocalFootprints(localMap);
    } catch (e) {
      debugPrint('⚠️ 발자취 로드/세이브 로컬 SharedPreferences 실패: $e');
    }

    // 3. 백그라운드 서버 저장 (실패하더라도 로컬에는 보존하여 롤백하지 않고 유지보수성 향상)
    final success = await _supabase.recordFootprint(userId, tileId, truncatedTime);
    if (!success) {
      debugPrint('⚠️ 발자취 서버 동기화 실패 (로컬 디바이스에는 정상 보존): $tileId');
    }
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

  // --- Stream / 침공 감지 ---
  /// 실시간 DB 변경 스트림을 통해 점령 타일 목록이 업데이트되었을 때 
  /// 침공을 감지하고 로컬 캐시를 갱신합니다.
  void _onTilesUpdated(List<HexTile> tiles) {
    final auth = _authProvider;
    if (auth?.user == null) return;

    bool changed = false;
    bool invasionDetected = false;

    final myMainBaseId = auth!.profile?.mainBaseTileId;

    // 1. 삭제된 타일 소거
    final incomingIds = tiles.map((t) => t.id).toSet();
    final localIds = _capturedTiles.keys.toSet();
    final removedIds = localIds.difference(incomingIds);
    for (final id in removedIds) {
      _capturedTiles.remove(id);
      changed = true;
    }

    // 2. 신규 및 업데이트 타일 반영 + 침공 감지
    for (final tile in tiles) {
      if (tile.id != myMainBaseId) {
        final oldTile = _capturedTiles[tile.id];
        if (oldTile != null &&
            oldTile.userId == auth.user!.id &&
            tile.userId != auth.user!.id) {
          invasionDetected = true;
        }
      }

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

    if (invasionDetected) {
      onInvasionDetected?.call();
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// 서버에서 모든 타일을 다시 불러와 캐시를 갱신합니다.
  Future<void> refreshTilesFromServer() async {
    if (!_isInitialized) return;
    try {
      final tiles = await _supabase.fetchAllCapturedTiles();
      _onTilesUpdated(tiles);
    } catch (e) {
      debugPrint('❌ 타일 서버 동기화 실패: $e');
    }
  }

  /// 현재 위치의 헥사곤 타일 점령 상태를 서버 기준으로 실시간 확인합니다.
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

  // --- 정리 ---
  @override
  void dispose() {
    _tilesStreamSub?.cancel();
    super.dispose();
  }
}
