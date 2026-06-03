import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/game_config.dart';
import '../../providers/location_provider.dart';

/// 전술 나침반(Tactical Compass) UI 위젯
/// - [디자인 리뉴얼] 투박한 군사용 계기판 디자인을 걷어내고, 모던하고 심플한 글래스모피즘 네온 다이아몬드 핀 지침으로 전면 개편했습니다.
/// - [성능 최적화] watch를 Selector로 전면 전환하여, 1초에 50번씩 회전할 때 상위 HUD나 UI 전체가 불필요하게 갱신되는 병목을 원천 격리했습니다.
class TacticalCompass extends StatefulWidget {
  final double size;
  const TacticalCompass({super.key, this.size = 44.0});

  @override
  State<TacticalCompass> createState() => _TacticalCompassState();
}

class _TacticalCompassState extends State<TacticalCompass>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // GPS 신호 유실 시 부드러운 글로우 펄스 애니메이션 구동
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
    // 1. GPS 신호 수신 품질만 정밀 모니터링 (변화 시에만 빌드)
    final bool isSignalGood = context.select<LocationProvider, bool>((loc) {
      final isGpsActive = loc.isGpsActive;
      final accuracy = loc.currentAccuracy;
      return isGpsActive && accuracy <= GameConfig.captureAccuracyThreshold;
    });

    // 2. 나침반 방위각(heading)만 정밀하게 Selector로 구독하여 UI 리빌드 병목 완벽 차단
    return Selector<LocationProvider, double>(
      selector: (_, loc) => loc.heading,
      builder: (context, heading, child) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: CustomPaint(
                painter: _ModernCompassPainter(
                  heading: heading,
                  isSignalGood: isSignalGood,
                  pulseValue: _pulseController.value,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 모던하고 세련된 네온 글래스 나침반을 그리는 CustomPainter
class _ModernCompassPainter extends CustomPainter {
  final double heading;
  final bool isSignalGood;
  final double pulseValue;

  _ModernCompassPainter({
    required this.heading,
    required this.isSignalGood,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final Color accentColor = isSignalGood
        ? GameColors.accentNeon
        : GameColors.error;

    // 1. 심플 글래스모피즘 아우터 섀도우 & 네온 테두리
    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: isSignalGood ? 0.7 : (0.2 + (pulseValue * 0.45)))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 2, borderPaint);

    // 반투명 다크 크리스탈 원형 배경
    final bgPaint = Paint()
      ..color = GameColors.backgroundMedium.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 2, bgPaint);

    // 2. 정북 방향을 가리키는 초슬림 입체 네온 솜사탕 다이아몬드 지침
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // 방위각 라디안 변환 (나침반 지침이 북쪽 고정 지시용 반대 회전)
    final double headingRad = -heading * (math.pi / 180.0);
    canvas.rotate(headingRad);

    final double pinLength = radius - 8;
    const double pinWidth = 5.0;

    // 북쪽 가리키는 핀 (그라데이션 네온 레드 솜사탕)
    final Path northPath = Path()
      ..moveTo(0, -pinLength)
      ..lineTo(pinWidth, 0)
      ..lineTo(0, -2) // 입체감을 위한 미세 오프셋
      ..close();

    final northPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFF5252),
          Color(0xFFFF8A80),
        ],
      ).createShader(Rect.fromLTRB(-pinWidth, -pinLength, pinWidth, 0))
      ..style = PaintingStyle.fill;
    canvas.drawPath(northPath, northPaint);

    final Path northShadowPath = Path()
      ..moveTo(0, -pinLength)
      ..lineTo(-pinWidth, 0)
      ..lineTo(0, -2)
      ..close();

    final northShadowPaint = Paint()
      ..color = const Color(0xFFC62828).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawPath(northShadowPath, northShadowPaint);

    // 남쪽 가리키는 핀 (세련된 다크 메탈릭 실버)
    final Path southPath = Path()
      ..moveTo(0, pinLength)
      ..lineTo(pinWidth, 0)
      ..lineTo(0, 2)
      ..close();

    final southPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawPath(southPath, southPaint);

    final Path southShadowPath = Path()
      ..moveTo(0, pinLength)
      ..lineTo(-pinWidth, 0)
      ..lineTo(0, 2)
      ..close();

    final southShadowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawPath(southShadowPath, southShadowPaint);

    // 정북 방향 미세 하이테크 N 마커 도트
    final nMarkerPaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, -pinLength + 3), 1.5, nMarkerPaint);

    canvas.restore(); // 회전 복구

    // 3. 중심 회전 축 레티클 코어
    final centerCorePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, centerCorePaint);

    final centerOuterPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 4.5, centerOuterPaint);
  }

  @override
  bool shouldRepaint(covariant _ModernCompassPainter oldDelegate) {
    return oldDelegate.heading != heading ||
        oldDelegate.isSignalGood != isSignalGood ||
        oldDelegate.pulseValue != pulseValue;
  }
}
