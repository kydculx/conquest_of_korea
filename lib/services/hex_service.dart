import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../core/constants/game_config.dart';

/// 지리 좌표(위도, 경도)와 지도상의 타일 시스템(Hex Grid) 간의 변환 및 헥사곤 좌표 연산을 담당하는 서비스 클래스
/// Flat-top 헥사곤 그리드 알고리즘을 준수합니다.
class HexService {
  /// 그리드 변환 시 기준점으로 삼는 기준 위도 (서울 중심부)
  static const double originLat = 37.5665;

  /// 그리드 변환 시 기준점으로 삼는 기준 경도 (서울 중심부)
  static const double originLng = 126.9780;

  /// Web Mercator 투영에 사용하는 지구 반경 (m)
  static const double _earthRadius = 6378137.0;

  /// 기준점(서울)에서의 Mercator 축척. 기존 그리드와 같은 타일 크기를 유지합니다.
  static const double _originLatRad = originLat * math.pi / 180;
  static final double _mercatorScale = math.cos(_originLatRad);

  /// 헥사곤 그리드 BFS 탐색 시 사용할 6방향 인접 타일 좌표 오프셋
  static const hexDirections = [
    [1, 0],
    [1, -1],
    [0, -1],
    [-1, 0],
    [-1, 1],
    [0, 1],
  ];

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

  /// 물리 위도/경도 좌표를 Web Mercator 평면 좌표로 투영한 뒤 헥사곤 좌표(q, r)로 변환합니다.
  ///
  /// 지도(flutter_map, Google Maps)가 Web Mercator를 사용하므로, 헥사곤도 같은
  /// 투영 평면에서 정의해야 모든 위도에서 화면상 동일한 모양으로 보입니다.
  static Map<String, int> latLngToHex(
    LatLng location, {
    double hexSize = GameConfig.tileSize,
  }) {
    final double latRad = location.latitude * math.pi / 180;
    final double xMeters =
        _earthRadius *
        (location.longitude - originLng) *
        math.pi /
        180 *
        _mercatorScale;
    final double yMeters =
        _earthRadius *
        math.log(
          math.tan(math.pi / 4 + latRad / 2) /
              math.tan(math.pi / 4 + _originLatRad / 2),
        ) *
        _mercatorScale;

    final double x = xMeters / hexSize;
    final double y = yMeters / hexSize;

    final double q = (math.sqrt(3) / 3) * x - (1 / 3) * y;
    final double r = (2 / 3) * y;

    final Map<String, int> cube = cubeRound(q, -q - r, r);
    return {'q': cube['x']!, 'r': cube['z']!};
  }

  /// 헥사곤 좌표(q, r)를 Web Mercator 평면 좌표로 바꾼 뒤 위도/경도 중심 좌표로 역변환합니다.
  static LatLng hexToLatLng(
    int q,
    int r, {
    double hexSize = GameConfig.tileSize,
  }) {
    final List<double> meters = _hexToMeters(q, r, hexSize);
    return _metersToLatLng(meters[0], meters[1]);
  }

  /// 특정 타일(q, r)의 외곽 테두리를 형성하는 6개 꼭짓점의 위도/경도 좌표 목록을 계산하여 반환합니다.
  ///
  /// 꼭짓점은 Mercator 평면에서 정육각형으로 배치한 뒤 위경도로 역변환합니다.
  static List<LatLng> getHexCorners(
    int q,
    int r, {
    double hexSize = GameConfig.tileSize,
  }) {
    final List<double> meters = _hexToMeters(q, r, hexSize);
    final List<LatLng> corners = [];

    for (int i = 0; i < 6; i++) {
      final double angleDeg = 60.0 * i - 30.0;
      final double angleRad = (math.pi / 180.0) * angleDeg;
      final double xMeters = meters[0] + math.cos(angleRad) * hexSize;
      final double yMeters = meters[1] + math.sin(angleRad) * hexSize;
      corners.add(_metersToLatLng(xMeters, yMeters));
    }
    return corners;
  }

  /// 헥사곤 좌표(q, r)를 Mercator 평면의 미터 좌표로 변환합니다.
  static List<double> _hexToMeters(int q, int r, double hexSize) {
    final double x = math.sqrt(3) * q + (math.sqrt(3) / 2) * r;
    final double y = 1.5 * r;
    return [x * hexSize, y * hexSize];
  }

  /// Mercator 평면의 미터 좌표를 위도/경도로 역변환합니다.
  static LatLng _metersToLatLng(double xMeters, double yMeters) {
    final double latRad =
        2 *
            math.atan(
              math.exp(yMeters / (_earthRadius * _mercatorScale)) *
                  math.tan(math.pi / 4 + _originLatRad / 2),
            ) -
        math.pi / 2;
    final double lng =
        originLng + (xMeters / (_earthRadius * _mercatorScale)) * 180 / math.pi;
    return LatLng(latRad * 180 / math.pi, lng);
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

  /// 헥사 좌표 (q, r)를 기반으로 타일 ID 문자열('hex_q_r')을 생성합니다.
  /// [hexSize]가 제공되고 기본 크기(lodSize0=100)가 아닌 경우 'hex_{sizeInt}_{q}_{r}' 형식으로 생성합니다.
  static String tileId(int q, int r, {double? hexSize}) {
    if (hexSize != null && hexSize != GameConfig.lodSize0) {
      return 'hex_${hexSize.toInt()}_${q}_$r';
    }
    return 'hex_${q}_$r';
  }

  /// 타일 ID 문자열(예: 'hex_q_r' 또는 'hex_size_q_r')을 분석 파싱하여 정수형 q, r 좌표 및 줌 스케일 크기 정보를 안전하게 추출합니다.
  /// 파싱 실패 시 null을 반환하여 강력한 가드 처리를 제공합니다.
  static Map<String, dynamic>? parseTileId(String id) {
    final parts = id.split('_');
    if (parts.length == 3 && parts[0] == 'hex') {
      final q = int.tryParse(parts[1]);
      final r = int.tryParse(parts[2]);
      if (q != null && r != null) {
        return {'q': q, 'r': r, 'size': null};
      }
    } else if (parts.length == 4 && parts[0] == 'hex') {
      final size = double.tryParse(parts[1]);
      final q = int.tryParse(parts[2]);
      final r = int.tryParse(parts[3]);
      if (q != null && r != null) {
        return {'q': q, 'r': r, 'size': size};
      }
    }
    return null;
  }
}
