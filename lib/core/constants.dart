import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class GameConstants {
  static const String appName = '한국정복 (Conquest)';

  // 지도 설정
  static const LatLng defaultPosition = LatLng(37.5665, 126.9780); // 서울시청
  static const double defaultZoom = 13.0;
  static const double minZoom = 7.0;
  static const double maxZoom = 14.0;
  static const double focusZoom = 13.0;
  static const double municipalBoundaryZoomThreshold = 9.5; // 시/군/구 경계 노출 임계값

  // 맵 이동 제한 구역 (남한 영토 기준 + Margin)
  static const LatLng mapBoundSouthWest = LatLng(32.000000, 123.500000);
  static const LatLng mapBoundNorthEast = LatLng(39.500000, 133.000000);

  // LOD 설정 (줌 퍼센트 기준)
  static const double lodThresholdTier1 = 30.0;
  static const double lodThresholdTier2 = 45.0; // 군청이 더 빨리 보이도록 조정
  static const double lodMinZoom = 7.0;  // 실제 지도 최소 줌에 맞춤
  static const double lodMaxZoom = 14.0; // 실제 지도 최대 줌에 맞춤

  // 텍스트 라벨 LOD 설정 (줌 퍼센트 기준)
  static const double textThresholdTier1 = 40.0;
  static const double textThresholdTier2 = 60.0;

  // 헥사곤 설정
  static const double tileSize = 400.0; // 헥사곤 크기 (미터 단위와 유사하게 사용)

  // GPS 설정
  static const double captureAccuracyThreshold = 15.0; // 물리 GPS 수준 (15m 이내만 허용)
  static const double highAccuracyThreshold = 10.0;

  // 게임 설정
  static const Duration emptyTileDuration = Duration(seconds: 10);
  static const Duration enemyTileDuration = Duration(seconds: 60);
  static const int updateIntervalMs = 100;
  static const double captureRange = 150.0; // 점령 가능 범위 (m)

  // 팀 설정
  static const String teamBlueId = 'blue';
  static const String teamRedId = 'red';

  static const Color colorBlue = Color(0xFF3A8DFF);
  static const Color colorRed = Color(0xFFFF4757);
  static const Color colorAccent = Color(0xFF00FFD1);

  // UI 스타일
  static const double hudOpacity = 0.8;
  static const Color accentNeon = Color(0xFF00FFD1);

  // Legacy constants (retained for compatibility)
  static const Color teamBlue = Color(0xFF2196F3);
  static const Color teamRed = Color(0xFFF44336);
  static const Color tacticalGray = Color(0xFF263238);
  static const Color tacticalBlack = Color(0xFF000000); // 완전한 블랙으로 변경
  static const int captureDurationSeconds = 5;
  // 맵 스타일 리스트 (방대한 풀 세트)
  static const List<MapStyle> mapStyles = [
    MapStyle(
      name: '다크',
      url: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
      icon: 'dark_mode',
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
  const MapStyle({required this.name, required this.url, required this.icon});
}
