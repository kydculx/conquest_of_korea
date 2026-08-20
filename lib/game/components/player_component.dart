import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/map_config.dart';

/// 지도 상에서 플레이어의 물리 위치를 가리키며, 디바이스 나침반 센서 각도에 연동해 정밀 회전하고 펄싱 애니메이션을 연출하는 심플한 커서 컴포넌트
class PlayerComponent extends PositionComponent {
  /// 플레이어의 현재 실제 GPS 지리적 위치 좌표
  LatLng _location = MapConfig.defaultPosition;

  /// 플레이어의 현재 지리적 위치 좌표 반환
  LatLng get location => _location;

  /// 나침반 센서로부터 계산된 플레이어의 주시 방향 각도 (라디안 단위)
  double _heading = 0.0;

  /// 플레이어 커서 컴포넌트의 가시성(화면 렌더링) 여부
  bool isVisible = true;

  /// PlayerComponent 생성자로 앵커를 중앙으로 고정합니다.
  PlayerComponent() : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // 크기는 기존대로 유지 (40x40)
    size = Vector2(40, 40);
    anchor = Anchor.center;
  }

  /// 플레이어의 지리적 위치(LatLng)를 동기화합니다.
  void updateLocation(LatLng newLocation) {
    _location = newLocation;
  }

  /// 나침반 각도(Degrees)를 기반으로 변환하여 플레이어의 방향(Heading)을 라디안 단위로 갱신합니다.
  void updateHeading(double degrees) {
    // 도(degree)를 라디안(radian)으로 변환
    _heading = degrees * (math.pi / 180.0);
  }

  /// 화면 픽셀 좌표(Offset) 정보를 기반으로 컴포넌트의 Vector2 스크린 위치를 보정합니다.
  void updateScreenPosition(Offset offset) {
    position = Vector2(offset.dx, offset.dy);
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;
    final center = Offset(size.x / 2, size.y / 2);
    final baseRadius = size.x * 0.35;
    final radius = baseRadius; // 정적 스케일 적용 (산만한 펄싱 애니메이션 완벽 소거)

    // 1. 하이테크 통합 나침반 방위 링 (디바이스 나침반 각도의 역방향으로 회전시켜 진짜 북극을 향하도록 정밀 기동)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-_heading); // 역회전 적용하여 링 자체가 실시간으로 회전
    canvas.translate(-center.dx, -center.dy);

    final compassPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 // 선명한 분리감을 위해 굵기 상향 보정
      ..color = GameColors.accentNeon.withValues(alpha: 0.32); // 투명도를 0.32로 높여 맵 위에서 선명하게 분리

    final compassRadius = baseRadius * 2.7; // 약 38.0 반경
    canvas.drawCircle(center, compassRadius, compassPaint);

    // 1-1. 나침반 정밀 조준 눈금선 (Ticks) - 4방위에 짧은 돌출선 렌더
    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = GameColors.accentNeon.withValues(alpha: 0.40);

    // 북, 동, 남, 서 4곳의 링 안쪽에 4dp 길이의 눈금선 이식
    canvas.drawLine(
      Offset(center.dx, center.dy - compassRadius),
      Offset(center.dx, center.dy - compassRadius + 4.0),
      tickPaint,
    );
    canvas.drawLine(
      Offset(center.dx + compassRadius, center.dy),
      Offset(center.dx + compassRadius - 4.0, center.dy),
      tickPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + compassRadius),
      Offset(center.dx, center.dy + compassRadius - 4.0),
      tickPaint,
    );
    canvas.drawLine(
      Offset(center.dx - compassRadius, center.dy),
      Offset(center.dx - compassRadius + 4.0, center.dy),
      tickPaint,
    );

    // 4방위 극미니멀 텍스트 레이블 (글자 크기를 11.0으로 대폭 확대하고 불투명도 0.85로 상향하여 가독성 혁신)
    final double textDist = compassRadius + 7.5; // 링 바깥쪽 마진
    _drawMiniDirText(
      canvas,
      center,
      'N',
      Offset(0, -textDist),
      const Color(0xFFFF5252),
    ); // 북쪽은 강렬한 네온 레드
    _drawMiniDirText(
      canvas,
      center,
      'E',
      Offset(textDist, 0),
      Colors.white.withValues(alpha: 0.85),
    );
    _drawMiniDirText(
      canvas,
      center,
      'S',
      Offset(0, textDist),
      Colors.white.withValues(alpha: 0.85),
    );
    _drawMiniDirText(
      canvas,
      center,
      'W',
      Offset(-textDist, 0),
      Colors.white.withValues(alpha: 0.85),
    );

    canvas.restore();

    // 2. 프리미엄 스텔스기 스타일의 입체 화살표 (맵 고정일 때는 헤딩만큼 정방향 회전하여 방향 표시, 맵 회전 모드일 때는 0.0이 들어오므로 12시 고정됨)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_heading); // 맵 고정일 때는 기기 주시 각도로 회전 가동!
    canvas.translate(-center.dx, -center.dy);

    final arrowPath = ui.Path()
      ..moveTo(center.dx, center.dy - radius * 1.1) // 전면 앞코 (정중앙 Y축 밸런스 정렬 보정)
      ..lineTo(
        center.dx - radius * 0.95,
        center.dy + radius * 1.1,
      ) // 좌측 하단 날개끝 (정중앙 Y축 밸런스 정렬 보정)
      ..lineTo(
        center.dx - radius * 0.25,
        center.dy + radius * 0.3,
      ) // 좌측 안쪽 꺾임선 (정중앙 Y축 밸런스 정렬 보정)
      ..lineTo(center.dx, center.dy + radius * 0.6) // 중앙 후방 홈
      ..lineTo(
        center.dx + radius * 0.25,
        center.dy + radius * 0.3,
      ) // 우측 안쪽 꺾임선 (정중앙 Y축 밸런스 정렬 보정)
      ..lineTo(
        center.dx + radius * 0.95,
        center.dy + radius * 1.1,
      ) // 우측 하단 날개끝 (정중앙 Y축 밸런스 정렬 보정)
      ..close();

    // 2-1. 강한 분리감용 그림자 드롭
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = GameColors.tacticalBlack.withValues(alpha: 200 / 255)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 2-2. 테두리 네온 야간 글로우 효과
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = GameColors.accentNeon.withValues(alpha: 130 / 255)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // 2-3. 입체 명암 연출을 위한 좌우 절반 패스 분리
    final leftHalf = ui.Path()
      ..moveTo(center.dx, center.dy - radius * 1.1)
      ..lineTo(center.dx - radius * 0.95, center.dy + radius * 1.1)
      ..lineTo(center.dx - radius * 0.25, center.dy + radius * 0.3)
      ..lineTo(center.dx, center.dy + radius * 0.6)
      ..close();

    final rightHalf = ui.Path()
      ..moveTo(center.dx, center.dy - radius * 1.1)
      ..lineTo(center.dx + radius * 0.95, center.dy + radius * 1.1)
      ..lineTo(center.dx + radius * 0.25, center.dy + radius * 0.3)
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
          [
            GameColors.accentNeon,
            GameColors.accentNeon.withValues(alpha: 0.55),
          ],
        )
        ..style = PaintingStyle.fill,
    );

    // 2-4. 하이라이트 외곽 테두리선
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = GameColors.tacticalWhite.withValues(alpha: 240 / 255)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round,
    );

    // 2-5. 중앙 축 척추선 드로잉
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

  /// 4방위 지시 문자를 극극미니멀한 폰트 스타일로 렌더링하는 헬퍼 메서드
  void _drawMiniDirText(
    Canvas canvas,
    Offset center,
    String text,
    Offset offset,
    Color color,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11.0, // 글자 크기 11.0으로 가독성 확장
          fontWeight: FontWeight.bold,
          fontFamily: 'Fredoka',
          shadows: [
            // 밝은 배경 맵 타일 위에서도 또렷이 분리되는 다크 섀도 드롭
            Shadow(
              color: const Color(0xFF121212).withValues(alpha: 0.85),
              offset: const Offset(0.5, 0.5),
              blurRadius: 2.0,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx + offset.dx - textPainter.width / 2,
        center.dy + offset.dy - textPainter.height / 2,
      ),
    );
  }
}
