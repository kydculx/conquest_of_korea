import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/constants/strings.dart';

/// 게임 데이터 로딩 및 GPS 연결 대기 시 표시하는 전술적 로딩 화면
class LoadingOverlay extends StatefulWidget {
  final String message;
  const LoadingOverlay({super.key, this.message = GameStrings.analyzingTacticalData});

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
                  return CustomPaint(
                    painter: _RadarPainter(_controller.value),
                  );
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

    final bgPaint = Paint()
      ..color = GameColors.accentNeon.withValues(alpha: 30 / 255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 동심원 그리기
    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawCircle(center, radius * 0.6, bgPaint);
    canvas.drawCircle(center, radius * 0.3, bgPaint);

    // 십자선
    canvas.drawLine(Offset(center.dx - radius, center.dy),
        Offset(center.dx + radius, center.dy), bgPaint);
    canvas.drawLine(Offset(center.dx, center.dy - radius),
        Offset(center.dx, center.dy + radius), bgPaint);

    // 회전하는 스캔 라인
    final sweepShader = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: math.pi * 2,
      colors: [
        GameColors.accentNeon.withValues(alpha: 0.0),
        GameColors.accentNeon.withValues(alpha: 150 / 255),
      ],
      stops: const [0.8, 1.0],
      transform: GradientRotation(progress * math.pi * 2 - math.pi / 2),
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, Paint()..shader = sweepShader);

    // 스캔 라인 끝부분의 밝은 점
    final angle = progress * math.pi * 2 - math.pi / 2;
    final dotOffset = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas.drawCircle(
        dotOffset, 3, Paint()..color = GameColors.accentNeon);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}
