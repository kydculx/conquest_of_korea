import 'package:latlong2/latlong.dart';

export 'constants/colors.dart';

class GameConstants {
  static const String appName = '한국정복 (Conquest)';

  // 지도 설정
  static const LatLng defaultPosition = LatLng(37.5665, 126.9780); // 서울시청
  static const double defaultZoom = 13.0;
  static const double minZoom = 7.0;
  static const double maxZoom = 17.0;
  static const double focusZoom = 16.0;
  static const double municipalBoundaryZoomThreshold = 9.5; // 시/군/구 경계 노출 임계값

  // 맵 이동 제한 구역 (남한 영토 기준 + Margin)
  static const LatLng mapBoundSouthWest = LatLng(32.000000, 123.500000);
  static const LatLng mapBoundNorthEast = LatLng(39.500000, 133.000000);

  // LOD 설정 (줌 퍼센트 기준)
  static const double lodThresholdTier1 = 30.0;
  static const double lodThresholdTier2 = 45.0; // 군청이 더 빨리 보이도록 조정

  // 텍스트 라벨 LOD 설정 (줌 퍼센트 기준)
  static const double textThresholdTier1 = 40.0;
  static const double textThresholdTier2 = 60.0;

  // 헥사곤 설정
  static const double tileSize = 100.0; // 헥사곤 크기 (미터 단위와 유사하게 사용)

  // GPS 설정
  static const double captureAccuracyThreshold = 15.0; // 물리 GPS 수준 (15m 이내만 허용)
  static const double highAccuracyThreshold = 10.0;

  // --- 점령 시스템 설정 ---
  static const Duration emptyTileDuration = Duration(seconds: 3);
  static const Duration enemyTileDuration = Duration(seconds: 10);
  static const int updateIntervalMs = 100;
  static const double captureDistanceThreshold = 40.0;

  // --- 서버 부하 방지 및 백그라운드 감시 설정 ---
  static const Duration serverCheckDelay = Duration(seconds: 3);
  static Duration backgroundCheckInterval = const Duration(
    seconds: 30,
  ); // 언제든 수정 가능
  // 점령 구역 투명도 (0.0 ~ 1.0)
  static const double tileOpacity = 0.5;

  // UI 스타일 (세부 색상 정의는 constants/colors.dart 참조)
  static const double hudOpacity = 0.8;

  static const int tileShieldDurationSeconds = 5; // 점령 성공 후 타일이 침공으로부터 보호(쉴드)되는 시간 (초)
  static const int initialCaptureDurationSeconds = 1; // 최초 점령시간 (수정하기 쉽도록 외부 변수로 분리)
  // 맵 스타일 리스트 (방대한 풀 세트)
  static const List<MapStyle> mapStyles = [
    MapStyle(
      name: '사이버',
      url: 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png',
      icon: 'grid_view',
      colorMatrix: <double>[
        0.1, 0.3, 0.1, 0, 0, // Red
        0.0, 1.6, 0.0, 0, 0, // Green (네온 그린 증폭)
        0.1, 0.3, 0.5, 0, 0, // Blue
        0, 0, 0, 1, 0, // Alpha
      ],
    ),
    MapStyle(
      name: '다크',
      url:
          'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}{r}.png',
      icon: 'dark_mode',
      colorMatrix: <double>[
        0.45, 0.0, 0.0, 0, 0, // Red (정직한 무채색을 위한 동일 배율)
        0.0, 0.45, 0.0, 0, 0, // Green (정직한 무채색을 위한 동일 배율)
        0.0, 0.0, 0.45, 0, 0, // Blue (푸른색 느낌을 완전히 걷어낸 동일 배율)
        0, 0, 0, 1, 0, // Alpha
      ],
    ),
    MapStyle(
      name: '위성',
      url:
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      icon: 'public',
    ),
    MapStyle(name: '외각', url: '', icon: 'layers_clear'),
  ];
}

class MapStyle {
  final String name;
  final String url;
  final String icon;
  final List<double>? colorMatrix;

  const MapStyle({
    required this.name,
    required this.url,
    required this.icon,
    this.colorMatrix,
  });
}
