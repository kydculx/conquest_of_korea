import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../providers/game_provider.dart';
import 'game_screen.dart';

/// 현재 사이버펑크 솜사탕 요원 테마(네온 시안, 하이테크 위성 영토 점령)에 완벽 매칭된 프리미엄 스플래시 화면
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// 타이틀 상하 Floating 및 하이테크 그리드 회전 연출을 위한 컨트롤러
  late AnimationController _animationController;

  /// 스플래시 화면 최소 감상 연출 시간(2.2초) 경과 여부
  bool _minTimeElapsed = false;

  @override
  void initState() {
    super.initState();

    // 3.0초 주기의 부드러운 위아래 둥실둥실 및 입체 연출용 애니메이션 가동
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // 2.2초의 쾌적하고 몰입감 있는 스플래시 최소 대기 시간 설정
    Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _minTimeElapsed = true;
        });
        _checkInitializationAndNavigate();
      }
    });

    // GameProvider 초기화 대기 리스너 바인딩
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = context.read<GameProvider>();
      game.addListener(_onGameProviderChanged);
    });
  }

  void _onGameProviderChanged() {
    _checkInitializationAndNavigate();
  }

  void _checkInitializationAndNavigate() {
    if (!mounted) return;
    final game = context.read<GameProvider>();

    if (_minTimeElapsed && game.isInitialized) {
      game.removeListener(_onGameProviderChanged);

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const GameScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 부드러운 400ms 페이드 전환 적용
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    try {
      final game = context.read<GameProvider>();
      game.removeListener(_onGameProviderChanged);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    // 테마 컬러 셋팅
    const Color neonCyan = Color(0xFF00E5FF);
    const Color neonPink = Color(0xFFFF4081);
    const Color textWhite = Colors.white;
    final Color textMuted = GameColors.textSecondary.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: GameColors.tacticalBlack,
      body: Stack(
        children: [
          // 1. Cozy Midnight 테크니컬 딥 블루 그라데이션 배경
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF020813),
                    Color(0xFF0A192F),
                    Color(0xFF020813),
                  ],
                ),
              ),
            ),
          ),

          // 2. 백그라운드 하이테크 헥사곤 전술 회로망 및 레이저 스타더스트
          Positioned.fill(
            child: CustomPaint(
              painter: _TacticalGridPainter(animValue: _animationController.value),
            ),
          ),

          // 3. 중앙 입체 요원 타겟 링 & 게임 타이틀
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                // 은은한 상하 6px 부유(Floating) 애니메이션 계산
                final double floatOffsetY =
                    6.0 * math.sin(_animationController.value * 2 * math.pi);
                final double angle = _animationController.value * 2 * math.pi;

                return Transform.translate(
                  offset: Offset(0, floatOffsetY),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 하이테크 레이더 스타일의 회전하는 이중 네온 링 로고 프레임
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1) 바깥쪽 회전하는 원형 링 실루엣
                          Transform.rotate(
                            angle: angle * 0.5,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: neonCyan.withValues(alpha: 0.18),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          // 2) 반대 방향으로 회전하는 정밀 점선 타겟 링
                          Transform.rotate(
                            angle: -angle,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: neonPink.withValues(alpha: 0.25),
                                  width: 1.0,
                                  style: BorderStyle.solid,
                                ),
                              ),
                            ),
                          ),
                          // 3) 중심 글래스모피즘 코어 & 레이더 레이아웃 아이콘
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: neonCyan.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: neonCyan.withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.radar_rounded,
                                color: neonCyan,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // 사이버 시안 네온 그라데이션 타이틀
                      Text(
                        'Conquest of Korea',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          color: textWhite,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          shadows: [
                            Shadow(
                              color: neonCyan.withValues(alpha: 0.35),
                              offset: const Offset(0, 0),
                              blurRadius: 15,
                            ),
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.9),
                              offset: const Offset(0, 3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // 요원 스타일의 테크니컬한 서브 타이틀
                      Text(
                        'GEO-TACTICAL TERRITORY SYSTEM',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          color: neonPink.withValues(alpha: 0.85),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.8,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 4. 하단부 실시간 백엔드 위성 연결 로더 및 동기화 상태 바
          Positioned(
            bottom: 60.0 + bottomPadding,
            left: 20,
            right: 20,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final double opacity =
                    0.5 +
                    (0.5 * math.sin(_animationController.value * 2 * math.pi));

                return Opacity(
                  opacity: opacity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 테마 전용 네온 시안 회전 도트형 로더
                      const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          valueColor: AlwaysStoppedAnimation<Color>(neonCyan),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // 모험 준비가 아닌 위성 링크 동기화 텍스트로 탈바꿈
                      Text(
                        'ESTABLISHING SATELLITE LINK...',
                        style: GoogleFonts.quicksand(
                          color: textMuted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 사이버펑크 헥사곤 전술 회로 패턴 및 레이저 스타더스트를 그리는 하이테크 페인터
class _TacticalGridPainter extends CustomPainter {
  final double animValue;

  _TacticalGridPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dotPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // 1. 하이테크 헥사곤 회로망 배경 그리기 (영토 점령 컨셉)
    const double hexSize = 40.0;
    final double width = size.width;
    final double height = size.height;

    final double xSpacing = hexSize * 1.5;
    final double ySpacing = hexSize * math.sqrt(3);

    for (double y = 0; y < height + ySpacing; y += ySpacing) {
      int count = 0;
      for (double x = 0; x < width + xSpacing; x += xSpacing) {
        final double xPos = x;
        final double yPos = y + (count % 2 == 0 ? 0 : ySpacing / 2);

        // 은은하게 흐르는 헥사곤 전술 회로망
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final double angle = i * math.pi / 3;
          final double hx = xPos + hexSize * math.cos(angle);
          final double hy = yPos + hexSize * math.sin(angle);
          if (i == 0) {
            path.moveTo(hx, hy);
          } else {
            path.lineTo(hx, hy);
          }
        }
        path.close();
        canvas.drawPath(path, gridPaint);

        // 주요 헥사곤 중심에 입자 도트 배치
        if (count % 3 == 0) {
          canvas.drawCircle(Offset(xPos, yPos), 1.0, dotPaint);
        }
        count++;
      }
    }

    // 2. 우측 상단과 좌측 하단에 부유하는 네온 레이저 미세 입자 빔 연출
    final laserPaint = Paint()
      ..color = const Color(0xFFFF4081).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final double leftLaserOffset = 15.0 * math.sin(animValue * 2 * math.pi);
    final double rightLaserOffset = 15.0 * math.cos(animValue * 2 * math.pi);

    // 좌측 하단 네온 타겟 데코
    canvas.drawCircle(
      Offset(width * 0.12 + leftLaserOffset, height * 0.78),
      35,
      laserPaint,
    );
    canvas.drawCircle(
      Offset(width * 0.12 + leftLaserOffset, height * 0.78),
      12,
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.06)
        ..style = PaintingStyle.fill,
    );

    // 우측 상단 네온 타겟 데코
    canvas.drawCircle(
      Offset(width * 0.88 + rightLaserOffset, height * 0.22),
      25,
      laserPaint,
    );
    canvas.drawCircle(
      Offset(width * 0.88 + rightLaserOffset, height * 0.22),
      6,
      Paint()
        ..color = const Color(0xFFFF4081).withValues(alpha: 0.1)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _TacticalGridPainter oldDelegate) =>
      oldDelegate.animValue != animValue;
}
