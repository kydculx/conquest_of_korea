import 'package:latlong2/latlong.dart';

/// 지도의 기본 위치, 줌 레벨 및 제공 스타일 설정을 관리하는 클래스
class MapConfig {
  /// 지도의 기본 초기 좌표 (0.0, 0.0)
  static const LatLng defaultPosition = LatLng(0.0, 0.0);

  /// 지도의 기본 줌 레벨
  static const double defaultZoom = 13.0;

  /// 지도의 최소 줌 레벨
  static const double minZoom = 8.0;

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
        1.35, 0.15, 0.45, 0, 10.0, // Red (솜사탕 핑크 로즈 채도 강화, 화사한 오프셋 추가)
        0.10, 1.20, 0.25, 0, 15.0, // Green (상큼하고 맑은 라임 민트 톤 증폭)
        0.15, 0.15, 1.65, 0, 30.0, // Blue (세련되고 밝은 스카이 블루 채도/명도 대폭 향상)
        0, 0, 0, 1, 0, // Alpha
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
