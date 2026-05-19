import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/location_provider.dart';

/// 전술 나침반(Tactical Compass) UI 위젯
/// - LocationProvider의 heading 및 GPS 정확도를 실시간 반영하여 회전 및 네온 링 컬러를 표현합니다.
class TacticalCompass extends StatefulWidget {
  const TacticalCompass({super.key});

  @override
  State<TacticalCompass> createState() => _TacticalCompassState();
}

class _TacticalCompassState extends State<TacticalCompass>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // GPS 신호 유실/경고 시 맥박(Pulse) 애니메이션을 위한 컨트롤러
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationProvider>();
    final heading = loc.heading;
    final isGpsActive = loc.isGpsActive;
    final accuracy = loc.currentAccuracy;

    // GPS 신호 품질 판별 (15m 이하: 양호, 15m 초과 또는 비활성: 경고)
    final bool isSignalGood = isGpsActive && accuracy <= GameConstants.captureAccuracyThreshold;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: CustomPaint(
            painter: _TacticalCompassPainter(
              heading: heading,
              isSignalGood: isSignalGood,
              pulseValue: _pulseController.value,
            ),
          ),
        );
      },
    );
  }
}

/// 전술 나침반 렌더링을 위한 CustomPainter
class _TacticalCompassPainter extends CustomPainter {
  final double heading;
  final bool isSignalGood;
  final double pulseValue;

  _TacticalCompassPainter({
    required this.heading,
    required this.isSignalGood,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // GPS 신호 강도에 따라 테두리 네온 색 결정 (정상: 네온그린, 경고: 네온레드)
    final Color neonColor = isSignalGood
        ? GameColors.accentNeon
        : GameColors.error;

    // 1. 반투명 하이테크 배경 디스크
    final bgPaint = Paint()
      ..color = GameColors.backgroundMedium.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 2, bgPaint);

    // 2. 바깥쪽 테두리 글로우 링 (맥박 효과 적용)
    final glowAlpha = isSignalGood ? 0.8 : (0.4 + (pulseValue * 0.4));
    final borderPaint = Paint()
      ..color = neonColor.withValues(alpha: glowAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius - 2, borderPaint);

    // 3. 기기 방위각에 동기화되어 회전하는 컴퍼스 링 및 눈금
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // 방위각(도) -> 라디안 변환 (나침반이 북쪽을 유지하도록 반대 방향 회전)
    final double headingRad = -heading * (math.pi / 180.0);
    canvas.rotate(headingRad);

    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 30도 간격으로 나침반 눈금 및 방위 표시 그리기
    for (int angle = 0; angle < 360; angle += 30) {
      // 0도(N)가 캔버스 12시 방향을 향하도록 -90도 영점 보정
      final double angleRad = (angle - 90) * (math.pi / 180.0);
      final double cosVal = math.cos(angleRad);
      final double sinVal = math.sin(angleRad);

      // 90도 단위 주요 눈금(N, E, S, W 등)은 길게 표현
      final bool isMajor = angle % 90 == 0;
      final double innerRadius = isMajor ? radius - 8.0 : radius - 5.0;
      final double outerRadius = radius - 3.0;

      tickPaint.color = isMajor
          ? (angle == 0 ? Colors.red : GameColors.textPrimary.withValues(alpha: 0.8))
          : GameColors.textMuted.withValues(alpha: 0.5);
      tickPaint.strokeWidth = isMajor ? 1.5 : 1.0;

      canvas.drawLine(
        Offset(cosVal * innerRadius, sinVal * innerRadius),
        Offset(cosVal * outerRadius, sinVal * outerRadius),
        tickPaint,
      );

      // 주요 방위 텍스트(N, E, S, W) 표기
      if (isMajor) {
        String dirText = '';
        Color txtColor = GameColors.textPrimary;
        switch (angle) {
          case 0:
            dirText = 'N';
            txtColor = Colors.redAccent; // 정북은 전술적 가독성을 위해 적색 표시
            break;
          case 90:
            dirText = 'E';
            break;
          case 180:
            dirText = 'S';
            break;
          case 270:
            dirText = 'W';
            break;
        }

        final textPainter = TextPainter(
          text: TextSpan(
            text: dirText,
            style: TextStyle(
              color: txtColor,
              fontSize: 9.0,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // 텍스트가 바깥쪽을 향하도록 정렬 및 캔버스 상 회전 보정
        canvas.save();
        // 텍스트 배치 중심으로 이동
        final double textDist = radius - 14.0;
        canvas.translate(cosVal * textDist, sinVal * textDist);
        // N, E, S, W 글자가 읽기 편하도록 안쪽 각도로 회전
        canvas.rotate(angleRad + math.pi / 2);
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
        canvas.restore();
      }
    }
    
    // 북쪽 가리키는 미세 삼각 지시선
    final northArrowPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(0, -(radius - 7))
      ..lineTo(-3, -(radius - 12))
      ..lineTo(3, -(radius - 12))
      ..close();
    canvas.drawPath(path, northArrowPaint);

    canvas.restore(); // 회전 복구

    // 4. 화면 수직 윗부분(사용자가 폰을 쥐고 있는 진행 방향)을 지시하는 고정 인덱스 눈금선
    final indexPaint = Paint()
      ..color = GameColors.accentNeon.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(center.dx, center.dy - radius + 1),
      Offset(center.dx, center.dy - radius + 6),
      indexPaint,
    );

    // 5. 중심 조준 레티클 도트
    final dotPaint = Paint()
      ..color = neonColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _TacticalCompassPainter oldDelegate) {
    return oldDelegate.heading != heading ||
        oldDelegate.isSignalGood != isSignalGood ||
        oldDelegate.pulseValue != pulseValue;
  }
}
