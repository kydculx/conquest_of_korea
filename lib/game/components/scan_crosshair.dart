import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 스캔 모드 선택 타일 중앙에 부드럽고 둥근 젤리 타겟 락온 커서를 드로잉합니다.
void drawScanCrosshair(
  Canvas canvas,
  double cx,
  double cy,
  Color color,
  double timer,
) {
  // 둥글고 두툼한 십자선 스타일
  final linePaint = Paint()
    ..color = color.withValues(alpha: 0.95)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 3.0;

  // 부드러운 안쪽 동심원
  final circlePaint = Paint()
    ..color = color.withValues(alpha: 0.35)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;

  final double scale = 1.0 + 0.08 * math.sin(timer * 3.5);
  final double r1 = 11.0 * scale;
  final double r2 = 19.0 * scale;
  const double crossLen = 5.0;

  canvas.drawCircle(Offset(cx, cy), r1, circlePaint);
  canvas.drawCircle(Offset(cx, cy), r2, circlePaint);

  // 십자선 그리기
  canvas.drawLine(
    Offset(cx, cy - r2 - crossLen),
    Offset(cx, cy - r1 - 1.5),
    linePaint,
  );
  canvas.drawLine(
    Offset(cx, cy + r1 + 1.5),
    Offset(cx, cy + r2 + crossLen),
    linePaint,
  );
  canvas.drawLine(
    Offset(cx - r2 - crossLen, cy),
    Offset(cx - r1 - 1.5, cy),
    linePaint,
  );
  canvas.drawLine(
    Offset(cx + r1 + 1.5, cy),
    Offset(cx + r2 + crossLen, cy),
    linePaint,
  );

  // 정중앙 통통한 젤리 비콘 코어
  final dotPaint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;
  final double dotPulse = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(timer * 7.0));

  // 외곽 소프트 번짐 효과
  final glowPaint = Paint()
    ..color = color.withValues(alpha: 0.25 * dotPulse)
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
  canvas.drawCircle(Offset(cx, cy), 5.5, glowPaint);

  canvas.drawCircle(
    Offset(cx, cy),
    3.2,
    dotPaint..color = color.withValues(alpha: dotPulse),
  );
}
