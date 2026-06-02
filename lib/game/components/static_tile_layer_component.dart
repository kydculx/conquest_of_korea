import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/game_config.dart';
import '../../models/tile_model.dart';
import '../../services/hex_service.dart';
import '../conquest_game.dart';

/// 이미 점령이 완료된 정적 타일들을 대량으로 화면에 그릴 때,
/// 매 프레임 개별 컴포넌트로 그리는 대신 ui.PictureRecorder로
/// 단 한 번의 녹화(Recording)를 거쳐 캐싱하여 단 1회의 드로우 콜로 렌더링하는 고성능 최적화 배경 레이어 컴포넌트
class StaticTileLayerComponent extends PositionComponent
    with HasGameReference<ConquestGame> {
  
  /// 녹화된 정적 타일 전체 이미지 캐시 객체
  ui.Picture? _cachedPicture;

  /// 캐시가 무효화되어 다음 프레임에 녹화를 갱신해야 하는지 여부 플래그
  bool _needsUpdate = true;

  /// 서버에서 수신한 점령 타일 목록 캐시 레퍼런스
  Map<String, HexTile> _capturedTiles = {};

  StaticTileLayerComponent() {
    priority = 0; // 최하단 배경 레이어로 고정
  }

  /// 타일 목록 데이터 및 맵 투영 상태가 갱신되었을 때 정적 캐시를 무효화하고 데이터를 갱신합니다.
  void updateTiles(Map<String, HexTile> capturedTiles) {
    _capturedTiles = capturedTiles;
    invalidate();
  }

  /// 지도 줌, 스크롤 동작이 발생하거나 데이터가 바뀌어 다음 렌더 시점에 캐시를 재생성하도록 지시합니다.
  void invalidate() {
    _needsUpdate = true;
  }

  @override
  void render(Canvas canvas) {
    if (_needsUpdate) {
      _rebuildCache();
    }

    // 🚀 드로우 콜 단 1회로 모든 정적 타일을 일괄 드로잉!
    if (_cachedPicture != null) {
      canvas.drawPicture(_cachedPicture!);
    }
  }

  /// PictureRecorder를 가동하여 화면 영역(프러스텀 컬링 적용) 내 정적 타일들을 일괄로 이미지 드로잉 녹화합니다.
  void _rebuildCache() {
    final recorder = ui.PictureRecorder();
    final recordingCanvas = ui.Canvas(recorder);

    final MapController? mapController = game.mapController;
    if (mapController == null || _capturedTiles.isEmpty) {
      _cachedPicture = recorder.endRecording();
      _needsUpdate = false;
      return;
    }

    final gameSize = game.size;
    final String? currentUserId = game.currentUserId;
    final String? capturingTileId = game.satelliteCapturingTileId;
    final bool isSatelliteCapturing = game.isSatelliteCapturing;

    _capturedTiles.forEach((id, data) {
      // 1. 현재 실시간 원격/물리 점령이 시도 중인 동적 타일은 정적 캐시 레이어에서 제외합니다.
      final bool isCurrentlyCapturing = isSatelliteCapturing && id == capturingTileId;
      if (isCurrentlyCapturing) return;

      // 2. 각 타일의 H3 헥사곤 좌표(q, r)를 현재 맵 스케일에 맞춰 스크린 꼭짓점 리스트(Offset)로 투영
      final corners = _calcScreenCorners(mapController, data.q, data.r);
      if (corners.isEmpty) return;

      // 3. 프러스텀 컬링: 화면 범위 밖의 타일은 스킵하여 버퍼 낭비를 최소화
      final isVisible = corners.any(
        (c) =>
            c.dx >= -50 &&
            c.dx <= gameSize.x + 50 &&
            c.dy >= -50 &&
            c.dy <= gameSize.y + 50,
      );
      if (!isVisible) return;

      // 4. 소유 요원에 따른 전술 컬러 결정
      final targetTileColorHex = (data.userId == currentUserId)
          ? GameColors.myTileColorHex
          : GameColors.enemyTileColorHex;

      // 5. 3D 입체 젤리 타일 녹화 드로잉 실행
      _drawSingleTile3D(recordingCanvas, corners, targetTileColorHex);
    });

    _cachedPicture = recorder.endRecording();
    _needsUpdate = false;
  }

  /// 지도의 특정 헥사곤 좌표(q, r)의 외각 6개 꼭짓점을 디바이스 스크린 픽셀 좌표(Offset) 목록으로 맵핑하여 계산합니다.
  List<Offset> _calcScreenCorners(MapController mapController, int q, int r) {
    final corners = HexService.getHexCorners(q, r);
    return corners.map((latlng) {
      final offset = mapController.camera.latLngToScreenOffset(latlng);
      return Offset(offset.dx, offset.dy);
    }).toList();
  }

  /// 3D 보드게임 칩 & 비대칭 광택 젤리 스펙큘러 입체 스타일의 타일 하나를 레코딩 캔버스에 그립니다.
  void _drawSingleTile3D(Canvas canvas, List<Offset> corners, String? colorHex) {
    if (colorHex == null) return;
    final Color baseColor = _parseColor(colorHex) ?? GameColors.transparent;

    // 타일의 중심점 계산
    double cx = 0, cy = 0;
    for (final c in corners) {
      cx += c.dx;
      cy += c.dy;
    }
    cx /= corners.length;
    cy /= corners.length;

    // 헥사곤 반지름 계산
    double radSum = 0;
    for (final c in corners) {
      final dx = c.dx - cx;
      final dy = c.dy - cy;
      radSum += math.sqrt(dx * dx + dy * dy);
    }
    final double tileRadius = radSum / corners.length;

    // 아기자기한 캐주얼 헥사칩 둥글기 수준 (육각형 본래 대칭각과 둥글기의 균형 조율)
    final double cornerRadius = math.min(8.0, tileRadius * 0.26);
    // 타일 간의 아기자기한 보드게임형 갭(Padding) 생성
    const double padding = 2.2;

    // 1) 패딩이 적용된 수축 꼭짓점 산출
    final List<Offset> insetCorners = [];
    for (int i = 0; i < corners.length; i++) {
      final c = corners[i];
      final dx = cx - c.dx;
      final dy = cy - c.dy;
      final dist = math.sqrt(dx * dx + dy * dy);

      final double insetX = dist > padding ? c.dx + (dx / dist) * padding : c.dx;
      final double insetY = dist > padding ? c.dy + (dy / dist) * padding : c.dy;
      insetCorners.add(Offset(insetX, insetY));
    }

    // 2) 베지에 곡선 기반 둥근 육각형 그리기 패스 생성
    final path = Path();
    for (int i = 0; i < insetCorners.length; i++) {
      final current = insetCorners[i];
      final prev = insetCorners[(i - 1 + insetCorners.length) % insetCorners.length];
      final next = insetCorners[(i + 1) % insetCorners.length];

      final vPrevX = prev.dx - current.dx;
      final vPrevY = prev.dy - current.dy;
      final lenPrev = math.sqrt(vPrevX * vPrevX + vPrevY * vPrevY);

      final vNextX = next.dx - current.dx;
      final vNextY = next.dy - current.dy;
      final lenNext = math.sqrt(vNextX * vNextX + vNextY * vNextY);

      final double r = math.min(
        cornerRadius,
        math.min(lenPrev / 2, lenNext / 2),
      );

      final startX = current.dx + (vPrevX / lenPrev) * r;
      final startY = current.dy + (vPrevY / lenPrev) * r;

      final endX = current.dx + (vNextX / lenNext) * r;
      final endY = current.dy + (vNextY / lenNext) * r;

      if (i == 0) {
        path.moveTo(startX, startY);
      } else {
        path.lineTo(startX, startY);
      }
      path.quadraticBezierTo(current.dx, current.dy, endX, endY);
    }
    path.close();

    // 3) 3D 드롭 섀도우 (바닥 그림자 효과로 공중에 입체적으로 떠 있는 보드게임 칩 느낌 형성)
    canvas.save();
    canvas.translate(0, 3.5); // 아래로 3.5px 오프셋
    final Paint shadowPaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.32)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5); // 흐림 효과 가미
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // 4) 비대칭 specularity 광원 효과를 가미한 스펙큘러 그라데이션 설계 (빛이 좌측 상단 45도에서 쬐는 볼륨 엠보싱)
    final double gradientRadius = tileRadius * 1.15;
    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill;
    
    fillPaint.shader = ui.Gradient.radial(
      Offset(cx, cy),
      gradientRadius,
      [
        const Color(0xFFFFFFFF).withValues(alpha: 0.75), // 좌측 상단 반사Specular 하이라이트
        baseColor.withValues(alpha: GameConfig.tileOpacity * 0.65), // 바디 기본 색상
        baseColor.withValues(alpha: GameConfig.tileOpacity * 1.45), // 하단 음영 섀도우 대비 쫀득한 채색
      ],
      const [0.0, 0.28, 1.0],
      TileMode.clamp,
      null,
      Offset(cx - tileRadius * 0.35, cy - tileRadius * 0.35), // 광원 중심(Focal)을 좌측 상단으로 이동!
      0.0,
    );

    // 5) 3D 입체 젤리 바디 드로잉
    canvas.drawPath(path, fillPaint);

    // 6) 윗면의 부드러운 하이라이트(림 라이트/베벨 입체감) 테두리 그리기
    final Paint lightBorderPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, lightBorderPaint);

    // 7) 아래쪽 어두운 입체 음영 테두리 그리기
    final Paint darkBorderPaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(path, darkBorderPaint);
  }

  /// 16진수 색상 디코딩 유틸리티
  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return null;
    }
  }
}
