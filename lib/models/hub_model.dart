import 'package:latlong2/latlong.dart';

/// 전술 거점 타입
enum HubType {
  special,
  metropolitan,
  provincial,
  city,
  district,
  county;

  static HubType fromString(String value) {
    return HubType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HubType.city,
    );
  }
}

/// 전술 거점 데이터 모델
class TacticalHub {
  final String id;
  final String name;
  final LatLng location;
  final HubType type;
  final String region;

  const TacticalHub({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.region,
  });
}
