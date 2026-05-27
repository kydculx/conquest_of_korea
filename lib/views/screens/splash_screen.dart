import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/game_provider.dart';
import 'game_screen.dart';

/// 군더더기 없는 미니멀 테크니컬 컨셉의 스플래시 화면 (Orbitron 및 Share Tech Mono 구글 폰트 적용)
class SplashScreen extends StatefulWidget {
  /// 스플래시 화면을 생성하는 기본 생성자
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// 페이드인 및 맥동 효과 제어용 애니메이션 컨트롤러
  late AnimationController _animationController;

  /// 배경 격자 서서히 밝아지는 페이드인 애니메이션
  late Animation<double> _fadeInAnimation;

  /// 스플래시 화면 최소 감상 연출 시간(1.2초) 경과 여부
  bool _minTimeElapsed = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // 1.2초의 쾌적한 최소 연출 대기 시간 구성
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _minTimeElapsed = true;
        });
        _checkInitializationAndNavigate();
      }
    });

    // GameProvider 초기화 대기 리스너
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
            // 자연스럽고 군더더기 없는 300ms 페이드아웃 전환 적용
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
          // 1. 배경 Grid 격자 연출 (미니멀 반투명 격자)
          Positioned.fill(child: CustomPaint(painter: _TacticalGridPainter())),

          // 2. 화면 정중앙에 위치한 메인 게임 제목 (CONQUEST OF KOREA)
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeInAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 전술 네온 블루 섀도우가 깔린 메인 타이틀 (구글 Orbitron SF 폰트)
                      Text(
                        GameStrings.appName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.orbitron(
                          color: GameColors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          shadows: [
                            Shadow(
                              color: GameColors.info.withValues(alpha: 0.6),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 미니멀 서브 헤더 (구글 Share Tech Mono 콘솔 폰트)
                      Text(
                        'REAL-TIME GEOGRAPHIC CONQUEST',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.shareTechMono(
                          color: GameColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 3. 하단부 로딩 인디케이터
          Positioned(
            bottom: 60.0 + bottomPadding,
            left: 20,
            right: 20,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeInAnimation.value,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            GameColors.info.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 구글 Share Tech Mono 콘솔 폰트
                      Text(
                        'CONNECTING TO SATELLITE SYSTEM...',
                        style: GoogleFonts.shareTechMono(
                          color: GameColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
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

/// 전술 격자 배경을 미니멀하게 그려주는 커스텀 페인터
class _TacticalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GameColors.dividerColor.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    const double step = 40.0;

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
