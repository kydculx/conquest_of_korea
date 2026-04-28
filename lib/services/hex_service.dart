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
}
