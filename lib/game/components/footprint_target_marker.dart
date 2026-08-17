import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../services/hex_service.dart';
import '../conquest_game.dart';

/// [신규] 발자취 모드에서 선택한 타일의 네온 청록색 하이라이팅 조준 마커 컴포넌트
class FootprintTargetMarker extends PositionComponent
    with HasGameReference<ConquestGame> {
  final int q;
  final int r;
  final List<LatLng> _latLngCorners;
  List<Offset> _screenCorners = [];
  double _timer = 0;

  FootprintTargetMarker({required this.q, required this.r})
      : _latLngCorners = HexService.getHexCorners(q, r) {
    priority = 17;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    if (game.mapController != null) {
      _screenCorners = _latLngCorners.map((latlng) {
        final offset = game.mapController!.camera.latLngToScreenOffset(latlng);
        return Offset(offset.dx, offset.dy);
      }).toList();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_screenCorners.isEmpty) return;

    // 1. 중심점 계산
    double cx = 0, cy = 0;
    for (final c in _screenCorners) {
      cx += c.dx;
      cy += c.dy;
    }
    cx /= _screenCorners.length;
    cy /= _screenCorners.length;

    final double pulse = 1.0 + 0.1 * math.sin(_timer * 6.0);
    const themeColor = Color(0xFF00FFCC); // 발자취 전용 네온 청록색

    // 2. 헥사곤 하이라이트 그리기
    final path = Path();
    path.moveTo(_screenCorners[0].dx, _screenCorners[0].dy);
    for (int i = 1; i < _screenCorners.length; i++) {
      path.lineTo(_screenCorners[i].dx, _screenCorners[i].dy);
    }
    path.close();

    // 헥사곤 외곽선
    final strokePaint = Paint()
      ..color = themeColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 + pulse * 1.0
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // 헥사곤 내부 은은한 글로우 채우기
    final fillPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.12 + 0.04 * math.sin(_timer * 6.0))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. 조준 원 및 크로스라인 연출
    final double radius = 28.0 * pulse;
    final circlePaint = Paint()
      ..color = themeColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), radius, circlePaint);

    // 조준 십자선 그리기 (미세 격자선)
    final linePaint = Paint()
      ..color = themeColor.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(cx - radius - 5, cy), Offset(cx - radius + 3, cy), linePaint);
    canvas.drawLine(Offset(cx + radius - 3, cy), Offset(cx + radius + 5, cy), linePaint);
    canvas.drawLine(Offset(cx, cy - radius - 5), Offset(cx, cy - radius + 3), linePaint);
    canvas.drawLine(Offset(cx, cy + radius - 3), Offset(cx, cy + radius + 5), linePaint);
  }
}
