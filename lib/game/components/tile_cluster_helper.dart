import 'package:latlong2/latlong.dart';
import '../../models/tile_model.dart';
import '../../services/hex_service.dart';
import '../../core/constants/game_config.dart';

/// 줌 레벨별 LOD 헥사곤 규격 결정, 타일 클러스터링(Clustering), 좌표 캐싱을 전담하는 헬퍼 클래스.
/// ConquestGame에서 순수 연산 로직을 분리합니다.
class TileClusterHelper {
  /// 타일 ID 기준 중심점 LatLng 지리적 불변 캐싱 맵 (중복 삼각함수 연산 차단)
  final Map<String, LatLng> tileCenterCache = {};

  /// 타일 ID 기준 6개 꼭짓점 LatLng 지리적 불변 캐싱 맵
  final Map<String, List<LatLng>> tileCornersCache = {};

  /// 현재 줌 레벨에 맞는 헥사곤 미터 규격(Size) 반환
  double getHexSizeForZoom(double zoom) {
    if (zoom >= GameConfig.lodZoomThreshold0) return GameConfig.lodSize0;
    if (zoom >= GameConfig.lodZoomThreshold1) return GameConfig.lodSize1;
    if (zoom >= GameConfig.lodZoomThreshold2) return GameConfig.lodSize2;
    if (zoom >= GameConfig.lodZoomThreshold3) return GameConfig.lodSize3;
    return GameConfig.lodSize4;
  }

  /// 현재 줌 레벨에 맞는 LOD 레벨(0 ~ 4) 반환
  int getLodLevelForZoom(double zoom) {
    if (zoom >= GameConfig.lodZoomThreshold0) return 0;
    if (zoom >= GameConfig.lodZoomThreshold1) return 1;
    if (zoom >= GameConfig.lodZoomThreshold2) return 2;
    if (zoom >= GameConfig.lodZoomThreshold3) return 3;
    return 4;
  }

  /// 줌 레벨 스케일(LOD)에 맞춘 고유 타일 ID 생성
  String getTileId(int q, int r, double hexSize) =>
      HexService.tileId(q, r, hexSize: hexSize);

  /// 소형 100m 기준의 타일 데이터를 현재 LOD dynamicSize 규격에 맞게 실시간 병합(Clustering)
  Map<String, HexTile> rebuildClusteredTiles(
    Map<String, HexTile> capturedTiles,
    double dynamicSize,
    String? currentUserId,
  ) {
    if (dynamicSize == GameConfig.lodSize0) {
      return Map.from(capturedTiles);
    }

    final Map<String, HexTile> clustered = {};
    capturedTiles.forEach((id, tile) {
      final smallCenter = _getTileCenter(tile.q, tile.r, id, GameConfig.lodSize0);

      final dynamicHex = HexService.latLngToHex(smallCenter, hexSize: dynamicSize);
      final dq = dynamicHex['q']!;
      final dr = dynamicHex['r']!;
      final String clusterId = getTileId(dq, dr, dynamicSize);

      final existing = clustered[clusterId];
      if (existing == null) {
        clustered[clusterId] = HexTile(
          id: clusterId,
          q: dq,
          r: dr,
          userId: tile.userId,
          // 발자취 타일처럼 colorHex로만 색이 결정되는 마커의 색상 유실 방지
          colorHex: tile.colorHex,
          capturedAt: tile.capturedAt,
          captureCount: tile.captureCount,
        );
      } else if (tile.userId == currentUserId) {
        clustered[clusterId] = HexTile(
          id: clusterId,
          q: dq,
          r: dr,
          userId: currentUserId!,
          colorHex: tile.colorHex,
          capturedAt: tile.capturedAt,
          captureCount: tile.captureCount,
        );
      }
    });

    return clustered;
  }

  /// 타일 ID와 헥사곤 규격을 조합한 캐시 키 생성.
  /// 동일한 LOD 0 타일 ID라도 렌더링 규격(hexSize)에 따라 중심/꼭짓점이 달라지므로
  /// 반드시 규격을 키에 포함하여 LOD 간 캐시 오염을 방지합니다.
  String _cacheKey(String id, double hexSize) => '${id}_$hexSize';

  /// 타일 ID에 상응하는 지리적 중심점 캐시 반환
  LatLng _getTileCenter(int q, int r, String id, double hexSize) {
    return tileCenterCache.putIfAbsent(
      _cacheKey(id, hexSize),
      () => HexService.hexToLatLng(q, r, hexSize: hexSize),
    );
  }

  /// 타일 ID에 상응하는 지리적 6개 꼭짓점 캐시 반환
  List<LatLng> _getTileCorners(int q, int r, String id, double hexSize) {
    return tileCornersCache.putIfAbsent(
      _cacheKey(id, hexSize),
      () => HexService.getHexCorners(q, r, hexSize: hexSize),
    );
  }

  /// 외부에서 타일 중심점 조회 (캐시 적용)
  LatLng getTileCenter(int q, int r, String id, double hexSize) =>
      _getTileCenter(q, r, id, hexSize);

  /// 외부에서 타일 꼭짓점 조회 (캐시 적용)
  List<LatLng> getTileCorners(int q, int r, String id, double hexSize) =>
      _getTileCorners(q, r, id, hexSize);
}
