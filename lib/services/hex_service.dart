import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../core/constants.dart';

/// 지리 좌표(위도, 경도)와 전술 맵의 타일 시스템(Hex Grid) 간의 변환을 담당하는 서비스
/// Flat-top 헥사곤 그리드 알고리즘을 사용합니다.
class HexService {
  static const double originLat = 37.5665;
  static const double originLng = 126.9780;

  /// 하버사인(Haversine) 공식을 사용하여 두 지점 사이의 거리를 계산 (미터 단위)
  static double calculateDistance(LatLng p1, LatLng p2) {
    const double R = 6371000; // 지구 반경 (m)
    final double phi1 = p1.latitude * math.pi / 180;
    final double phi2 = p2.latitude * math.pi / 180;
    final double dPhi = (p2.latitude - p1.latitude) * math.pi / 180;
    final double dLambda = (p2.longitude - p1.longitude) * math.pi / 180;

    final double a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) * math.cos(phi2) * math.sin(dLambda / 2) * math.sin(dLambda / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }

  /// 실수 부동소수점 큐브 좌표를 가장 가까운 정수 헥사곤 좌표로 반올림
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

  /// 위도/경도를 전술 맵의 헥사곤 좌표(q, r)로 변환
  static Map<String, int> latLngToHex(LatLng location, {double hexSize = GameConstants.tileSize}) {
    final double latRad = originLat * math.pi / 180;
    final double x = (location.longitude - originLng) * (111320 * math.cos(latRad) / hexSize);
    final double y = (location.latitude - originLat) * (111320 / hexSize);

    // Flat-top 헥사곤 수학 공식 적용
    final double q = (math.sqrt(3) / 3) * x - (1 / 3) * y;
    final double r = (2 / 3) * y;

    final Map<String, int> cube = cubeRound(q, -q - r, r);
    return {'q': cube['x']!, 'r': cube['z']!};
  }

  /// 헥사곤 좌표(q, r)를 위도/경도 중심점으로 변환
  static LatLng hexToLatLng(int q, int r, {double hexSize = GameConstants.tileSize}) {
    final double x = math.sqrt(3) * q + (math.sqrt(3) / 2) * r;
    final double y = (3 / 2) * r.toDouble();

    final double latRad = originLat * math.pi / 180;
    final double lat = (y * hexSize / 111320) + originLat;
    final double lng = (x * hexSize / (111320 * math.cos(latRad))) + originLng;

    return LatLng(lat, lng);
  }

  /// 특정 타일(q, r)의 6개 꼭짓점 위도/경도 좌표를 계산
  static List<LatLng> getHexCorners(int q, int r, {double hexSize = GameConstants.tileSize}) {
    final LatLng center = hexToLatLng(q, r, hexSize: hexSize);
    final double latRad = originLat * math.pi / 180;
    final double latScale = hexSize / 111320;
    final double lngScale = hexSize / (111320 * math.cos(latRad));
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

  /// 두 헥사곤 타일 간의 거리(Ring 수)를 계산
  static int hexDistance(int q1, int r1, int q2, int r2) {
    final int x1 = q1;
    final int z1 = r1;
    final int y1 = -q1 - r1;

    final int x2 = q2;
    final int z2 = r2;
    final int y2 = -q2 - r2;

    return ((x1 - x2).abs() + (y1 - y2).abs() + (z1 - z2).abs()) ~/ 2;
  }

  /// 두 헥사곤 타일 간의 최단 경로(경유하는 모든 타일 좌표 리스트)를 계산
  static List<Map<String, int>> hexLine(int q1, int r1, int q2, int r2) {
    final int dist = hexDistance(q1, r1, q2, r2);
    if (dist == 0) {
      return [
        {'q': q1, 'r': r1}
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
