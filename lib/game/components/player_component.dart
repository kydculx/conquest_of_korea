import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants.dart';

/// 플레이어의 현재 위치와 방향을 나타내는 전술 커서 컴포넌트
class PlayerComponent extends PositionComponent {
  LatLng _location = GameConstants.defaultPosition;
  LatLng get location => _location;
  double _heading = 0.0; // 라디안 단위
  
  // 가독성 개선을 위한 애니메이션 변수
  double _pulseTime = 0;
  double _pulseScale = 1.0;

  PlayerComponent() : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // 크기는 기존대로 유지 (40x40)
    size = Vector2(40, 40);
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // 펄스 애니메이션: 커서가 미세하게 커졌다 작아지며 시선을 끎
    _pulseTime += dt * 3;
    _pulseScale = 1.0 + (math.sin(_pulseTime) * 0.08);
  }

  void updateLocation(LatLng newLocation) {
    _location = newLocation;
  }

  void updateHeading(double degrees) {
    // 도(degree)를 라디안(radian)으로 변환
    _heading = degrees * (math.pi / 180.0);
  }

  void updateScreenPosition(Offset offset) {
    position = Vector2(offset.dx, offset.dy);
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final baseRadius = size.x * 0.35;
    final radius = baseRadius * _pulseScale;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_heading);
    canvas.translate(-center.dx, -center.dy);

    // 화살표 경로 정의 (날렵한 전술 화살표 모양)
    final arrowPath = ui.Path()
      ..moveTo(center.dx, center.dy - radius * 1.1) // 앞쪽 끝
      ..lineTo(center.dx - radius * 0.8, center.dy + radius * 0.9) // 좌측 하단
      ..lineTo(center.dx, center.dy + radius * 0.5) // 중앙 홈
      ..lineTo(center.dx + radius * 0.8, center.dy + radius * 0.9) // 우측 하단
      ..close();

    // 1. 강한 바닥 그림자 (지도와 분리감 생성)
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = GameColors.tacticalBlack.withValues(alpha: 180 / 255)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 2. 네온 글로우 (가독성 핵심)
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = GameColors.accentNeon.withValues(alpha: 100 / 255)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // 3. 본체 그라데이션 (화이트 -> 네온)
    canvas.drawPath(
      arrowPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(center.dx, center.dy - radius),
          Offset(center.dx, center.dy + radius),
          [GameColors.tacticalWhite, GameColors.accentNeon],
        )
        ..style = PaintingStyle.fill,
    );

    // 4. 선명한 화이트 외곽선 (가장자리 가독성)
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = GameColors.tacticalWhite.withValues(alpha: 220 / 255)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );

    // 5. 내부 전술 라인 (디테일)
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.6),
      Offset(center.dx, center.dy + radius * 0.3),
      Paint()
        ..color = GameColors.tacticalBlack.withValues(alpha: 60 / 255)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.restore();
  }
}
