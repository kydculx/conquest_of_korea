import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_config.dart';
import '../core/constants.dart';
import '../models/tile_model.dart';

/// Supabase 외부 통신 전담 서비스 (순수 I/O 레이어)
class SupabaseService {
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

  SupabaseClient get _client => Supabase.instance.client;

  /// 모든 점령 타일 조회
  Future<List<HexTile>> fetchAllCapturedTiles() async {
    debugPrint('🛰️ 점령 타일 데이터 요청 중...');
    final response = await _client.from('captured_tiles').select('*');
    final tiles = (response as List)
        .map((e) => HexTile.fromJson(e as Map<String, dynamic>))
        .toList();
    debugPrint('📦 ${tiles.length}개 타일 수신 완료');
    return tiles;
  }

  /// 점령 타일 실시간 스트림
  Stream<List<HexTile>> get capturedTilesStream {
    return _client
        .from('captured_tiles')
        .stream(primaryKey: ['id'])
        .map((list) => list.map(HexTile.fromJson).toList());
  }

  /// 타일 점령 정보 저장 (원자적 RPC 트랜잭션 호출)
  Future<bool> captureTile(HexTile tile) async {
    try {
      debugPrint('🏹 RPC 점령 안전 트랜잭션 전송 중: ${tile.id}');
      
      // Supabase RPC 안전 호출 체계 도입
      final response = await _client.rpc('safe_capture_tile', params: {
        'p_tile_id': tile.id,
        'p_q': tile.q,
        'p_r': tile.r,
        'p_user_id': tile.userId,
        'p_color_hex': tile.colorHex,
        'p_bounds': tile.bounds,
        'p_target_capture_count': tile.captureCount,
        'p_shield_duration_seconds': GameConstants.tileShieldDurationSeconds,
      });

      debugPrint('🚀 RPC 트랜잭션 처리 결과: $response');
      return response as bool;
    } catch (e) {
      debugPrint('❌ RPC 점령 전송 실패: $e');
      return false;
    }
  }

  /// 특정 타일의 점령 상태를 서버에서 조회하여 TileStatus로 반환
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

      final String? ownerId = response['user_id'];
      if (ownerId == currentUserId) return TileStatus.mine;

      return TileStatus.enemy;
    } catch (e) {
      debugPrint('❌ 타일 상태 서버 조회 실패: $e');
      return TileStatus.empty; // 오류 시 기본값
    }
  }

  /// 특정 타일 ID로 서버의 최신 점령 데이터 전체를 조회하여 반환하는 함수
  Future<HexTile?> fetchTile(String tileId) async {
    try {
      final response = await _client
          .from('captured_tiles')
          .select('*')
          .eq('id', tileId)
          .maybeSingle();

      if (response == null) return null;
      return HexTile.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ 단일 타일 서버 조회 실패: $e');
      return null;
    }
  }
}
