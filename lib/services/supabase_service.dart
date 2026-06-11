import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_config.dart';
import '../models/tile_model.dart';
import '../models/user_profile.dart';

/// Supabase 백엔드 데이터베이스 및 Realtime 데이터 처리를 담당하는 네트워크 통신 서비스 클래스
class SupabaseService {
  /// Supabase 응답(Map 타입이 아닌 동적 값)을 안전하게 `Map<String, dynamic>`으로 변환
  static Map<String, dynamic> _toMap(dynamic value) =>
      Map<String, dynamic>.from(value);

  /// 마지막으로 발생한 RPC 또는 데이터베이스 에러 메시지
  String? lastError;

  /// Supabase SDK 초기화 및 접속 정보 설정을 처리합니다.
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        debug: kDebugMode,
      );
      debugPrint('✅ Supabase 초기화 성공');
    } catch (e) {
      debugPrint('❌ Supabase 초기화 실패: $e');
      rethrow;
    }
  }

  /// Supabase SDK 클라이언트 인스턴스 게터
  SupabaseClient get _client => Supabase.instance.client;
  SupabaseClient get client => _client;

  /// 데이터베이스에 저장된 모든 점령 완료 타일 목록을 비동기 조회하여 반환합니다.
  Future<List<HexTile>> fetchAllCapturedTiles() async {
    debugPrint('🔍 점령 타일 데이터 요청 중...');
    final response = await _client.from('captured_tiles').select('*');
    final tiles = (response as List)
        .map((e) => HexTile.fromJson(e as Map<String, dynamic>))
        .toList();
    debugPrint('📦 ${tiles.length}개 타일 수신 완료');
    return tiles;
  }

  /// 실시간 점령 현황 동기화를 위한 Supabase Realtime 스트림을 제공합니다.
  Stream<List<HexTile>> get capturedTilesStream {
    return _client
        .from('captured_tiles')
        .stream(primaryKey: ['id'])
        .map(
          (list) => list
              .map((e) => HexTile.fromJson(_toMap(e)))
              .toList(),
        );
  }

  Future<bool> captureTile(HexTile tile) async {
    try {
      lastError = null;
      final params = {
        'p_tile_id': tile.id,
        'p_q': tile.q,
        'p_r': tile.r,
        'p_user_id': tile.userId,
        'p_color_hex': tile.colorHex,
        'p_target_capture_count': tile.captureCount,
        'p_shield_duration_seconds': 0,
      };
      debugPrint('🏹 RPC 점령 안전 트랜잭션 전송 중: ${tile.id}');

      final response = await _client.rpc('safe_capture_tile', params: params);

      debugPrint('🚀 RPC 트랜잭션 처리 결과: $response');
      return response as bool;
    } catch (e, stack) {
      lastError = e.toString();
      debugPrint('❌ RPC 점령 전송 실패: $e');
      debugPrint('❌ 에러 스택트레이스: $stack');
      return false;
    }
  }

  /// 지정한 타일 ID의 최신 소유 상황을 서버 데이터베이스로부터 확인하여 타일 소유 상태 [TileStatus]로 반환합니다.
  Future<TileStatus> checkTileStatusFromServer(
    String tileId,
    String currentUserId,
  ) async {
    try {
      final response = await _client
          .from('captured_tiles')
          .select('user_id')
          .eq('id', tileId)
          .maybeSingle();

      if (response == null) return TileStatus.empty;

      final data = _toMap(response);
      final String? ownerId = data['user_id'];
      if (ownerId == currentUserId) return TileStatus.mine;

      return TileStatus.enemy;
    } catch (e) {
      debugPrint('❌ 타일 상태 서버 조회 실패: $e');
      return TileStatus.empty; // 오류 시 기본값
    }
  }

  /// 특정 타일 ID에 대한 상세 점령 정보를 단일 레코드로 조회하여 반환합니다. 점령되지 않은 중립 타일일 시 null을 반환합니다.
  Future<HexTile?> fetchTile(String tileId) async {
    try {
      final response = await _client
          .from('captured_tiles')
          .select('*')
          .eq('id', tileId)
          .maybeSingle();

      if (response == null) return null;
      return HexTile.fromJson(_toMap(response));
    } catch (e) {
      debugPrint('❌ 단일 타일 서버 조회 실패: $e');
      return null;
    }
  }

  /// 서버의 글로벌 시스템 설정 테이블에서 골드 획득 배율(`gold_rate`) 설정을 가져옵니다.
  Future<double?> fetchGoldRate() async {
    try {
      final response = await _client
          .from('system_settings')
          .select('value')
          .eq('key', 'gold_rate')
          .maybeSingle();
      if (response == null) return null;
      return (response['value'] as num?)?.toDouble();
    } catch (e) {
      debugPrint('❌ gold_rate 조회 실패: $e');
      return null;
    }
  }

  /// 지정한 랭킹 타입에 따라 상위 100위까지의 요원 프로필 목록을 조회합니다.
  Future<List<UserProfile>> fetchTopRankings(String rankType) async {
    try {
      final response = await _client
          .from('profiles')
          .select('*')
          .order(rankType, ascending: false)
          .limit(100);

      return (response as List)
          .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ 랭킹 조회 실패 ($rankType): $e');
      return [];
    }
  }

  /// 특정 요원의 현재 랭킹 순위 숫자를 연산하여 반환합니다. (1부터 시작)
  Future<int> fetchMyRanking(
    String userId,
    String rankType,
    dynamic myValue,
  ) async {
    try {
      final queryVal = rankType == 'captured_tiles_count'
          ? (myValue as num).toInt()
          : myValue;

      final response = await _client
          .from('profiles')
          .select('id')
          .gt(rankType, queryVal);

      final count = (response as List).length;
      return count + 1;
    } catch (e) {
      debugPrint('❌ 내 순위 조회 실패 ($rankType): $e');
      return 0;
    }
  }
}
