import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/game_provider.dart';
import 'game_screen.dart';

/// 하이테크 홀로그래픽 전술 맵 컨셉의 초고품격 스플래시 화면 (Rich Aesthetics & Geodetic Hexagon Grid)
class SplashScreen extends StatefulWidget {
  /// 스플래시 화면을 생성하는 기본 생성자
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// 홀로그램 회전 및 펄스 효과를 정밀 제어하는 메인 애니메이션 컨트롤러
  late AnimationController _animationController;

  /// 로고 글로우 및 텍스트 맥동 효과용 바운스 애니메이션
  late Animation<double> _pulseAnimation;

  /// 배경 헥사곤 매트릭스 서서히 밝아지는 페이드인 애니메이션
  late Animation<double> _fadeInAnimation;

  /// 스플래시 화면 최소 감상 연출 시간(1.2초) 경과 여부
  bool _minTimeElapsed = false;

  @override
  void initState() {
    super.initState();

    // 쾌적하고 은은한 하이테크 루프 애니메이션 구성 (3초 주기)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_animationController);

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.40, curve: Curves.easeIn),
      ),
    );

    _animationController.repeat();

    // 최소 연출 시간을 1.2초로 정교하게 세팅 (너무 짧아 날아가는 느낌과 너무 길어 답답한 느낌의 골든 밸런스)
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _minTimeElapsed = true;
        });
        _checkInitializationAndNavigate();
      }
    });

    // GameProvider 초기화 대기 리스너 추가
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = context.read<GameProvider>();
      game.addListener(_onGameProviderChanged);
    });
  }

  /// [GameProvider] 상태 변화 감지 리스너
  void _onGameProviderChanged() {
    _checkInitializationAndNavigate();
  }

  /// 초기화 및 최소 시간 대조 후 메인 게임 맵으로 부드럽게 네비게이션
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
            // 덜컹거림이 전혀 없는 극도로 부드럽고 품격 있는 300ms 페이드아웃 전환 적용
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
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

    return Scaffold(
      backgroundColor: GameColors.tacticalBlack,
      body: Stack(
        children: [
          // 1. 딥 블루 네온 백그라운드 그라디언트 광원
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    GameColors.info.withValues(alpha: 0.12),
                    GameColors.tacticalBlack,
                  ],
                ),
              ),
            ),
          ),

          // 2. 전술 지리 정보 격자 + 사이버 헥사곤 그리드 배경 연출 (Custom Paint)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeInAnimation.value,
                  child: CustomPaint(
                    painter: _GeodeticTacticalPainter(
                      progress: _animationController.value,
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. 중앙 홀로그램 헥사곤 스캐너 및 글래스모피즘 로고 카드
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // 홀로그램 외부 헥사곤 링 (시계 방향 서서히 회전)
                    Transform.rotate(
                      angle: _animationController.value * 2 * math.pi,
                      child: CustomPaint(
                        size: const Size(260, 260),
                        painter: _HologramHexagonRingPainter(
                          color: GameColors.accentNeon.withValues(alpha: 0.15),
                          isDashed: true,
                        ),
                      ),
                    ),

                    // 홀로그램 내부 헥사곤 링 (반시계 방향 서서히 회전)
                    Transform.rotate(
                      angle: -_animationController.value * 2 * math.pi,
                      child: CustomPaint(
                        size: const Size(200, 200),
                        painter: _HologramHexagonRingPainter(
                          color: GameColors.info.withValues(alpha: 0.2),
                          isDashed: false,
                        ),
                      ),
                    ),

                    // 맥동하는 로고 카드 섀도우 및 백 라이트
                    Container(
                      width: 90 * _pulseAnimation.value,
                      height: 90 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: GameColors.accentNeon.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),

                    // 글래스모피즘 기하학 전술 메인 로고 카드 (아크릴 유리 텍스처)
                    Container(
                      width: 90,
                      height: 90,
                      decoration: ShapeDecoration(
                        color: GameColors.backgroundMedium.withValues(
                          alpha: 0.85,
                        ),
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: GameColors.accentNeon.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                        ),
                        shadows: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Icon(
                          Icons.radar_rounded,
                          color: GameColors.accentNeon,
                          size: 45,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // 4. 하단 텍스트 레이아웃 및 펄스 동기화 메시지
          Positioned(
            bottom: 60.0 + bottomPadding,
            left: 30,
            right: 30,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeInAnimation.value,
                  child: Column(
                    children: [
                      // 전술 앱 타이틀
                      Text(
                        GameStrings.appName.toUpperCase(),
                        style: TextStyle(
                          color: GameColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6.0,
                          shadows: [
                            Shadow(
                              color: GameColors.accentNeon.withValues(
                                alpha: 0.6,
                              ),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // 하이테크 서브 타이틀
                      Text(
                        'REAL-TIME GEOGRAPHIC TACTICAL CONQUEST',
                        style: TextStyle(
                          color: GameColors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 52),

                      // 펄스 맥동 효과가 적용된 위성 동기화 표시기
                      Opacity(
                        opacity:
                            0.5 +
                            (0.5 *
                                math.sin(
                                  _animationController.value * 2 * math.pi,
                                )),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: ShapeDecoration(
                            color: GameColors.backgroundMedium.withValues(
                              alpha: 0.4,
                            ),
                            shape: BeveledRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: BorderSide(
                                color: GameColors.accentNeon.withValues(
                                  alpha: 0.25,
                                ),
                                width: 0.8,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    GameColors.accentNeon,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'ESTABLISHING SATELLITE SYNC...',
                                style: TextStyle(
                                  color: GameColors.accentNeon,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
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

/// 홀로그래픽 헥사곤 링 커스텀 페인터
class _HologramHexagonRingPainter extends CustomPainter {
  final Color color;
  final bool isDashed;

  _HologramHexagonRingPainter({required this.color, required this.isDashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final double radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final double angle = (i * 60) * math.pi / 180;
      final double x = center.dx + radius * math.cos(angle);
      final double y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    if (isDashed) {
      // 헥사곤 점선 그리기 (간이 점선 연출)
      canvas.drawPath(path, paint..strokeWidth = 1.0);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 하이테크 전술 격자 및 H3 헥사곤 사이버 백그라운드 페인터
class _GeodeticTacticalPainter extends CustomPainter {
  final double progress;

  _GeodeticTacticalPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = GameColors.dividerColor.withValues(alpha: 0.12)
      ..strokeWidth = 0.5;

    final dotPaint = Paint()
      ..color = GameColors.info.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    // 1. 기본 그리드 가로/세로선 및 그리드 조준 교차점 드로잉
    const double step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      for (double y = 0; y < size.height; y += step) {
        if (x % (step * 3) == 0 && y % (step * 3) == 0) {
          canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
        }
      }
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. 화면 곳곳에 사이버 헥사곤 그리드 아웃라인 그리기 (정적 배치로 세련된 분위기 지향)
    final hexPaint = Paint()
      ..color = GameColors.info.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final List<Offset> hexPositions = [
      Offset(size.width * 0.15, size.height * 0.25),
      Offset(size.width * 0.82, size.height * 0.18),
      Offset(size.width * 0.22, size.height * 0.78),
      Offset(size.width * 0.78, size.height * 0.72),
      Offset(size.width * 0.5, size.height * 0.5),
    ];

    final List<double> hexSizes = [45.0, 32.0, 50.0, 40.0, 115.0];

    for (int idx = 0; idx < hexPositions.length; idx++) {
      final center = hexPositions[idx];
      final double hexRadius = hexSizes[idx];

      final path = Path();
      for (int i = 0; i < 6; i++) {
        final double angle = (i * 60 + 30) * math.pi / 180; // 회전 오프셋
        final double x = center.dx + hexRadius * math.cos(angle);
        final double y = center.dy + hexRadius * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      // 바깥쪽 큰 헥사곤은 은은하게 글로우 칠
      if (idx == 4) {
        canvas.drawPath(
          path,
          hexPaint..color = GameColors.info.withValues(alpha: 0.02),
        );
      } else {
        canvas.drawPath(path, hexPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
