import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../providers/game_provider.dart';
import 'game_screen.dart';

/// 아기자기하고 화사한 코지 파스텔 룩의 스플래시 화면 (동글동글 Fredoka 폰트 및 둥실둥실 플로팅 애니메이션)
class SplashScreen extends StatefulWidget {
  /// 스플래시 화면을 생성하는 기본 생성자
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// 은은한 둥실둥실 구름 부유(Floating) 애니메이션을 위한 컨트롤러
  late AnimationController _animationController;

  /// 스플래시 화면 최소 감상 연출 시간(1.2초) 경과 여부
  bool _minTimeElapsed = false;

  @override
  void initState() {
    super.initState();

    // 2.5초 주기의 부드러운 위아래 둥실둥실 부유 효과 애니메이션 가동
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // 1.2초의 쾌적한 최소 연출 대기 시간 구성
    Timer(const Duration(milliseconds: 3000), () {
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
            // 부드러운 300ms 페이드아웃 전환 적용
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

    // 다크 테마 일관 적용을 위한 컬러 맵핑
    final Color softNavyText = GameColors.textPrimary;
    final Color softMutedText = GameColors.textSecondary;
    final Color pastelPink = GameColors.accentNeon;
    final Color pastelBlue = GameColors.accentNeon;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Cozy Midnight 다크 그라데이션 배경
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: GameColors.cozyDarkGradient,
              ),
            ),
          ),

          // 2. 두둥실 뭉게구름과 귀여운 미니 헥사곤 버블 배경 페인터
          Positioned.fill(
            child: CustomPaint(
              painter: _CozySkyPainter(animValue: _animationController.value),
            ),
          ),

          // 3. 화면 정중앙에 위치한 둥실둥실 플로팅 게임 제목
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                // 은은한 상하 8px 부유(Floating) 애니메이션 계산
                final double floatOffsetY =
                    8.0 * math.sin(_animationController.value * 2 * math.pi);

                return Transform.translate(
                  offset: Offset(0, floatOffsetY),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 동글동글하고 귀여운 구름 모양 실루엣 로고 배경
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: GameColors.tacticalGray.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.cloud_queue_rounded,
                          color: pastelBlue,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 솜사탕 같이 둥글고 귀여운 구글 Fredoka 원형 볼드 폰트 적용
                      Text(
                        'Conquest World',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          color: softNavyText,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 아기자기한 서브 타이틀 (Quicksand 폰트)
                      Text(
                        'MY COZY CONQUEST ADVENTURE',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          color: softMutedText,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 4. 하단부 아기자기한 로딩 인디케이터
          Positioned(
            bottom: 60.0 + bottomPadding,
            left: 20,
            right: 20,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                // 은은한 깜빡임 펄스 효과
                final double opacity =
                    0.6 +
                    (0.4 * math.sin(_animationController.value * 2 * math.pi));

                return Opacity(
                  opacity: opacity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 동글동글 아기자기한 커스텀 테마 로더
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(pastelPink),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 아기자기한 모험 준비 알림 텍스트 (Quicksand 폰트)
                      Text(
                        'PREPARING FOR EXPEDITION...',
                        style: GoogleFonts.quicksand(
                          color: softMutedText,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
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

/// 아기자기한 뭉게구름과 둥글둥글 파스텔 헥사곤 버블을 그려주는 커스텀 페인터
class _CozySkyPainter extends CustomPainter {
  final double animValue;

  _CozySkyPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    // 1. 화면 좌우에 두둥실 뜬 아기자기한 미니 구름들 드로잉
    final double leftCloudOffset = 6.0 * math.sin(animValue * 2 * math.pi);
    final double rightCloudOffset = 5.0 * math.cos(animValue * 2 * math.pi);

    // 좌측 구름 버블들
    canvas.drawCircle(
      Offset(size.width * 0.15 + leftCloudOffset, size.height * 0.22),
      25,
      cloudPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.20 + leftCloudOffset, size.height * 0.20),
      30,
      cloudPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.26 + leftCloudOffset, size.height * 0.23),
      20,
      cloudPaint,
    );

    // 우측 구름 버블들
    canvas.drawCircle(
      Offset(size.width * 0.76 + rightCloudOffset, size.height * 0.70),
      20,
      cloudPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82 + rightCloudOffset, size.height * 0.68),
      28,
      cloudPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.88 + rightCloudOffset, size.height * 0.71),
      22,
      cloudPaint,
    );

    // 2. 둥글둥글하고 반투명한 파스텔 헥사곤 버블 아스라이 흩뿌리기
    final hexPaint = Paint()
      ..color = const Color(0xFFF8BBD0)
          .withValues(alpha: 0.12) // 솜사탕 핑크
      ..style = PaintingStyle.fill;

    final List<Offset> hexCenters = [
      Offset(size.width * 0.80, size.height * 0.15),
      Offset(size.width * 0.22, size.height * 0.75),
      Offset(size.width * 0.50, size.height * 0.80),
    ];

    final List<double> hexSizes = [30.0, 35.0, 22.0];
    final List<Color> hexColors = [
      const Color(0xFFF8BBD0).withValues(alpha: 0.12), // 솜사탕 핑크
      const Color(0xFFB3E5FC).withValues(alpha: 0.15), // 소프트 블루
      const Color(0xFFC8E6C9).withValues(alpha: 0.12), // 소프트 그린
    ];

    for (int i = 0; i < hexCenters.length; i++) {
      final center = hexCenters[i];
      final double radius = hexSizes[i];
      hexPaint.color = hexColors[i];

      final path = Path();
      for (int j = 0; j < 6; j++) {
        final double angle = (j * 60 + 30) * math.pi / 180;
        final double x = center.dx + radius * math.cos(angle);
        final double y = center.dy + radius * math.sin(angle);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, hexPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
