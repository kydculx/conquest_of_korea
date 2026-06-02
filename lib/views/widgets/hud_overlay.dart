import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import '../screens/game_guide_screen.dart';

/// 인게임 HUD 오버레이 (점수판, 점령 버튼, 유틸리티 버튼, 위성 스캔 연동)
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameProvider>();
    final auth = context.read<AuthProvider>();

    // 기기별 상하단 안전 영역 높이 자동 산출
    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    // Y축 정밀 오프셋 연산
    final double topOffset = topPadding > 0 ? topPadding + 12.0 : 24.0;

    // 여백 조율을 위한 기본 하단 마진
    final double baseBottomMargin = bottomPadding > 0 ? 16.0 : 32.0;

    // 화면 가로 너비
    final double screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        const SizedBox.expand(),

        // [상단 좌측] 정밀 대칭 배치된 골드 캡슐 정보 바 (아바타 버튼과 시각적 중심 정렬 보정)
        Positioned(
          top: topOffset + 3.0,
          left: 20.0,
          child: const _CozyHeaderBar(),
        ),

        // [상단 우측 - 가이드 버튼] 랭킹 버튼 바로 왼쪽에 1:1 대칭 정렬 나란히 배치 (44x44)
        Positioned(
          top: topOffset,
          right: 20.0 + 44.0 + 10.0 + 44.0 + 10.0, // 프로필 44 + 랭킹 44 + 여백 오프셋 연산
          child: const _GuideActionButton(size: 44),
        ),

        // [상단 우측 - 랭킹 버튼] 유저 프로필 버튼 바로 왼쪽에 1:1 대칭 정렬 나란히 배치 (44x44)
        Positioned(
          top: topOffset,
          right: 20.0 + 44.0 + 10.0, // 프로필 단추 너비 44 + 여백 10 오프셋 연산
          child: const _RankingActionButton(size: 44),
        ),

        // [상단 우측 - 프로필 버튼] 독립 배치된 내 정보 아바타 버튼 (44x44)
        Positioned(
          top: topOffset,
          right: 20.0,
          child: _ProfileFloatingButton(auth: auth),
        ),

        // [하단 좌측] 독립 배치된 내 위치 / 맵 회전 토글 버튼 (42x42)
        Positioned(
          bottom: baseBottomMargin + bottomPadding + 17.0,
          left: 20.0,
          child: const _MapFollowRotationButton(size: 42, iconSize: 20),
        ),

        // [하단 중앙] 콤팩트해진 점령 전술 조작 버튼 (오직 로그인 요원에게만 노출)
        Selector<AuthProvider, bool>(
          selector: (_, a) => a.isAuthenticated,
          builder: (context, isAuthenticated, child) {
            if (!isAuthenticated) return const SizedBox.shrink();
            return Positioned(
              bottom: baseBottomMargin + bottomPadding,
              left: (screenWidth - 76) / 2,
              child: SizedBox(
                width: 76,
                height: 76,
                child: Center(child: _StartStopCaptureButton(game: game)),
              ),
            );
          },
        ),

        // [하단 우측 - 테마 순환 버튼] 접이식 메뉴를 걷어내고 기존 메뉴 버튼 자리에 독립형 젤리 단추로 배치 (44x44)
        Positioned(
          bottom: baseBottomMargin + bottomPadding + 16.0,
          right: 20.0, // 기존 기어 트리거 메뉴 버튼 자리에 완벽 대칭 배치
          child: _MapStyleCycleButton(game: game, size: 44, iconSize: 22),
        ),

        // [위성 스캔 팝업 레이어] 스캔 모드 여부 변동 시에만 리빌드 격리
        Selector<GameProvider, bool>(
          selector: (_, p) => p.isScanMode,
          builder: (context, isScanMode, child) {
            return Positioned(
              bottom: 90 + baseBottomMargin + bottomPadding,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !isScanMode,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: isScanMode ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: isScanMode
                        ? const _SatelliteMapBubble()
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// [상단] '솜사탕 올인원' 정보 캡슐 바 (오직 순수 GP 보유량만 극극 미니멀 노출)
class _CozyHeaderBar extends StatelessWidget {
  const _CozyHeaderBar();

  @override
  Widget build(BuildContext context) {
    return Selector<GameProvider, double>(
      selector: (_, provider) => provider.currentGold,
      builder: (context, gold, child) {
        return Container(
          height: 38,
          padding: const EdgeInsets.only(
            left: 10,
            right: 16,
            top: 2,
            bottom: 2,
          ),
          decoration: ShapeDecoration(
            color: GameColors.backgroundMedium.withValues(alpha: 0.92),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: const Color(
                  0xFF00E5FF,
                ).withValues(alpha: 0.25), // 시스템 시그니처 시안 보더
                width: 1.2,
              ),
            ),
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 3D 보석 느낌의 입체 사이버 시안 코인 엠블럼
              const Icon(
                Icons.monetization_on_rounded,
                color: Color(0xFF00E5FF),
                size: 18.0,
              ),
              const SizedBox(width: 6),
              Text(
                gold.toStringAsFixed(0),
                style: GoogleFonts.fredoka(
                  color: GameColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// [신규] 상단 우측에 단독 배치되는 3D 보석 젤리 스타일의 프로필 아바타 단추
class _ProfileFloatingButton extends StatefulWidget {
  final AuthProvider auth;

  const _ProfileFloatingButton({required this.auth});

  @override
  State<_ProfileFloatingButton> createState() => _ProfileFloatingButtonState();
}

class _ProfileFloatingButtonState extends State<_ProfileFloatingButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isAuth = widget.auth.isAuthenticated;

    final gradientColors = isAuth
        ? [const Color(0xFF00E5FF), const Color(0xFF00838F)] // 활성: 사이버 네온 시안 젤리
        : [
            const Color(0xFF37474F),
            const Color(0xFF212121),
          ]; // 비활성: 다크 메탈릭 실버 젤리

    final shadowColor = isAuth ? const Color(0xFF00E5FF) : Colors.black;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (isAuth) {
          Navigator.pushNamed(context, '/profile');
        } else {
          Navigator.pushNamed(context, '/login');
        }
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: isAuth ? 0.35 : 0.12),
                blurRadius: isAuth ? 10 : 4,
                offset: const Offset(0, 2.5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 3D 젤리 반사광 오버레이
              Positioned(
                top: 2,
                left: 5,
                right: 5,
                height: 16,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.45),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Icon(
                  Icons.person_rounded,
                  color: isAuth
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.55),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [신규] 접이식 메뉴 수납용 랭킹 이동 젤리 버튼
class _RankingActionButton extends StatefulWidget {
  final double size;

  const _RankingActionButton({required this.size});

  @override
  State<_RankingActionButton> createState() => _RankingActionButtonState();
}

class _RankingActionButtonState extends State<_RankingActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double glowRadius = widget.size * 0.38;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Navigator.pushNamed(context, '/ranking');
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF00E5FF),
                Color(0xFF00838F),
              ], // 일관성 있는 사이버 네온 시안 젤리
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 2,
                left: 5,
                right: 5,
                height: glowRadius,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(glowRadius),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.45),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              const Center(
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [신규] 접이식 메뉴 수납용 게임 가이드 이동 젤리 버튼
class _GuideActionButton extends StatefulWidget {
  final double size;

  const _GuideActionButton({required this.size});

  @override
  State<_GuideActionButton> createState() => _GuideActionButtonState();
}

class _GuideActionButtonState extends State<_GuideActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double glowRadius = widget.size * 0.38;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GameGuideScreen(),
          ),
        );
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF00E5FF),
                Color(0xFF00838F),
              ], // 일관성 있는 사이버 네온 시안 젤리
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 2,
                left: 5,
                right: 5,
                height: glowRadius,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(glowRadius),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.45),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              const Center(
                child: Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [신규] 하단 조작계 극좌측 날개에 배치되는 3D 솜사탕 보석 젤리 지도 스타일 순환 버튼
class _MapStyleCycleButton extends StatefulWidget {
  final GameProvider game;
  final double size;
  final double iconSize;

  const _MapStyleCycleButton({
    required this.game,
    this.size = 42.0,
    this.iconSize = 20.0,
  });

  @override
  State<_MapStyleCycleButton> createState() => _MapStyleCycleButtonState();
}

class _MapStyleCycleButtonState extends State<_MapStyleCycleButton> {
  bool _isPressed = false;

  IconData _getMapStyleIcon(String iconName) {
    const iconMap = <String, IconData>{
      'explore': Icons.explore,
      'brightness_5': Icons.brightness_5,
      'map': Icons.map,
      'public': Icons.public,
      'straighten': Icons.straighten,
      'filter_hdr': Icons.filter_hdr,
      'landscape': Icons.landscape,
      'directions_bike': Icons.directions_bike,
      'layers_clear': Icons.layers_clear,
    };
    return iconMap[iconName] ?? Icons.map;
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final double glowRadius = widget.size * 0.38;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        game.cycleMapStyle();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF00E5FF),
                Color(0xFF00838F),
              ], // 상시 정 가동 상태인 사이버 네온 시안 젤리 톤 적용
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2.5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 3D 젤리 반사광 오버레이
              Positioned(
                top: 2,
                left: 5,
                right: 5,
                height: glowRadius,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(glowRadius),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.45),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Icon(
                  _getMapStyleIcon(game.currentMapStyle.icon),
                  color: Colors.white,
                  size: widget.iconSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [신규] 하단 조작계 극우측 날개에 배치되는 3D 솜사탕 보석 젤리 내 위치 찾기 및 맵 회전 토글 버튼
class _MapFollowRotationButton extends StatefulWidget {
  final double size;
  final double iconSize;

  const _MapFollowRotationButton({
    this.size = 42.0,
    this.iconSize = 20.0,
  });

  @override
  State<_MapFollowRotationButton> createState() =>
      _MapFollowRotationButtonState();
}

class _MapFollowRotationButtonState extends State<_MapFollowRotationButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Selector<GameProvider, (bool, bool)>(
      selector: (_, provider) =>
          (provider.isFollowingUser, provider.isMapRotationMode),
      builder: (context, state, child) {
        final isFollowing = state.$1;
        final isRotation = state.$2;

        // 2단 모드 기반의 바람개비 아이콘 비주얼 상태 매핑
        final IconData iconData = isFollowing
            ? Icons.near_me
            : Icons.near_me_outlined;
        final double angle = isRotation ? -math.pi / 4 : 0.0;

        final gradientColors = isFollowing
            ? [
                const Color(0xFF00E5FF),
                const Color(0xFF00838F),
              ] // 활성: 사이버 네온 시안 젤리
            : [
                const Color(0xFF37474F),
                const Color(0xFF212121),
              ]; // 비활성: 다크 메탈릭 실버 젤리

        final shadowColor = isFollowing
            ? const Color(0xFF00E5FF)
            : Colors.black;

        final double glowRadius = widget.size * 0.38;

        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapCancel: () => setState(() => _isPressed = false),
          onTapUp: (_) async {
            setState(() => _isPressed = false);
            final game = Provider.of<GameProvider>(context, listen: false);
            if (!isFollowing) {
              // 비추적 상태일 때는 현재 활성화된 모드 설정을 유지하면서 추적만 다시 복원
              game.setFollowingUser(true);
            } else {
              // 추적 상태일 때는 [추적만] ↔ [추적+회전] 두 모드 간 상호 교차 토글
              await game.toggleMapRotationMode();
            }
          },
          child: AnimatedScale(
            scale: _isPressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withValues(
                      alpha: isFollowing ? 0.35 : 0.12,
                    ),
                    blurRadius: isFollowing ? 10 : 4,
                    offset: const Offset(0, 2.5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 3D 젤리 반사광 오버레이
                  Positioned(
                    top: 2,
                    left: 5,
                    right: 5,
                    height: glowRadius,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(glowRadius),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.45),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Transform.rotate(
                      angle: angle,
                      child: Icon(
                        iconData,
                        color: isFollowing
                            ? Colors.white
                            : const Color(0xFF1565C0).withValues(alpha: 0.7),
                        size: widget.iconSize,
                      ),
                    ),
                  ),
                ],
              ),
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
  State<_StartStopCaptureButton> createState() =>
      _StartStopCaptureButtonState();
}

class _StartStopCaptureButtonState extends State<_StartStopCaptureButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isRunning = widget.game.isAutoCapture;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.game.toggleAutoCapture();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isRunning
                  ? [
                      const Color(0xFFFF5252),
                      const Color(0xFFC62828),
                    ] // 작전 기동 중: 네온 레드
                  : [
                      const Color(0xFF00E5FF),
                      const Color(0xFF00838F),
                    ], // 대기: 사이버 네온 시안
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              // 네온 글로우 효과
              BoxShadow(
                color:
                    (isRunning
                            ? const Color(0xFFFF5252)
                            : const Color(0xFF00E5FF))
                        .withValues(alpha: _isPressed ? 0.15 : 0.35),
                blurRadius: _isPressed ? 8.0 : 16.0,
                spreadRadius: 1.0,
              ),
              // 하단 3D 어둠 그림자
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: _isPressed ? const Offset(0, 2) : const Offset(0, 5),
                blurRadius: _isPressed ? 4.0 : 10.0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // 상단 반사광 오버레이 (젤리 느낌 극대화)
              Positioned(
                top: 4,
                left: 10,
                right: 10,
                height: 32,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.5),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // 중앙 아이콘 및 한글 고정 텍스트 (다크 그레이 대비)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isRunning
                          ? GameStrings.stopCaptureMode
                          : GameStrings.startCaptureMode,
                      style: GoogleFonts.fredoka(
                        color: Colors.white,
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 선택된 위성 조준 타일 위에 실시간으로 위치가 갱신되는 말풍선 위젯.
class _SatelliteMapBubble extends StatefulWidget {
  const _SatelliteMapBubble();

  @override
  State<_SatelliteMapBubble> createState() => _SatelliteMapBubbleState();
}

/// [_SatelliteMapBubble]의 주기적 화면 갱신을 담당하는 상태 클래스
class _SatelliteMapBubbleState extends State<_SatelliteMapBubble> {
  /// 1초 단위로 상태 정보(쿨타임/시간)를 동기화 갱신하기 위한 타이머
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      return const SizedBox.shrink();
    }

    final game = context.read<GameProvider>();
    final tileLatLng = game.selectedScanTileLatLng;
    final selectedId = game.selectedScanTileId;

    if (tileLatLng == null || selectedId == null) {
      return const SizedBox.shrink();
    }
    final bool isCapturing =
        game.isSatelliteCapturing &&
        game.satelliteCapturingTileId == selectedId;

    // --- All-In-One 타일 기본 정보 파싱 ---
    final parts = selectedId.split('_');
    final int q = parts.length == 3 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final int r = parts.length == 3 ? (int.tryParse(parts[2]) ?? 0) : 0;

    final existingTile = game.capturedTiles[selectedId];
    final int captureCount = existingTile?.captureCount ?? 0;
    final bool isShieldActive = existingTile?.isShieldActive ?? false;
    final DateTime? shieldExpiration = existingTile?.shieldExpiration;

    // 내 소유 및 빈 타일 판별
    final myId = auth.user?.id;
    final String myNickname = auth.profile?.nickname ?? '';
    final bool isMine = existingTile != null && existingTile.userId == myId;
    final bool isTileEmpty =
        existingTile == null ||
        existingTile.userId == null ||
        existingTile.userId == 'none';

    // 연결망 판단 (내가 소유한 구역이거나, 본진에서부터 유효한 BFS 연결망이 닿는 경우 true)
    final bool isConnected = isMine || game.checkSatelliteCaptureConnectivity(selectedId);

    // --- 보안 판독(Reveal) 권한 조회 ---
    // 만약 타인 영토인데 연결망마저 끊어졌다면, 무조건 보안 해제 상태를 false로 잠금
    final bool isRevealed = isMine ? true : (isConnected && game.isTileInfoRevealed(selectedId));
    void onRevealPressed() => game.revealTileInfo(selectedId);

    final String? ownerId =
        (existingTile != null && existingTile.userId != 'none' && (isMine || isConnected))
        ? existingTile.userId
        : null;
    final Future<String>? nicknameFuture = ownerId != null
        ? game.getAgentNickname(ownerId)
        : null;

    // --- 상태 계산 ---
    Color themeColor = GameColors.accentNeon;
    bool isError = false;
    bool isCooltime = false;
    String detailsText = GameStrings.satScanActive;
    String? distanceStr;
    String? timeStr;
    bool showActionButton = false;
    String actionButtonText = '';
    VoidCallback? onActionPressed;
    List<Color> buttonGradient = [
      const Color(0xFF00E5FF),
      const Color(0xFF00838F),
    ];

    if (isCapturing) {
      final remainingSec = game.remainingSatelliteCaptureSeconds;
      themeColor = const Color(0xFFFF5252);
      detailsText = GameStrings.satCapturingAttempt;
      timeStr = GameStrings.secondsUnit(remainingSec.toString());
      showActionButton = true;
      actionButtonText = GameStrings.cancel;
      buttonGradient = [const Color(0xFFFF5252), const Color(0xFFC62828)];
      onActionPressed = () => game.cancelSatelliteCapture();
    } else {
      if (isTileEmpty) {
        final satCooltime = game.remainingSatelliteCaptureCoolSeconds;

        if (satCooltime > 0) {
          final minutes = satCooltime ~/ 60;
          final seconds = satCooltime % 60;
          themeColor = const Color(0xFFFF9900);
          isCooltime = true;
          detailsText = GameStrings.satCooltimeWaitingLabel;
          timeStr =
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        } else if (!isConnected) {
          themeColor = GameColors.error;
          isError = true;
          detailsText = GameStrings.satDisconnectedLabel;
        } else {
          final durationSec = game.getSatelliteCaptureDurationSeconds(
            selectedId,
          );
          detailsText = GameStrings.satLockOnReady;
          final distance = game.getTileDistance(selectedId);
          distanceStr = '\$ $distance';

          // 위성 점령 소모 재화(골드) 부족 여부 검증
          final double currentGold = game.currentGold;
          if (currentGold < distance) {
            themeColor = GameColors.error;
            isError = true;
            detailsText = GameStrings.satGoldShortage;
          } else {
            showActionButton = true;
            actionButtonText = GameStrings.satCaptureAction;
            buttonGradient = [const Color(0xFF00E5FF), const Color(0xFF00838F)];
            onActionPressed = () => game.executeSatelliteCapture(selectedId);
          }
          timeStr = GameStrings.secondsUnit(durationSec.toString());
        }
      } else {
        // 기존 점령지가 존재할 때
        if (isMine) {
          themeColor = GameColors.accentNeon;
          isError = false;
          detailsText = GameStrings.satAlreadyCapturedByMe(myNickname);
          showActionButton = false;
        } else {
          // 상대 타일인 경우
          if (!isConnected) {
            themeColor = GameColors.error;
            isError = true;
            detailsText = GameStrings.satDisconnectedLabel;
            showActionButton = false; // 엿보기 버튼 원천 차단
          } else {
            themeColor = GameColors.error;
            isError = true;
            detailsText = GameStrings.satOtherPlayerTerritory;

            // 상대 타일이고 보안 판독 전인 경우 -> [동네 엿보기] 유료 버튼 바인딩
            if (!isRevealed) {
              themeColor = const Color(0xFFFF7700);
              final dist = game.getTileDistance(selectedId);
              showActionButton = true;
              actionButtonText = GameStrings.satRevealVillageWithGp(
                dist.toString(),
              );
              buttonGradient = [const Color(0xFFFF8800), const Color(0xFFE65100)];
              onActionPressed = onRevealPressed;
            }
          }
        }
      }
    }

    final DateTime? revealExpiration = game.getTileRevealExpiration(selectedId);

    return SizedBox(
      width: 240.0,
      child: _BubbleColumn(
        themeColor: themeColor,
        isError: isError,
        isCooltime: isCooltime,
        detailsText: detailsText,
        distanceStr: distanceStr,
        timeStr: timeStr,
        showActionButton: showActionButton,
        actionButtonText: actionButtonText,
        onActionPressed: onActionPressed,
        buttonGradient: buttonGradient,
        onClosePressed: () => game.selectScanTile(selectedId), // 닫기 제스처 콜백
        q: q,
        r: r,
        captureCount: captureCount,
        isShieldActive: isShieldActive,
        shieldExpiration: shieldExpiration,
        agentNicknameFuture: nicknameFuture,
        isRevealed: isRevealed,
        onRevealPressed: onRevealPressed,
        revealExpiration: revealExpiration,
        isMine: isMine,
        myNickname: myNickname,
      ),
    );
  }
}

/// 정보창 본체 위젯의 래퍼 Column 클래스 (구조 일관성 유지)
class _BubbleColumn extends StatelessWidget {
  final Color themeColor;
  final bool isError;
  final bool isCooltime;
  final String detailsText;
  final String? distanceStr;
  final String? timeStr;
  final bool showActionButton;
  final String actionButtonText;
  final VoidCallback? onActionPressed;
  final List<Color> buttonGradient;
  final VoidCallback onClosePressed;

  // All-in-One 신규 확장 필드
  final int q;
  final int r;
  final int captureCount;
  final bool isShieldActive;
  final DateTime? shieldExpiration;
  final Future<String>? agentNicknameFuture;
  final bool isRevealed;
  final VoidCallback? onRevealPressed;
  final DateTime? revealExpiration;
  final bool isMine;
  final String myNickname;

  const _BubbleColumn({
    required this.themeColor,
    required this.isError,
    required this.isCooltime,
    required this.detailsText,
    this.distanceStr,
    this.timeStr,
    required this.showActionButton,
    required this.actionButtonText,
    this.onActionPressed,
    required this.buttonGradient,
    required this.onClosePressed,
    required this.q,
    required this.r,
    required this.captureCount,
    required this.isShieldActive,
    this.shieldExpiration,
    this.agentNicknameFuture,
    required this.isRevealed,
    this.onRevealPressed,
    this.revealExpiration,
    required this.isMine,
    required this.myNickname,
  });

  @override
  Widget build(BuildContext context) {
    return _BubbleBody(
      themeColor: themeColor,
      isError: isError,
      isCooltime: isCooltime,
      detailsText: detailsText,
      distanceStr: distanceStr,
      timeStr: timeStr,
      showActionButton: showActionButton,
      actionButtonText: actionButtonText,
      onActionPressed: onActionPressed,
      buttonGradient: buttonGradient,
      onClosePressed: onClosePressed,
      q: q,
      r: r,
      captureCount: captureCount,
      isShieldActive: isShieldActive,
      shieldExpiration: shieldExpiration,
      agentNicknameFuture: agentNicknameFuture,
      isRevealed: isRevealed,
      onRevealPressed: onRevealPressed,
      revealExpiration: revealExpiration,
      isMine: isMine,
      myNickname: myNickname,
    );
  }
}

/// 말풍선 본체 위젯 (Cozy 버블 테두리 + BackdropBlur 배경)
class _BubbleBody extends StatefulWidget {
  final Color themeColor;
  final bool isError;
  final bool isCooltime;
  final String detailsText;
  final String? distanceStr;
  final String? timeStr;
  final bool showActionButton;
  final String actionButtonText;
  final VoidCallback? onActionPressed;
  final List<Color> buttonGradient;
  final VoidCallback onClosePressed;

  // All-in-One 신규 확장 필드
  final int q;
  final int r;
  final int captureCount;
  final bool isShieldActive;
  final DateTime? shieldExpiration;
  final Future<String>? agentNicknameFuture;
  final bool isRevealed;
  final VoidCallback? onRevealPressed;
  final DateTime? revealExpiration;
  final bool isMine;
  final String myNickname;

  const _BubbleBody({
    required this.themeColor,
    required this.isError,
    required this.isCooltime,
    required this.detailsText,
    this.distanceStr,
    this.timeStr,
    required this.showActionButton,
    required this.actionButtonText,
    this.onActionPressed,
    required this.buttonGradient,
    required this.onClosePressed,
    required this.q,
    required this.r,
    required this.captureCount,
    required this.isShieldActive,
    this.shieldExpiration,
    this.agentNicknameFuture,
    required this.isRevealed,
    this.onRevealPressed,
    this.revealExpiration,
    required this.isMine,
    required this.myNickname,
  });

  @override
  State<_BubbleBody> createState() => _BubbleBodyState();
}

class _BubbleBodyState extends State<_BubbleBody> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: ShapeBorderClipper(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: ShapeDecoration(
            color: GameColors.backgroundMedium.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: widget.themeColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
          ),
          child: Stack(
            children: [
              // 메인 정보 카드 텍스트 & 버튼들
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상태 텍스트
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(right: 6, top: 1),
                        decoration: BoxDecoration(
                          color: GameColors.textPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailsText(context),
                      ),
                      const SizedBox(width: 20), // 우측 닫기(X) 버튼 영역 겹침 방지 여백 강제 확보
                    ],
                  ),
                  // [신규] All-in-One 타일 상세 정보 그리드 패널 (보안 해제 상태 연동)
                  const SizedBox(height: 8),
                  if (widget.isRevealed) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        // 📍 좌표 칩
                        _buildMiniBadge(
                          '${GameStrings.hudCoordinateLabel}: ${widget.q}, ${widget.r}',
                          const Color(0xFF00E5FF),
                        ),
                        // 🔥 점령 빈도 칩
                        _buildMiniBadge(
                          GameStrings.satCaptureCount(
                            widget.captureCount.toString(),
                          ),
                          const Color(0xFFFF9900),
                        ),
                        // 🛡️ 쉴드 활성 칩 (활성화 시에만 노출)
                        if (widget.isShieldActive &&
                            widget.shieldExpiration != null) ...[
                          (() {
                            final diff = widget.shieldExpiration!
                                .difference(DateTime.now().toUtc())
                                .inSeconds;
                            if (diff > 0) {
                              final m = diff ~/ 60;
                              final s = diff % 60;
                              final timeStr =
                                  '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
                              return _buildMiniBadge(
                                GameStrings.satShieldWithTime(timeStr),
                                const Color(0xFF4CAF50),
                              );
                            }
                            return const SizedBox.shrink();
                          })(),
                        ],
                        // ⏳ 엿보기 만료 칩 (10분 시간제 해제 타이머 연동)
                        if (widget.revealExpiration != null) ...[
                          (() {
                            final diff = widget.revealExpiration!
                                .difference(DateTime.now().toUtc())
                                .inSeconds;
                            if (diff > 0) {
                              final m = diff ~/ 60;
                              final s = diff % 60;
                              final timeStr =
                                  '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
                              return _buildMiniBadge(
                                GameStrings.satPeekTimeWithTime(timeStr),
                                const Color(0xFFFFD54F),
                              );
                            }
                            return const SizedBox.shrink();
                          })(),
                        ],
                      ],
                    ),
                    // 필요재화 / 소요시간 배지
                    if (widget.distanceStr != null ||
                        widget.timeStr != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.distanceStr != null) ...[
                            _buildBadge(
                              GameStrings.satRequiredGold,
                              widget.distanceStr!,
                              widget.themeColor,
                              isGold: true,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (widget.timeStr != null)
                            _buildBadge(
                              widget.isCooltime
                                  ? GameStrings.satCooltimeWaitingText
                                  : GameStrings.satRequiredTime,
                              widget.timeStr!,
                              widget.themeColor,
                            ),
                        ],
                      ),
                    ],
                  ] else ...[
                    // 🔒 보안 잠금 칩 -> 귀여운 아기자기한 비밀 은폐로 개조
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildMiniBadge(
                          GameStrings.satSecretArea,
                          const Color(0xFFFF5252),
                        ),
                        _buildMiniBadge(
                          GameStrings.satSecretHidden,
                          const Color(0xFFFF5252),
                        ),
                      ],
                    ),
                  ],
                  // 하단 전술 행동 버튼 (All-In-One 통합)
                  if (widget.showActionButton &&
                      widget.onActionPressed != null) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isPressed = true),
                      onTapUp: (_) {
                        setState(() => _isPressed = false);
                        widget.onActionPressed!();
                      },
                      onTapCancel: () => setState(() => _isPressed = false),
                      child: AnimatedScale(
                        scale: _isPressed ? 0.96 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: Container(
                          width: double.infinity,
                          height: 38,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: widget.buttonGradient,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.themeColor.withValues(alpha: 0.3),
                                blurRadius: 8.0,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: _buildButtonContent(widget.actionButtonText),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // 우상단 정밀 닫기(X) 제스처 버튼 (All-In-One 카드 전용)
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: widget.onClosePressed,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: GameColors.textSecondary.withValues(alpha: 0.7),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(String text) {
    if (text.contains('\$')) {
      final parts = text.split('\$');
      if (parts.length == 2) {
        final prefix = parts[0].trim();
        final suffix = parts[1].replaceAll(')', '').trim();
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              prefix,
              style: GoogleFonts.fredoka(
                color: Colors.white,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFF00E5FF),
              size: 14.0,
            ),
            const SizedBox(width: 2),
            Text(
              suffix,
              style: GoogleFonts.fredoka(
                color: const Color(0xFF00E5FF),
                fontSize: 12.0,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              ')',
              style: GoogleFonts.fredoka(
                color: Colors.white,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        );
      }
    }

    return Text(
      text,
      style: GoogleFonts.fredoka(
        color: Colors.white,
        fontSize: 12.0,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    // ':' 구분자를 기준으로 제목과 값을 파싱하여 제목은 보통체, 값은 굵고 고유 색상으로 분리 렌더링
    final parts = text.split(':');
    final String label;
    final String? value;
    if (parts.length >= 2) {
      label = parts[0].trim();
      value = parts.sublist(1).join(':').trim();
    } else {
      label = text;
      value = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value != null ? '$label: ' : label,
            style: GoogleFonts.quicksand(
              color: GameColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w500, // 보통 글씨체
            ),
          ),
          if (value != null)
            Text(
              value,
              style: GoogleFonts.quicksand(
                color: color, // 값은 굵고 고유 색상있게
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(
    String label,
    String value,
    Color color, {
    bool isGold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.quicksand(
              color: GameColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w500, // 제목은 보통 글씨체
            ),
          ),
          // 아이콘은 전부 제거하라는 지시에 의해 Gold 동전 아이콘 렌더링 비활성화
          Text(
            isGold ? value.replaceAll(RegExp(r'[\$\s]'), '') : value,
            style: GoogleFonts.quicksand(
              color: isGold ? const Color(0xFF00E5FF) : color, // 값은 굵고 고유 색상있게
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  /// 닉네임과 테마색/타일색을 연동하여 '누구 님의 구역입니다.' 형태의 미려한 RichText 및 일반 상태 텍스트를 분기 렌더링합니다.
  Widget _buildDetailsText(BuildContext context) {
    final defaultStyle = GoogleFonts.fredoka(
      color: GameColors.textPrimary,
      fontSize: 11.5,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.4,
    );

    // 1. 본인 소유의 타일인 경우 -> 동기적으로 내 닉네임을 내 타일 테마색(GameColors.myTileColor)으로 물들여 표시
    if (widget.isMine) {
      final nameColor = GameColors.myTileColor;
      return RichText(
        text: TextSpan(
          style: defaultStyle,
          children: [
            TextSpan(
              text: widget.myNickname,
              style: TextStyle(color: nameColor),
            ),
            const TextSpan(text: ' 님의 구역입니다.'),
          ],
        ),
      );
    }

    // 2. 다른 플레이어 소유이고 상세 엿보기가 활성화된 경우 -> 비동기적으로 상대 닉네임을 상대 테마색(widget.themeColor)으로 물들여 표시
    if (!widget.isMine && widget.isRevealed && widget.agentNicknameFuture != null) {
      final nameColor = widget.themeColor;
      return FutureBuilder<String>(
        future: widget.agentNicknameFuture,
        builder: (context, snapshot) {
          final nickname = snapshot.data ?? '...';
          return RichText(
            text: TextSpan(
              style: defaultStyle,
              children: [
                TextSpan(
                  text: nickname,
                  style: TextStyle(color: nameColor),
                ),
                const TextSpan(text: ' 님의 구역입니다.'),
              ],
            ),
          );
        },
      );
    }

    // 3. 그 외 일반 정보 상태 (중립지, 정보 가림 상태, 통신 해제 등) -> 기본 detailsText 일반 출력
    return Text(
      widget.detailsText,
      style: defaultStyle,
    );
  }
}
