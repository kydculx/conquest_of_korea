import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../core/constants/game_config.dart';

/// 지리 좌표(위도, 경도)와 전술 맵의 타일 시스템(Hex Grid) 간의 변환 및 헥사곤 좌표 연산을 담당하는 서비스 클래스
/// Flat-top 헥사곤 그리드 알고리즘을 준수합니다.
class HexService {
  /// 그리드 변환 시 기준점으로 삼는 기준 위도 (서울 중심부)
  static const double originLat = 37.5665;

  /// 그리드 변환 시 기준점으로 삼는 기준 경도 (서울 중심부)
  static const double originLng = 126.9780;

  /// 하버사인(Haversine) 공식을 사용하여 두 위경도 좌표점 사이의 물리적 거리를 계산하여 미터 단위로 반환합니다.
  static double calculateDistance(LatLng p1, LatLng p2) {
    const double R = 6371000; // 지구 반경 (m)
    final double phi1 = p1.latitude * math.pi / 180;
    final double phi2 = p2.latitude * math.pi / 180;
    final double dPhi = (p2.latitude - p1.latitude) * math.pi / 180;
    final double dLambda = (p2.longitude - p1.longitude) * math.pi / 180;

    final double a =
        math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(dLambda / 2) *
            math.sin(dLambda / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }

  /// 실수형 부동소수점 큐브 좌표를 가장 가까운 정수 헥사곤 큐브 좌표로 반올림하여 반환합니다.
  static Map<String, int> cubeRound(double x, double y, double z) {
    int rx = x.round();
    int ry = y.round();
    int rz = z.round();

    final double xDiff = (rx - x).abs();
    final double yDiff = (ry - y).abs();
    final double zDiff = (rz - z).abs();

    if (xDiff > yDiff && xDiff > zDiff) {
      rx = -ry - rz;
    } else if (yDiff > zDiff) {
      ry = -rx - rz;
    } else {
      rz = -rx - ry;
    }

    return {'x': rx, 'y': ry, 'z': rz};
  }

  /// 물리 위도/경도 좌표를 전술 맵의 정수 헥사곤 좌표(q, r) 쌍으로 계산 변환합니다.
  static Map<String, int> latLngToHex(
    LatLng location, {
    double hexSize = GameConfig.tileSize,
  }) {
    final double latRad = originLat * math.pi / 180;
    final double x =
        (location.longitude - originLng) *
        (111320 * math.cos(latRad) / hexSize);
    final double y = (location.latitude - originLat) * (111320 / hexSize);

    final double q = (math.sqrt(3) / 3) * x - (1 / 3) * y;
    final double r = (2 / 3) * y;

    final Map<String, int> cube = cubeRound(q, -q - r, r);
    return {'q': cube['x']!, 'r': cube['z']!};
  }

  /// 헥사곤 좌표(q, r)를 물리 지도 상의 위도/경도 중심 좌표(LatLng)로 역변환합니다.
  static LatLng hexToLatLng(
    int q,
    int r, {
    double hexSize = GameConfig.tileSize,
  }) {
    final double x = math.sqrt(3) * q + (math.sqrt(3) / 2) * r;
    final double y = (3 / 2) * r.toDouble();

    final double latRad = originLat * math.pi / 180;
    final double lat = (y * hexSize / 111320) + originLat;
    final double lng = (x * hexSize / (111320 * math.cos(latRad))) + originLng;

    return LatLng(lat, lng);
  }

  /// 특정 타일(q, r)의 외곽 테두리를 형성하는 6개 꼭짓점의 위도/경도 좌표 목록을 계산하여 반환합니다.
  static List<LatLng> getHexCorners(
    int q,
    int r, {
    double hexSize = GameConfig.tileSize,
  }) {
    final LatLng center = hexToLatLng(q, r, hexSize: hexSize);
    final double latRad = originLat * math.pi / 180; // 일관되게 기준 위도(originLat)의 cos 사용
    final double latScale = hexSize / 111320;
    final double lngScale = hexSize / (111320 * math.cos(latRad)); // 이웃 타일 간의 가로 너비가 균일하게 맞물림
    final List<LatLng> corners = [];

    for (int i = 0; i < 6; i++) {
      final double angleDeg = 60.0 * i - 30.0;
      final double angleRad = (math.pi / 180.0) * angleDeg;
      final double lat = center.latitude + latScale * math.sin(angleRad);
      final double lng = center.longitude + lngScale * math.cos(angleRad);
      corners.add(LatLng(lat, lng));
    }
    return corners;
  }

  /// 두 헥사곤 좌표쌍 간의 거리를 헥사곤 그리드 링(Ring) 개수 단위로 계산하여 반환합니다.
  static int hexDistance(int q1, int r1, int q2, int r2) {
    final int x1 = q1;
    final int z1 = r1;
    final int y1 = -q1 - r1;

    final int x2 = q2;
    final int z2 = r2;
    final int y2 = -q2 - r2;

    return ((x1 - x2).abs() + (y1 - y2).abs() + (z1 - z2).abs()) ~/ 2;
  }

  /// 출발 타일(q1, r1)에서 도착 타일(q2, r2)까지 헥사곤 그리드 상을 잇는 최단 선형 경로에 포함된 모든 헥사곤 타일 좌표 리스트를 계산합니다.
  static List<Map<String, int>> hexLine(int q1, int r1, int q2, int r2) {
    final int dist = hexDistance(q1, r1, q2, r2);
    if (dist == 0) {
      return [
        {'q': q1, 'r': r1},
      ];
    }

    final List<Map<String, int>> results = [];
    final double x1 = q1.toDouble();
    final double z1 = r1.toDouble();
    final double y1 = (-q1 - r1).toDouble();

    final double x2 = q2.toDouble();
    final double z2 = r2.toDouble();
    final double y2 = (-q2 - r2).toDouble();

    for (int i = 0; i <= dist; i++) {
      final double t = dist == 0 ? 0.0 : i / dist.toDouble();
      final double x = x1 + (x2 - x1) * t;
      final double y = y1 + (y2 - y1) * t;
      final double z = z1 + (z2 - z1) * t;
      final rounded = cubeRound(x, y, z);
      results.add({'q': rounded['x']!, 'r': rounded['z']!});
    }
    return results;
  }
}
