import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';

/// 게임 데이터 로딩 및 GPS 연결 대기 시 표시하는 전술적 로딩 화면
class LoadingOverlay extends StatefulWidget {
  final String message;
  LoadingOverlay({super.key, String? message})
    : message = message ?? GameStrings.analyzingTacticalData;

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GameColors.tacticalBlack.withValues(alpha: 220 / 255),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 레이더 스타일 로딩 애니메이션
            SizedBox(
              width: 120,
              height: 120,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(painter: _RadarPainter(_controller.value));
                },
              ),
            ),
            const SizedBox(height: 40),
            // 텍스트 애니메이션
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Column(
                    children: [
                      Text(
                        widget.message,
                        style: TextStyle(
                          color: GameColors.accentNeon,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'STRATEGIC NETWORK CONNECTING...',
                        style: TextStyle(
                          color: GameColors.dividerColor,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;
  _RadarPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. 미세 그리드 배경 (Tech Grid Background)
    final gridPaint = Paint()
      ..color = GameColors.techGrid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const double gridSpacing = 12.0;
    // 가로 격자선
    for (
      double y = center.dy - radius;
      y <= center.dy + radius;
      y += gridSpacing
    ) {
      canvas.drawLine(
        Offset(center.dx - radius, y),
        Offset(center.dx + radius, y),
        gridPaint,
      );
    }
    // 세로 격자선
    for (
      double x = center.dx - radius;
      x <= center.dx + radius;
      x += gridSpacing
    ) {
      canvas.drawLine(
        Offset(x, center.dy - radius),
        Offset(x, center.dy + radius),
        gridPaint,
      );
    }

    // 기본 네온 펜
    final bgPaint = Paint()
      ..color = GameColors.accentNeon.withValues(alpha: 40 / 255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 2. 동심원 그리기
    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawCircle(center, radius * 0.7, bgPaint);
    canvas.drawCircle(center, radius * 0.4, bgPaint);

    // 3. 십자선 (중앙 눈금 포함)
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      bgPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      bgPaint,
    );

    // 4. 방위각 눈금선 (Degree Ticks)
    final tickPaint = Paint()
      ..color = GameColors.accentNeon.withValues(alpha: 80 / 255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 15도마다 외곽선에 미세 눈금 추가
    for (int angleDeg = 0; angleDeg < 360; angleDeg += 15) {
      final double rad = angleDeg * math.pi / 180;
      final double startDist =
          radius - (angleDeg % 45 == 0 ? 8.0 : 4.0); // 45도 눈금은 조금 더 길게
      final double endDist = radius;

      final startOffset = Offset(
        center.dx + startDist * math.cos(rad),
        center.dy + startDist * math.sin(rad),
      );
      final endOffset = Offset(
        center.dx + endDist * math.cos(rad),
        center.dy + endDist * math.sin(rad),
      );
      canvas.drawLine(startOffset, endOffset, tickPaint);
    }

    // 5. 회전하는 스캔 빔 (Sweep Gradient Shader)
    final sweepShader = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: math.pi * 2,
      colors: [
        GameColors.accentNeon.withValues(alpha: 0.0),
        GameColors.accentNeon.withValues(alpha: 180 / 255),
      ],
      stops: const [0.75, 1.0],
      transform: GradientRotation(progress * math.pi * 2 - math.pi / 2),
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final scanPaint = Paint()
      ..shader = sweepShader
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, scanPaint);

    // 6. 스캔 스위퍼 경계면의 밝은 하이라이트 도트 및 라인
    final angle = progress * math.pi * 2 - math.pi / 2;
    final sweepLineEnd = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );

    // 스위퍼 선
    final sweeperLinePaint = Paint()
      ..color = GameColors.accentNeon.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(center, sweepLineEnd, sweeperLinePaint);

    // 스위퍼 헤드 도트 (펄싱 느낌의 외부 글로우 추가)
    final dotCorePaint = Paint()
      ..color = GameColors.tacticalWhite
      ..style = PaintingStyle.fill;
    final dotGlowPaint = Paint()
      ..color = GameColors.accentNeon.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(sweepLineEnd, 5.0, dotGlowPaint);
    canvas.drawCircle(sweepLineEnd, 2.5, dotCorePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}
