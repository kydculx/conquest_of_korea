import 'package:latlong2/latlong.dart';

/// 지도의 기본 위치, 줌 레벨 및 제공 스타일 설정을 관리하는 클래스
class MapConfig {
  /// 지도의 기본 초기 좌표 (0.0, 0.0)
  static const LatLng defaultPosition = LatLng(0.0, 0.0);

  /// 지도의 기본 줌 레벨
  static const double defaultZoom = 13.0;

  /// 지도의 최소 줌 레벨
  static const double minZoom = 5.0;

  /// 지도의 최대 줌 레벨
  static const double maxZoom = 16.0;

  /// 포커스 시 지도의 줌 레벨
  static const double focusZoom = 16.0;

  /// 앱에서 지원하는 지도 스타일 리스트
  static const List<MapStyle> mapStyles = [
    MapStyle(
      name: 'mapStyleDark',
      url: 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png',
      icon: 'dark_mode',
      colorMatrix: <double>[
        1.20, 0.20, 0.40, 0, -0.01, // Red (포근한 아기자기 파스텔 핑크)
        0.15, 0.95, 0.20, 0, -0.02, // Green (따뜻하고 귀여운 파스텔 민트)
        0.20, 0.20, 1.50, 0, 0.05,  // Blue (부드럽고 아늑한 다크 파스텔 밤빛)
        0, 0, 0, 1, 0,               // Alpha
      ],
    ),
    MapStyle(
      name: 'mapStyleSatellite',
      url:
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      icon: 'public',
    ),
  ];
}

/// 지도 스타일 정보를 나타내는 데이터 클래스
class MapStyle {
  /// 스타일 식별 키 명칭
  final String name;

  /// 타일 서버 URL
  final String url;

  /// 렌더링에 사용될 아이콘 명칭
  final String icon;

  /// 컬러 필터에 사용될 컬러 매트릭스 (RGB/Alpha 조절용)
  final List<double>? colorMatrix;

  /// MapStyle 생성자
  const MapStyle({
    required this.name,
    required this.url,
    required this.icon,
    this.colorMatrix,
  });
}
