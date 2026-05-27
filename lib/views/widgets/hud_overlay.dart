import 'dart:async';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/hex_service.dart';

/// 인게임 HUD 오버레이 (점수판, 점령 버튼, 유틸리티 버튼, 위성 스캔 연동)
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final auth = context.watch<AuthProvider>();

    // 인증되지 않은 경우 아무것도 렌더링하지 않음
    if (!auth.isAuthenticated) {
      return const SizedBox.shrink();
    }

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
        // 위성 스캔 활성화 시 화면 전술 데코레이션 오버레이 (가장 뒷레이어)
        // 리빌드 시 Stack 자식들의 구조적 일관성(개수/순서)을 고정하여 _CozyTacticalMenu의 상태(접힘/열림) 유실을 원천 차단
        IgnorePointer(
          ignoring: !game.isScanMode,
          child: AnimatedOpacity(
            opacity: game.isScanMode ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: _SatelliteScanFullscreenOverlay(colorHex: auth.profile?.colorHex),
          ),
        ),

        // [상단 좌측] 정밀 대칭 배치된 골드 캡슐 정보 바 (아바타 버튼과 시각적 중심 정렬 보정)
        Positioned(
          top: topOffset + 3.0,
          left: 20.0,
          child: _CozyHeaderBar(game: game),
        ),

        // [상단 우측] 독립 배치된 내 정보 아바타 버튼 (44x44 대칭 정렬)
        Positioned(
          top: topOffset, // 수평 그리드 상단 탑라인 매칭 정렬
          right: 20.0,
          child: _ProfileFloatingButton(auth: auth),
        ),

        // [하단 좌측] 독립 배치된 내 위치 / 맵 회전 토글 버튼 (42x42)
        Positioned(
          bottom: baseBottomMargin + bottomPadding + 17.0,
          left: 20.0,
          child: _MapFollowRotationButton(
            game: game,
            size: 42,
            iconSize: 20,
          ),
        ),

        // [하단 중앙] 콤팩트해진 점령 전술 조작 버튼 (단독 독점 배치)
        Positioned(
          bottom: baseBottomMargin + bottomPadding,
          left: (screenWidth - 76) / 2,
          child: SizedBox(
            width: 76,
            height: 76,
            child: Center(
              child: game.isScanMode
                  ? _SatelliteCaptureActionButton(game: game)
                  : _StartStopCaptureButton(game: game),
            ),
          ),
        ),

        // [하단 우측] 접이식 플로팅 전술 메뉴 (랭킹, 테마, 모드 수납)
        Positioned(
          bottom: baseBottomMargin + bottomPadding + 16.0,
          right: 20.0, // 화면 우측 가장자리에 완벽 밀착 배치
          child: _CozyTacticalMenu(
            key: const ValueKey('cozy_tactical_menu'), // 오버레이 탈착 및 리빌드 시 상태 유실(닫힘) 방지용 키 장착
            game: game,
          ),
        ),

        // [위성 모드] 스캔 정보창 (하단 컨트롤 데크 바로 위에 둥실 뜬 형태로 배치)
        Positioned(
          bottom: 90 + baseBottomMargin + bottomPadding,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                opacity: game.isScanMode ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: game.isScanMode
                    ? _SatelliteMapBubble(gameProvider: game)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// [상단] '솜사탕 올인원' 정보 캡슐 바 (오직 순수 GP 보유량만 극극 미니멀 노출)
class _CozyHeaderBar extends StatelessWidget {
  final GameProvider game;

  const _CozyHeaderBar({required this.game});

  @override
  Widget build(BuildContext context) {
    final double gold = game.currentGold;

    return Container(
      height: 38,
      padding: const EdgeInsets.only(left: 10, right: 16, top: 2, bottom: 2),
      decoration: ShapeDecoration(
        color: GameColors.backgroundMedium.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.25), // 시스템 시그니처 시안 보더
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
        : [const Color(0xFF37474F), const Color(0xFF212121)]; // 비활성: 다크 메탈릭 실버 젤리

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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                  color: isAuth ? Colors.white : Colors.white.withValues(alpha: 0.55),
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

/// [신규] 접이식 플로팅 전술 메뉴 (Cozy Expansion Menu)
/// 슬라이드 업 및 페이드 인 애니메이션을 결합하여 조작성을 극대화한 접이식 수직 패널 위젯
class _CozyTacticalMenu extends StatefulWidget {
  final GameProvider game;

  const _CozyTacticalMenu({super.key, required this.game});

  @override
  State<_CozyTacticalMenu> createState() => _CozyTacticalMenuState();
}

class _CozyTacticalMenuState extends State<_CozyTacticalMenu>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end, // 자식들을 우측 가장자리에 맞춰 정렬
      children: [
        // 펼쳐졌을 때 솟아오르는 세로 단추 모음
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: 1.0,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 1. 랭킹 젤리 단추
                const _RankingActionButton(size: 42),
                const SizedBox(height: 8),
                // 2. 지도 테마 순환 단추
                _MapStyleCycleButton(game: widget.game, size: 42, iconSize: 20),
                const SizedBox(height: 8),
                // 3. 모드 변경 (위성 락온) 단추
                _ScanToggleActionButton(game: widget.game, size: 42, iconSize: 20),
                const SizedBox(height: 12), // 메인 트리거와 여백
              ],
            ),
          ),
        ),

        // 전술 기어 트리거 버튼 (44x44)
        _MenuTriggerButton(
          isExpanded: _isExpanded,
          onTap: _toggleMenu,
        ),
      ],
    );
  }
}

/// [신규] 접이식 메뉴를 여닫는 하이테크 젤리 트리거 버튼
class _MenuTriggerButton extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const _MenuTriggerButton({
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<_MenuTriggerButton> createState() => _MenuTriggerButtonState();
}

class _MenuTriggerButtonState extends State<_MenuTriggerButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isExpanded = widget.isExpanded;
    final gradientColors = [const Color(0xFF00E5FF), const Color(0xFF00838F)]; // 일관성 있는 사이버 네온 시안으로 통일

    final shadowColor = const Color(0xFF00E5FF);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
                color: shadowColor.withValues(alpha: 0.35),
                blurRadius: isExpanded ? 10 : 6,
                offset: const Offset(0, 2.5),
              )
            ],
          ),
          child: Stack(
            children: [
              // 3D 반사광 젤리 오버레이
              Positioned(
                top: 2,
                left: 5,
                right: 5,
                height: 16,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                child: AnimatedRotation(
                  turns: isExpanded ? 0.125 : 0.0, // 열리고 닫힐 때 45도 회전 애니메이션
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isExpanded ? Icons.close_rounded : Icons.grid_view_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
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
              colors: [Color(0xFF00E5FF), Color(0xFF00838F)], // 일관성 있는 사이버 네온 시안 젤리
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
              )
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
                    borderRadius: BorderRadius.vertical(top: Radius.circular(glowRadius)),
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
              colors: [Color(0xFF00E5FF), Color(0xFF00838F)], // 상시 정 가동 상태인 사이버 네온 시안 젤리 톤 적용
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
              )
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
                    borderRadius: BorderRadius.vertical(top: Radius.circular(glowRadius)),
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
  final GameProvider game;
  final double size;
  final double iconSize;

  const _MapFollowRotationButton({
    required this.game,
    this.size = 42.0,
    this.iconSize = 20.0,
  });

  @override
  State<_MapFollowRotationButton> createState() => _MapFollowRotationButtonState();
}

class _MapFollowRotationButtonState extends State<_MapFollowRotationButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final isFollowing = game.isFollowingUser;
    final isRotation = game.isMapRotationMode;

    IconData icon = Icons.location_searching;
    if (isFollowing) {
      icon = isRotation ? Icons.explore : Icons.my_location;
    }

    final gradientColors = isFollowing
        ? [const Color(0xFF00E5FF), const Color(0xFF00838F)] // 활성: 사이버 네온 시안 젤리
        : [const Color(0xFF37474F), const Color(0xFF212121)]; // 비활성: 다크 메탈릭 실버 젤리

    final shadowColor = isFollowing ? const Color(0xFF00E5FF) : Colors.black;

    final double glowRadius = widget.size * 0.38;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) async {
        setState(() => _isPressed = false);
        if (!isFollowing) {
          game.setFollowingUser(true);
          if (isRotation) {
            await game.toggleMapRotationMode();
          }
        } else if (!isRotation) {
          await game.toggleMapRotationMode();
        } else {
          game.setFollowingUser(false);
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
                color: shadowColor.withValues(alpha: isFollowing ? 0.35 : 0.12),
                blurRadius: isFollowing ? 10 : 4,
                offset: const Offset(0, 2.5),
              )
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
                    borderRadius: BorderRadius.vertical(top: Radius.circular(glowRadius)),
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
                  icon,
                  color: isFollowing ? Colors.white : const Color(0xFF1565C0).withValues(alpha: 0.7),
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

/// [리뉴얼] 하단 조작계 접이식 메뉴에 탑재되는 3D 하이테크 레이더 틴트의 위성 스캔 토글 젤리 버튼
class _ScanToggleActionButton extends StatefulWidget {
  final GameProvider game;
  final double size;
  final double iconSize;

  const _ScanToggleActionButton({
    required this.game,
    this.size = 42.0,
    this.iconSize = 20.0,
  });

  @override
  State<_ScanToggleActionButton> createState() => _ScanToggleActionButtonState();
}

class _ScanToggleActionButtonState extends State<_ScanToggleActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isScanMode = widget.game.isScanMode;
    final double glowRadius = widget.size * 0.38;

    final gradientColors = isScanMode
        ? [const Color(0xFF00E5FF), const Color(0xFF00838F)] // 활성화: 사이버 네온 시안 젤리
        : [const Color(0xFF37474F), const Color(0xFF212121)]; // 비활성: 시크한 스페이스 다크 네이비 실버

    final glowColor = isScanMode ? const Color(0xFF00E5FF) : Colors.black;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.game.toggleScanMode();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
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
              color: isScanMode
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: isScanMode ? 0.45 : 0.15),
                blurRadius: isScanMode ? 10 : 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Stack(
            children: [
              // 3D 하이테크 하프 링 빛 반사
              Positioned(
                top: 2,
                left: 5,
                right: 5,
                height: glowRadius,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(glowRadius)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Icon(
                  Icons.satellite_alt_rounded, // 최첨단 입체 위성 아이콘으로 교체
                  color: isScanMode ? Colors.white : Colors.white.withValues(alpha: 0.55),
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
                  ? [const Color(0xFFFF5252), const Color(0xFFC62828)] // 작전 기동 중: 네온 레드
                  : [const Color(0xFF00E5FF), const Color(0xFF00838F)], // 대기: 사이버 네온 시안
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              // 네온 글로우 효과
              BoxShadow(
                color: (isRunning ? const Color(0xFFFF5252) : const Color(0xFF00E5FF))
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

// --- [신규] 위성 스캔 관련 추가 위젯들 ---

/// 위성 스캔 모드가 켜졌을 때 화면 전체에 전술 레이더 스캔 효과를 제공하는 오버레이
class _SatelliteScanFullscreenOverlay extends StatefulWidget {
  final String? colorHex;
  const _SatelliteScanFullscreenOverlay({this.colorHex});

  @override
  State<_SatelliteScanFullscreenOverlay> createState() =>
      _SatelliteScanFullscreenOverlayState();
}

class _SatelliteScanFullscreenOverlayState
    extends State<_SatelliteScanFullscreenOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _parseColor() {
    final hexString = widget.colorHex;
    if (hexString == null || hexString.isEmpty) {
      return const Color(0xFFFF9900); // 디폴트 주황
    }
    final hexVal = hexString.replaceFirst('#', '');
    try {
      if (hexVal.length == 6) {
        return Color(int.parse('FF$hexVal', radix: 16));
      } else if (hexVal.length == 8) {
        return Color(int.parse(hexVal, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFFFF9900);
  }

  @override
  Widget build(BuildContext context) {
    final Color scanColor = _parseColor();
    const double opacity = 0.008;
    const double borderOpacity = 0.15;

    return IgnorePointer(
      child: Stack(
        children: [
          // 전체 은은한 틴트 및 얇은 테두리
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: scanColor.withValues(alpha: borderOpacity),
                width: 1.5,
              ),
              color: scanColor.withValues(alpha: opacity),
            ),
          ),
          // 동적 전술 조준선 및 스캔라인 효과
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SatelliteScanPainter(
                    color: scanColor,
                    progress: _animController.value,
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

class _SatelliteScanPainter extends CustomPainter {
  final Color color;
  final double progress;

  _SatelliteScanPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. 가장자리 어두운 비네팅 효과 (Vignette Shadow Glow)
    final vignettePaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        size.longestSide * 0.62,
        [
          Colors.transparent,
          color.withValues(alpha: 0.04),
          Colors.black.withValues(alpha: 0.42),
        ],
        [0.0, 0.65, 1.0],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      vignettePaint,
    );

    // 2. 바둑판 형태의 전술 격자 눈금 (+) (Tactical Grid Crosses) - 요동 없이 완전히 고정
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.03)
      ..strokeWidth = 0.8;
    const double gridSize = 64.0;
    const double crossLen = 3.0;
    for (double x = gridSize; x < size.width; x += gridSize) {
      for (double y = gridSize; y < size.height; y += gridSize) {
        canvas.drawLine(
          Offset(x - crossLen, y),
          Offset(x + crossLen, y),
          gridPaint,
        );
        canvas.drawLine(
          Offset(x, y - crossLen),
          Offset(x, y + crossLen),
          gridPaint,
        );
      }
    }

    // 3. 네 귀퉁이 전술 조준 꺾쇠 (Corner Brackets)
    final bracketPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    const double bSize = 20.0;
    const double margin = 8.0;

    // 상좌
    canvas.drawPath(
      Path()
        ..moveTo(margin + bSize, margin)
        ..lineTo(margin, margin)
        ..lineTo(margin, margin + bSize),
      bracketPaint,
    );
    // 상우
    canvas.drawPath(
      Path()
        ..moveTo(size.width - margin - bSize, margin)
        ..lineTo(size.width - margin, margin)
        ..lineTo(size.width - margin, margin + bSize),
      bracketPaint,
    );
    // 하좌
    canvas.drawPath(
      Path()
        ..moveTo(margin + bSize, size.height - margin)
        ..lineTo(margin, size.height - margin)
        ..lineTo(margin, size.height - margin - bSize),
      bracketPaint,
    );
    // 하우
    canvas.drawPath(
      Path()
        ..moveTo(size.width - margin - bSize, size.height - margin)
        ..lineTo(size.width - margin, size.height - margin)
        ..lineTo(size.width - margin, size.height - margin - bSize),
      bracketPaint,
    );

    // 4. 화면 위에서 아래로 스캔하는 동적 스캔라인 광선 바 (Dynamic Sweeper Beam)
    final double sweepY = size.height * progress;
    final sweepPaint = Paint()
      ..shader = ui.Gradient.linear(Offset(0, sweepY - 35), Offset(0, sweepY), [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.07),
      ]);
    canvas.drawRect(
      Rect.fromLTRB(0, sweepY - 35, size.width, sweepY),
      sweepPaint,
    );

    // 가로 스캔 강선 레이저
    final laserPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, sweepY), Offset(size.width, sweepY), laserPaint);

    // 5. 은은한 가로 스캔라인 텍스처 (Static Scanlines)
    final scanlinePaint = Paint()
      ..color = color.withValues(alpha: 0.02)
      ..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 5.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SatelliteScanPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}

/// 현재 선택된 타일에 대해 위성 점령 실행 또는 취소 작전을 수행하는 버튼 위젯
class _SatelliteCaptureActionButton extends StatefulWidget {
  /// 게임의 핵심 인게임 비즈니스 상태를 관리하는 GameProvider 인스턴스
  final GameProvider game;

  /// [_SatelliteCaptureActionButton] 생성자
  const _SatelliteCaptureActionButton({required this.game});

  @override
  State<_SatelliteCaptureActionButton> createState() =>
      _SatelliteCaptureActionButtonState();
}

class _SatelliteCaptureActionButtonState
    extends State<_SatelliteCaptureActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final selectedId = game.selectedScanTileId;
    final bool isCapturing = game.isSatelliteCapturing;

    bool showButton = false;
    String buttonText = '';
    IconData buttonIcon = Icons.play_arrow_rounded;
    List<Color> gradientColors = [
      const Color(0xFF00E5FF),
      const Color(0xFF00838F),
    ];
    Color shadowColor = const Color(0xFF00E5FF);
    VoidCallback? onPressed;

    final auth = context.read<AuthProvider>();

    if (isCapturing) {
      showButton = true;
      buttonText = GameStrings.cancel; // '취소'
      buttonIcon = Icons.stop_rounded;
      gradientColors = [const Color(0xFFFF5252), const Color(0xFFC62828)];
      shadowColor = const Color(0xFFFF5252);
      onPressed = () => game.cancelSatelliteCapture();
    } else if (selectedId != null) {
      final existingTile = game.capturedTiles[selectedId];
      final isTileEmpty =
          existingTile == null ||
          existingTile.userId == null ||
          existingTile.userId == 'none';

      if (isTileEmpty) {
        final satCooltime = game.remainingSatelliteCaptureCoolSeconds;
        final isConnected = game.checkSatelliteCaptureConnectivity(selectedId);

        if (satCooltime <= 0 && isConnected) {
          // 위성 점령 소모 재화 부족 여부 검증
          final mainBaseId = auth.profile?.mainBaseTileId;
          int distance = 0;
          if (mainBaseId != null && mainBaseId.isNotEmpty) {
            final partsBase = mainBaseId.split('_');
            final bq = int.tryParse(partsBase[1]) ?? 0;
            final br = int.tryParse(partsBase[2]) ?? 0;
            final partsTarget = selectedId.split('_');
            final tq = int.tryParse(partsTarget[1]) ?? 0;
            final tr = int.tryParse(partsTarget[2]) ?? 0;
            distance = HexService.hexDistance(bq, br, tq, tr);
          }
          final double currentGold = game.currentGold;

          if (currentGold >= distance) {
            showButton = true;
            buttonText = '점령 실행'; // 96x96 원형 버튼 규격에 최적화된 4자 구성
            buttonIcon = Icons.satellite_alt_rounded;
            gradientColors = [const Color(0xFF00E5FF), const Color(0xFF00838F)];
            shadowColor = const Color(0xFF00E5FF);
            onPressed = () => game.executeSatelliteCapture(selectedId);
          }
        }
      }
    }

    if (!showButton) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (onPressed != null) {
          onPressed();
        }
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
              colors: gradientColors,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              // 네온 글로우 효과
              BoxShadow(
                color: shadowColor.withValues(alpha: _isPressed ? 0.15 : 0.35),
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
              // 중앙 아이콘 및 전술 한글 명칭
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(buttonIcon, color: Colors.white, size: 28),
                    const SizedBox(height: 1),
                    Text(
                      buttonText,
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
  final GameProvider gameProvider;

  const _SatelliteMapBubble({required this.gameProvider});

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
    final game = widget.gameProvider;
    final tileLatLng = game.selectedScanTileLatLng;
    final selectedId = game.selectedScanTileId;

    if (tileLatLng == null || selectedId == null) {
      return const SizedBox.shrink();
    }

    final auth = context.read<AuthProvider>();

    // 위성 점령 시도 중에는 팝업 정보창(말풍선)을 완전히 제거하여 화면을 미니멀하게 유지합니다.
    final bool isCapturing = game.isSatelliteCapturing;
    if (isCapturing) {
      return const SizedBox.shrink();
    }

    // --- 상태 계산 ---
    Color themeColor = GameColors.accentNeon;
    bool isError = false;
    bool isCooltime = false;
    String detailsText = GameStrings.satScanActive;
    String? distanceStr;
    String? timeStr;

    if (isCapturing) {
      final remainingSec = game.remainingSatelliteCaptureSeconds;
      detailsText = GameStrings.satCapturingAttempt;
      timeStr = '$remainingSec초';
    } else {
      final existingTile = game.capturedTiles[selectedId];
      final isTileEmpty =
          existingTile == null ||
          existingTile.userId == null ||
          existingTile.userId == 'none';

      if (isTileEmpty) {
        final satCooltime = game.remainingSatelliteCaptureCoolSeconds;
        final isConnected = game.checkSatelliteCaptureConnectivity(selectedId);

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
          final mainBaseId = auth.profile?.mainBaseTileId;
          int distance = 0;
          if (mainBaseId != null && mainBaseId.isNotEmpty) {
            final partsBase = mainBaseId.split('_');
            final bq = int.tryParse(partsBase[1]) ?? 0;
            final br = int.tryParse(partsBase[2]) ?? 0;
            final partsTarget = selectedId.split('_');
            final tq = int.tryParse(partsTarget[1]) ?? 0;
            final tr = int.tryParse(partsTarget[2]) ?? 0;
            distance = HexService.hexDistance(bq, br, tq, tr);
            distanceStr = '$distance GP';
          }

          // 위성 점령 소모 재화(골드) 부족 여부 검증
          final double currentGold = game.currentGold;
          if (currentGold < distance) {
            themeColor = GameColors.error;
            isError = true;
            detailsText = GameStrings.satGoldShortage;
          }

          timeStr = '$durationSec초';
        }
      } else {
        themeColor = GameColors.error;
        isError = true;
        detailsText = GameStrings.satAlreadyCapturedLabel;
      }
    }

    return SizedBox(
      width: 220.0,
      child: _BubbleColumn(
        themeColor: themeColor,
        isError: isError,
        isCooltime: isCooltime,
        detailsText: detailsText,
        distanceStr: distanceStr,
        timeStr: timeStr,
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

  const _BubbleColumn({
    required this.themeColor,
    required this.isError,
    required this.isCooltime,
    required this.detailsText,
    this.distanceStr,
    this.timeStr,
  });

  @override
  Widget build(BuildContext context) {
    // 하단 삼각형 꼬리를 제거하고 본체만 렌더링합니다.
    return _BubbleBody(
      themeColor: themeColor,
      isError: isError,
      isCooltime: isCooltime,
      detailsText: detailsText,
      distanceStr: distanceStr,
      timeStr: timeStr,
    );
  }
}

/// 말풍선 본체 위젯 (Cozy 버블 테두리 + BackdropBlur 배경)
class _BubbleBody extends StatelessWidget {
  final Color themeColor;
  final bool isError;
  final bool isCooltime;
  final String detailsText;
  final String? distanceStr;
  final String? timeStr;

  const _BubbleBody({
    required this.themeColor,
    required this.isError,
    required this.isCooltime,
    required this.detailsText,
    this.distanceStr,
    this.timeStr,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: ShapeBorderClipper(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: ShapeDecoration(
            color: GameColors.backgroundMedium.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: themeColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태 텍스트
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(right: 6, top: 1),
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      detailsText,
                      style: GoogleFonts.fredoka(
                        color: isError
                            ? GameColors.error
                            : GameColors.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              // 메트릭 배지 (거리 / 시간)
              if (distanceStr != null || timeStr != null) ...[
                const SizedBox(height: 7),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (distanceStr != null) ...[
                      _buildBadge(
                        GameStrings.satRequiredGold,
                        distanceStr!,
                        themeColor,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (timeStr != null)
                      _buildBadge(
                        isCooltime
                            ? GameStrings.satCooltimeWaitingText
                            : GameStrings.satRequiredTime,
                        timeStr!,
                        themeColor,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.quicksand(
              color: GameColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.quicksand(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
