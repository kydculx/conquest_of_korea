import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/constants/strings.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import 'tactical_compass.dart';

/// 인게임 HUD 오버레이 (점수판, 점령 버튼, 유틸리티 버튼)
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final auth = context.watch<AuthProvider>();
    
    // 기기별 하단 제스처바/내비게이션바 안전 영역 높이 자동 산출
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    // 여백 조율을 위한 기본 하단 마진
    final double baseBottomMargin = bottomPadding > 0 ? 24.0 : 40.0;

    return Stack(
      children: [
        // 상단 좌측 나침반 버튼
        const Positioned(
          top: 60,
          left: 20,
          child: TacticalCompass(),
        ),

        // 상단 우측 로그인/프로필 버튼
        Positioned(
          top: 60,
          right: 20,
          child: _AuthProfileButton(auth: auth),
        ),

        // 점령 중 안내 텍스트 (택티컬 터미널 메시지 스타일)
        if (auth.isAuthenticated && game.isCapturing)
          Positioned(
            bottom: 150 + baseBottomMargin + bottomPadding,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: ShapeDecoration(
                  color: GameColors.backgroundTranslucent,
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: GameColors.accentNeon,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: GameColors.accentNeon,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      '[ SYSTEM: ${GameStrings.capturingZone.toUpperCase()} ]',
                      style: TextStyle(
                        color: GameColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 자동 점령(점령시작/정지) 버튼 (로그인 상태일 때 노출)
        if (auth.isAuthenticated)
          Positioned(
            bottom: baseBottomMargin + bottomPadding - 10,
            left: 0,
            right: 0,
            child: Center(child: _StartStopCaptureButton(game: game)),
          ),

      ],
    );
  }
}

class _AuthProfileButton extends StatefulWidget {
  final AuthProvider auth;
  const _AuthProfileButton({required this.auth});

  @override
  State<_AuthProfileButton> createState() => _AuthProfileButtonState();
}

class _AuthProfileButtonState extends State<_AuthProfileButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
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
    final bool isAuth = widget.auth.isAuthenticated;
    final Color color = isAuth ? GameColors.accentNeon : GameColors.textMuted;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowAlpha = isAuth ? (40 + (_pulseController.value * 50)) / 255 : 30 / 255;
        return GestureDetector(
          onTap: () {
            if (isAuth) {
              Navigator.pushNamed(context, '/profile');
            } else {
              Navigator.pushNamed(context, '/login');
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: ShapeDecoration(
              color: GameColors.backgroundMedium,
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: color.withValues(alpha: isAuth ? 0.8 : 0.3),
                  width: 1.5,
                ),
              ),
              shadows: [
                BoxShadow(
                  color: color.withValues(alpha: glowAlpha),
                  blurRadius: isAuth ? 12.0 * _pulseController.value + 4.0 : 4.0,
                  spreadRadius: isAuth ? 2.0 * _pulseController.value : 0.0,
                )
              ],
            ),
            child: Icon(
              Icons.person_rounded,
              color: color,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}

// --- 전술 타겟 형태의 점령 버튼 ---

class _StartStopCaptureButton extends StatefulWidget {
  final GameProvider game;
  const _StartStopCaptureButton({required this.game});

  @override
  State<_StartStopCaptureButton> createState() => _StartStopCaptureButtonState();
}

class _StartStopCaptureButtonState extends State<_StartStopCaptureButton>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = widget.game.isAutoCapture;
    final Color mainColor = isRunning ? GameColors.accentNeon : GameColors.error;

    return GestureDetector(
      onTap: () {
        widget.game.toggleAutoCapture();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 회전 및 펄싱 타겟 조준경 CustomPaint
          AnimatedBuilder(
            animation: Listenable.merge([_rotationController, _pulseController]),
            builder: (context, child) {
              return SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _TacticalTargetPainter(
                    rotation: _rotationController.value * 2 * math.pi,
                    isRunning: isRunning,
                    pulseValue: _pulseController.value,
                  ),
                ),
              );
            },
          ),
          // 중앙 전술 기호 및 텍스트
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRunning ? Icons.gps_fixed : Icons.gps_off_rounded,
                color: mainColor,
                size: 28,
              ),
              const SizedBox(height: 2),
              Text(
                isRunning ? GameStrings.hudSecScan : GameStrings.hudOffline,
                style: TextStyle(
                  color: GameColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                isRunning ? GameStrings.hudActive : GameStrings.hudStandby,
                style: TextStyle(
                  color: mainColor,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 전술 레이더 조준선(Crosshair Painter)
class _TacticalTargetPainter extends CustomPainter {
  final double rotation;
  final bool isRunning;
  final double pulseValue;

  _TacticalTargetPainter({
    required this.rotation,
    required this.isRunning,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final activeColor = GameColors.accentNeon;
    final inactiveColor = GameColors.error;
    final mainColor = isRunning ? activeColor : inactiveColor;

    // 1. 딥 블랙 하이테크 배경원
    final bgPaint = Paint()
      ..color = GameColors.backgroundMedium.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4, bgPaint);

    // 2. 바깥쪽 타겟 브래킷 (각진 테두리 4개)
    final bracketPaint = Paint()
      ..color = mainColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double bracketLength = 10.0;
    final double dist = radius - 2;

    // 좌상단
    canvas.drawPath(
        Path()
          ..moveTo(center.dx - dist + bracketLength, center.dy - dist)
          ..lineTo(center.dx - dist, center.dy - dist)
          ..lineTo(center.dx - dist, center.dy - dist + bracketLength),
        bracketPaint);
    // 우상단
    canvas.drawPath(
        Path()
          ..moveTo(center.dx + dist - bracketLength, center.dy - dist)
          ..lineTo(center.dx + dist, center.dy - dist)
          ..lineTo(center.dx + dist, center.dy - dist + bracketLength),
        bracketPaint);
    // 좌하단
    canvas.drawPath(
        Path()
          ..moveTo(center.dx - dist + bracketLength, center.dy + dist)
          ..lineTo(center.dx - dist, center.dy + dist)
          ..lineTo(center.dx - dist, center.dy + dist - bracketLength),
        bracketPaint);
    // 우하단
    canvas.drawPath(
        Path()
          ..moveTo(center.dx + dist - bracketLength, center.dy + dist)
          ..lineTo(center.dx + dist, center.dy + dist)
          ..lineTo(center.dx + dist, center.dy + dist - bracketLength),
        bracketPaint);

    // 3. 회전하는 전술 점선 링 (방위 지시선)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    
    final ringPaint = Paint()
      ..color = mainColor.withValues(alpha: (0.3 + (pulseValue * 0.3)))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const int segments = 8;
    const double sweepAngle = (2 * math.pi) / (segments * 2);
    for (int i = 0; i < segments; i++) {
      final double startAngle = i * (sweepAngle * 2);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius - 8),
        startAngle,
        sweepAngle,
        false,
        ringPaint,
      );
    }
    canvas.restore();

    // 4. 중앙 십자 조준선 (Crosshair HUD Ticks)
    final crossPaint = Paint()
      ..color = mainColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const double crossSize = 8.0;
    const double gap = 5.0;
    // 상/하/좌/우 십자선 그리기
    canvas.drawLine(Offset(center.dx, center.dy - crossSize - gap), Offset(center.dx, center.dy - gap), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy + gap), Offset(center.dx, center.dy + crossSize + gap), crossPaint);
    canvas.drawLine(Offset(center.dx - crossSize - gap, center.dy), Offset(center.dx - gap, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx + gap, center.dy), Offset(center.dx + crossSize + gap, center.dy), crossPaint);

    // 5. 미세 도트 오버레이
    final dotPaint = Paint()
      ..color = mainColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _TacticalTargetPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.pulseValue != pulseValue;
  }
}


