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
  bool isVisible = true; // 추가: 렌더링 활성화 상태 플래그
  
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
    if (!isVisible) return;
    final center = Offset(size.x / 2, size.y / 2);
    final baseRadius = size.x * 0.35;
    final radius = baseRadius * _pulseScale;

    // 회전 및 스케일 변환 적용
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_heading);
    canvas.translate(-center.dx, -center.dy);

    // 1. 하이테크 레이더 스캔 서클 및 펄싱 웨이브 (배경)
    final radarPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // 정적 전술 타겟 원
    radarPaint.color = GameColors.accentNeon.withValues(alpha: 0.15);
    canvas.drawCircle(center, baseRadius * 1.4, radarPaint);
    
    // 밖으로 퍼져나가는 스캔 웨이브 효과 (두 개의 엇갈리는 주기)
    final wave1 = (_pulseTime * 0.5) % 1.0;
    final wave2 = ((_pulseTime * 0.5) + 0.5) % 1.0;
    
    radarPaint.color = GameColors.accentNeon.withValues(alpha: (1.0 - wave1) * 0.3);
    canvas.drawCircle(center, baseRadius * (0.8 + wave1 * 1.0), radarPaint);

    radarPaint.color = GameColors.accentNeon.withValues(alpha: (1.0 - wave2) * 0.3);
    canvas.drawCircle(center, baseRadius * (0.8 + wave2 * 1.0), radarPaint);

    // 2. 전방 전술 레이저 조준 라인 (Dashed Laser Guide)
    final laserPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy - radius * 1.2),
        Offset(center.dx, center.dy - radius * 4.5),
        [
          GameColors.accentNeon.withValues(alpha: 0.95),
          GameColors.accentNeon.withValues(alpha: 0.0),
        ],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // 전방으로 연장되는 점선 그리기
    const int dashCount = 6;
    final double dashStart = -radius * 1.4;
    final double dashLength = radius * 0.35;
    final double dashSpace = radius * 0.18;
    for (int i = 0; i < dashCount; i++) {
      final double yStart = center.dy + dashStart - (i * (dashLength + dashSpace));
      final double yEnd = yStart - dashLength;
      canvas.drawLine(Offset(center.dx, yStart), Offset(center.dx, yEnd), laserPaint);
    }

    // 3. 프리미엄 스텔스기 스타일의 입체 화살표 패스 정의
    final arrowPath = ui.Path()
      ..moveTo(center.dx, center.dy - radius * 1.25) // 전면 앞코
      ..lineTo(center.dx - radius * 0.95, center.dy + radius * 0.9) // 좌측 하단 날개끝
      ..lineTo(center.dx - radius * 0.25, center.dy + radius * 0.35) // 좌측 안쪽 꺾임선
      ..lineTo(center.dx, center.dy + radius * 0.6) // 중앙 후방 홈
      ..lineTo(center.dx + radius * 0.25, center.dy + radius * 0.35) // 우측 안쪽 꺾임선
      ..lineTo(center.dx + radius * 0.95, center.dy + radius * 0.9) // 우측 하단 날개끝
      ..close();

    // 3-1. 강한 분리감용 그림자 드롭
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = GameColors.tacticalBlack.withValues(alpha: 200 / 255)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 3-2. 테두리 네온 야간 글로우 효과
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = GameColors.accentNeon.withValues(alpha: 130 / 255)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // 3-3. 입체 명암 연출을 위한 좌우 절반 패스 분리
    final leftHalf = ui.Path()
      ..moveTo(center.dx, center.dy - radius * 1.25)
      ..lineTo(center.dx - radius * 0.95, center.dy + radius * 0.9)
      ..lineTo(center.dx - radius * 0.25, center.dy + radius * 0.35)
      ..lineTo(center.dx, center.dy + radius * 0.6)
      ..close();

    final rightHalf = ui.Path()
      ..moveTo(center.dx, center.dy - radius * 1.25)
      ..lineTo(center.dx + radius * 0.95, center.dy + radius * 0.9)
      ..lineTo(center.dx + radius * 0.25, center.dy + radius * 0.35)
      ..lineTo(center.dx, center.dy + radius * 0.6)
      ..close();

    // 좌측 날개면: 메탈릭 반사광 그라데이션 (화이트 -> 연청색 네온)
    canvas.drawPath(
      leftHalf,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(center.dx - radius, center.dy),
          Offset(center.dx, center.dy),
          [GameColors.tacticalWhite, Colors.cyanAccent],
        )
        ..style = PaintingStyle.fill,
    );

    // 우측 날개면: 어두운 그림자면 (기본 네온그린 -> 어두운 그린 반 그라데이션)
    canvas.drawPath(
      rightHalf,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(center.dx, center.dy),
          Offset(center.dx + radius, center.dy),
          [GameColors.accentNeon, GameColors.accentNeon.withValues(alpha: 0.55)],
        )
        ..style = PaintingStyle.fill,
    );

    // 3-4. 하이라이트 외곽 테두리선
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = GameColors.tacticalWhite.withValues(alpha: 240 / 255)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round,
    );

    // 3-5. 중앙 축 척추선 드로잉
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.7),
      Offset(center.dx, center.dy + radius * 0.5),
      Paint()
        ..color = GameColors.tacticalBlack.withValues(alpha: 130 / 255)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.restore();
  }
}
