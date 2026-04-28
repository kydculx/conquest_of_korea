import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants.dart';

class PlayerComponent extends PositionComponent {
  LatLng _location = GameConstants.defaultPosition;
  LatLng get location => _location;
  double _heading = 0.0; // 라디안 단위

  @override
  Future<void> onLoad() async {
    size = Vector2(40, 40); // 가시성을 위해 크기 약간 키움
    anchor = Anchor.center;
  }

  void updateLocation(LatLng newLocation) {
    _location = newLocation;
  }

  void updateHeading(double degrees) {
    // 도(degree)를 라디안(radian)으로 변환 (북쪽이 0도 기준)
    _heading = degrees * (3.14159 / 180.0);
  }

  void updateScreenPosition(Offset offset) {
    position = Vector2(offset.dx, offset.dy);
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    
    // 0. 방향지시 부채꼴 (Heading Beam)
    final beamPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          GameConstants.accentNeon.withAlpha(150),
          GameConstants.accentNeon.withAlpha(0),
        ],
        stops: const [0.2, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.x * 2))
      ..style = PaintingStyle.fill;

    // 부채꼴 그리기 (현재 heading 기준 좌우 20도씩 총 40도 범위)
    // 캔버스 회전 적용
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_heading);
    canvas.translate(-center.dx, -center.dy);
    
    final ui.Path beamPath = ui.Path()
      ..moveTo(center.dx, center.dy)
      ..relativeLineTo(-size.x * 0.8, -size.x * 2.5) // 왼쪽 끝
      ..relativeLineTo(size.x * 1.6, 0) // 오른쪽 끝
      ..close();
    
    canvas.drawPath(beamPath, beamPaint);
    canvas.restore();

    // 1. 외부 글로우 (바깥쪽으로 퍼지는 효과)
    final glowPaint = Paint()
      ..color = GameConstants.accentNeon.withAlpha(60)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, size.x * 0.6, glowPaint);

    // 2. 메인 펄스 원
    final pulsePaint = Paint()
      ..color = GameConstants.accentNeon.withAlpha(100)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.x * 0.3, pulsePaint);

    // 3. 중심점 (Core)
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.x * 0.1, corePaint);
    
    // 4. 전술적 테두리 (Radar Line)
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, size.x * 0.3, strokePaint);
  }
}
