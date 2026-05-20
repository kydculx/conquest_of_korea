import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/constants/strings.dart';
import '../../providers/game_provider.dart';
import 'game_screen.dart';

/// 전술 맵 컨셉의 고급 스플래시 화면 (Rich Aesthetics & Radar Scan Animation)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeInAnimation;
  bool _minTimeElapsed = false;

  @override
  void initState() {
    super.initState();

    // 레이더 펄스 애니메이션 설정 (무한 반복)
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _radarController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
      ),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _radarController,
        curve: const Interval(0.0, 0.40, curve: Curves.easeIn),
      ),
    );

    _radarController.repeat();

    // 최소 연출 시간 2.5초 설정
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _minTimeElapsed = true;
        });
        _checkInitializationAndNavigate();
      }
    });

    // GameProvider 초기화 상태 모니터링
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

    // 최소 시간이 경과하고 게임 초기화(위성 동기화)가 완료되었을 때 메인으로 전환
    if (_minTimeElapsed && game.isInitialized) {
      game.removeListener(_onGameProviderChanged);
      
      // 멋진 페이드 아웃 전환 효과 적용
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const GameScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    try {
      final game = context.read<GameProvider>();
      game.removeListener(_onGameProviderChanged);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.tacticalBlack,
      body: Stack(
        children: [
          // 1. 배경 Grid 격자 연출
          Positioned.fill(
            child: CustomPaint(
              painter: _TacticalGridPainter(),
            ),
          ),

          // 2. 중앙 레이더 스캔 및 로고
          Center(
            child: AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // 레이더 원형 펄스 1
                    Container(
                      width: 280 * _pulseAnimation.value,
                      height: 280 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: GameColors.accentNeon.withValues(
                            alpha: (1.0 - _pulseAnimation.value) * 0.4,
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),
                    // 레이더 원형 펄스 2 (지연 발생 효과)
                    Container(
                      width: 280 * ((_pulseAnimation.value + 0.3) % 1.0),
                      height: 280 * ((_pulseAnimation.value + 0.3) % 1.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: GameColors.accentNeon.withValues(
                            alpha: (1.0 - ((_pulseAnimation.value + 0.3) % 1.0)) * 0.25,
                          ),
                          width: 1.0,
                        ),
                      ),
                    ),
                    // 중앙 스캐너 선
                    Transform.rotate(
                      angle: _radarController.value * 2 * 3.14159265,
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            center: Alignment.center,
                            colors: [
                              GameColors.accentNeon.withValues(alpha: 0.15),
                              GameColors.transparent,
                            ],
                            stops: const [0.2, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // 메인 전술 아이콘
                    Opacity(
                      opacity: _fadeInAnimation.value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: ShapeDecoration(
                          color: GameColors.backgroundMedium.withValues(alpha: 0.8),
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: GameColors.accentNeon,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.radar_rounded,
                          color: GameColors.accentNeon,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // 3. 하단 텍스트 및 로딩 상태
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Opacity(
              opacity: _fadeInAnimation.value,
              child: Column(
                children: [
                  Text(
                    GameStrings.appName.toUpperCase(),
                    style: TextStyle(
                      color: GameColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                      shadows: [
                        Shadow(
                          color: GameColors.accentNeon.withValues(alpha: 0.6),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TACTICAL POSITION & TERRITORY CONQUEST',
                    style: TextStyle(
                      color: GameColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // 로딩 표시기
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            GameColors.accentNeon,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'SATELLITE SYNC IN PROGRESS...',
                        style: TextStyle(
                          color: GameColors.accentNeon,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 전술 격자 배경을 그려주는 커스텀 페인터
class _TacticalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GameColors.dividerColor.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    const double step = 30.0;

    // 세로선 그리기
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 가로선 그리기
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
