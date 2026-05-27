import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/game_provider.dart';
import 'game_screen.dart';

/// 전술 맵 컨셉의 정적 스플래시 화면 (애니메이션 제거 및 즉시 진입 최적화)
class SplashScreen extends StatefulWidget {
  /// 스플래시 화면을 생성하는 기본 생성자
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // GameProvider 초기화 상태 즉시 감지 및 연동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = context.read<GameProvider>();

      // 이미 초기화가 완료된 상태라면 딜레이 없이 즉시 네비게이션 실행
      if (game.isInitialized) {
        _navigateToGame();
      } else {
        game.addListener(_onGameProviderChanged);
      }
    });
  }

  /// [GameProvider]의 상태가 변경될 때 호출되는 리스너 콜백
  void _onGameProviderChanged() {
    final game = context.read<GameProvider>();
    if (game.isInitialized) {
      game.removeListener(_onGameProviderChanged);
      _navigateToGame();
    }
  }

  /// 메인 전술 맵 화면으로 쾌속 화면 전환을 수행합니다.
  void _navigateToGame() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GameScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 자연스러운 150ms 신속 페이드 트랜지션 적용으로 덜컹거림 차단
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 150),
      ),
    );
  }

  @override
  void dispose() {
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
          // 1. 배경 Grid 격자 연출
          Positioned.fill(child: CustomPaint(painter: _TacticalGridPainter())),

          // 2. 중앙 레이더 스캔 이미지 및 로고 (애니메이션이 소거된 정적 룩)
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 정적 레이더 원형 라인 1
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: GameColors.accentNeon.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                ),
                // 정적 레이더 원형 라인 2
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: GameColors.accentNeon.withValues(alpha: 0.1),
                      width: 1.0,
                    ),
                  ),
                ),

                // 메인 전술 아이콘 (정적 렌더링)
                Container(
                  width: 80,
                  height: 80,
                  decoration: ShapeDecoration(
                    color: GameColors.backgroundMedium.withValues(alpha: 0.9),
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
              ],
            ),
          ),

          // 3. 하단 텍스트 및 로딩 상태
          Positioned(
            bottom: 60.0 + bottomPadding,
            left: 20,
            right: 20,
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
                        color: GameColors.accentNeon.withValues(alpha: 0.5),
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
