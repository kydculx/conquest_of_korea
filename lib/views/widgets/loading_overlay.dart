import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';

/// 게임 데이터 로딩 및 GPS 연결 대기 시 표시하는 Cozy 파스텔 로딩 화면
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
      color: GameColors.backgroundMedium.withValues(alpha: 0.95), // 뽀얀 우유빛 크림 오버레이
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cozy 3색 버블 스피너 애니메이션
            SizedBox(
              width: 100,
              height: 100,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(painter: _CozyBubbleSpinnerPainter(_controller.value));
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
                        style: GoogleFonts.fredoka(
                          color: GameColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'strategically connecting base...',
                        style: GoogleFonts.quicksand(
                          color: GameColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
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

/// 3개의 파스텔 버블이 원 궤도를 돌며 귀엽게 공전하는 스피너
class _CozyBubbleSpinnerPainter extends CustomPainter {
  final double progress;
  _CozyBubbleSpinnerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10.0; // 버블 반지름 여유분 확보

    // 1. 공전 궤도선 (조약돌 링)
    final orbitPaint = Paint()
      ..color = GameColors.dividerColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, orbitPaint);

    // 2. 3색 파스텔 솜사탕 버블 (120도 간격)
    final colors = [
      const Color(0xFFE57373), // 솜사탕 핑크
      const Color(0xFF90CAF9), // 솜사탕 블루
      const Color(0xFFFFB74D), // 솜사탕 옐로우
    ];

    final double baseAngle = progress * math.pi * 2;

    for (int i = 0; i < 3; i++) {
      final double angle = baseAngle + (i * 2 * math.pi / 3);
      final double bubbleX = center.dx + radius * math.cos(angle);
      final double bubbleY = center.dy + radius * math.sin(angle);
      final bubbleCenter = Offset(bubbleX, bubbleY);

      // 개별 버블 젤리 글로우
      final glowPaint = Paint()
        ..color = colors[i].withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(bubbleCenter, 10.0, glowPaint);

      // 개별 버블 알갱이
      final corePaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      canvas.drawCircle(bubbleCenter, 6.0, corePaint);

      // 화이트 젤리 반사광 광원 데코
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(bubbleX - 2, bubbleY - 2), 2.0, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CozyBubbleSpinnerPainter oldDelegate) => true;
}
