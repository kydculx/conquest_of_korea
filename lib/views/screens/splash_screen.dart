import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/constants/assets.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/game_config.dart';
import '../../core/constants/strings.dart';
import '../../providers/game_provider.dart';
import 'game_screen.dart';

/// 현재 사이버펑크 솜사탕 테마(네온 시안, 하이테크 위성 영토 점령)에 완벽 매칭된 프리미엄 스플래시 화면
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// 스플래시 화면 최소 감상 연출 시간(3초) 경과 여부
  bool _minTimeElapsed = false;

  /// 배경화면과 타이틀이 이질감 없이 동시에 부드럽게 연동되어 뜨도록 보장하는 페이드인 투명도 제어 변수
  double _fadeOpacity = 0.0;

  /// 플랫폼 실시간 앱 버전 정보 텍스트
  String _appVersion = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 앱 첫 프레임 기동 시 스플래시 고해상도 이미지가 디코딩 렉 없이 0ms로 즉시 뜨도록 프리캐시 가속 적용
    precacheImage(const AssetImage(GameAssets.splashBg), context);
  }

  // 플랫폼에서 실제 동적 빌드 버전을 가져오는 비동기 메소드 (Failsafe 예외 장치 완비)
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'v${packageInfo.version} (${packageInfo.buildNumber})';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _appVersion = 'v1.0.0';
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // 동적 앱 버전 정보 비동기 로딩 가동
    _loadAppVersion();

    // 첫 프레임 렌더링 직후 배경과 타이틀이 정교하게 동시 페이드인 되도록 트리거 활성화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _fadeOpacity = 1.0;
        });
      }
    });

    // 3.0초의 아늑하고 신속한 스플래시 최소 대기 시간 설정 (정밀 오타 보정 완료)
    Timer(GameConfig.splashDuration, () {
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
    try {
      final game = context.read<GameProvider>();
      game.removeListener(_onGameProviderChanged);
    } catch (_) {
      // dispose 과정에서 Provider를 못 찾는 경우 무시
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    // 테마 컬러 셋팅
    const Color neonCyan = Color(0xFF00E5FF);
    const Color textWhite = Colors.white;

    return Scaffold(
      backgroundColor: GameColors.tacticalBlack,
      body: AnimatedOpacity(
        opacity: _fadeOpacity,
        duration: const Duration(
          milliseconds: 550,
        ), // 0.55초 동안 부드럽게 동시에 짠 하고 페이드인
        curve: Curves.easeOutCubic,
        child: Stack(
          children: [
            // 1. 아름답고 아늑한 3D Cozy Clay 타이틀 스플래시 배경 이미지 연동
            Positioned.fill(
              child: Image.asset(
                GameAssets.splashBg,
                fit: BoxFit.cover,
              ),
            ),

            // 2. 게임 타이틀 및 서브타이틀 드로잉 (원형 로고 및 부유 연출 코드 완전 소거)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 타이틀 명칭
                  Text(
                    GameStrings.appName,
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

                  // 서브 타이틀
                  Text(
                    GameStrings.splashSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                      color: const Color(
                        0xFFFFFFFF,
                      ).withValues(alpha: 0.9), // 전부 흰색으로 일치화
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.8,
                    ),
                  ),
                ],
              ),
            ),

            // 4. 하단부 실시간 백엔드 위성 연결 로더 및 동기화 상태 바
            Positioned(
              bottom: 60.0 + bottomPadding,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 테마 전용 화이트 회전 도트형 로더
                  const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFFFFF),
                      ), // 로더도 흰색으로 통일
                    ),
                  ),
                  const SizedBox(width: 14),
                  // 모험 준비가 아닌 위성 링크 동기화 텍스트로 탈바꿈
                  Text(
                    GameStrings.loadingBaseConnection,
                    style: GoogleFonts.quicksand(
                      color: const Color(
                        0xFFFFFFFF,
                      ).withValues(alpha: 0.8), // 텍스트도 흰색으로 일치화
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
            ),

            // 5. 좌측 하단 앱 버전 표시
            if (_appVersion.isNotEmpty)
              Positioned(
                left: 20.0,
                bottom: 20.0 + bottomPadding,
                child: Text(
                  _appVersion,
                  style: GoogleFonts.quicksand(
                    color: const Color(0xFFFFFFFF).withValues(alpha: 1.0),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
