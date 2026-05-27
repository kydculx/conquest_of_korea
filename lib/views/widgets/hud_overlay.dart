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
import 'tactical_compass.dart';

/// 인게임 HUD 오버레이 (점수판, 점령 버튼, 유틸리티 버튼, 위성 스캔 연동)
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final auth = context.watch<AuthProvider>();

    // 기기별 상하단 안전 영역 높이 자동 산출
    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    // Y축 정밀 오프셋 연산
    final double topOffset = topPadding > 0 ? topPadding + 12.0 : 24.0;
    final double bubbleTopOffset = topPadding > 0 ? topPadding + 120.0 : 132.0;

    // 여백 조율을 위한 기본 하단 마진
    final double baseBottomMargin = bottomPadding > 0 ? 24.0 : 40.0;

    return Stack(
      children: [
        // 위성 스캔 활성화 시 화면 전술 데코레이션 오버레이 (가장 뒷레이어)
        if (auth.isAuthenticated && game.isScanMode)
          _SatelliteScanFullscreenOverlay(colorHex: auth.profile?.colorHex),

        // 상단 좌측 컨트롤 (나침반 & 당일 작전 거리 HUD)
        Positioned(
          top: topOffset,
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const TacticalCompass(),
              const SizedBox(height: 10),
              if (auth.isAuthenticated) ...[const _OperationGoldHud()],
            ],
          ),
        ),

        // 상단 우측 컨트롤 영역 (랭킹 및 프로필)
        Positioned(
          top: topOffset,
          right: 76,
          child: _RankingButton(isAuthenticated: auth.isAuthenticated),
        ),
        Positioned(
          top: topOffset,
          right: 20,
          child: _AuthProfileButton(auth: auth),
        ),

        // 점령 중 안내 텍스트 (택티컬 터미널 메시지 스타일 - 위성 스캔 모드가 아닐 때만 노출)
        if (auth.isAuthenticated && game.isCapturing && !game.isScanMode)
          Positioned(
            bottom: 130 + baseBottomMargin + bottomPadding,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: ShapeDecoration(
                  color: GameColors.backgroundTranslucent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: GameColors.accentNeon, width: 1.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: GameColors.accentNeon,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      '[ 알림: ${GameStrings.capturingZone} ]',
                      style: GoogleFonts.fredoka(
                        color: GameColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 점령 관련 버튼 하단 배치
        if (auth.isAuthenticated)
          Positioned(
            bottom: baseBottomMargin + bottomPadding - 16,
            left: 0,
            right: 0,
            child: Center(
              child: game.isScanMode
                  ? _SatelliteCaptureActionButton(game: game)
                  : _StartStopCaptureButton(game: game),
            ),
          ),

        // 위성 점령 정보창 (최상단 레이어에 상단 중앙 고정 배치)
        if (auth.isAuthenticated && game.isScanMode)
          Positioned(
            top: bubbleTopOffset,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(child: _SatelliteMapBubble(gameProvider: game)),
            ),
          ),
      ],
    );
  }
}

class _AuthProfileButton extends StatelessWidget {
  final AuthProvider auth;
  const _AuthProfileButton({required this.auth});

  @override
  Widget build(BuildContext context) {
    final bool isAuth = auth.isAuthenticated;
    final Color color = isAuth ? GameColors.accentNeon : GameColors.textMuted;

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: color.withValues(alpha: isAuth ? 0.3 : 0.1),
              width: 1.2,
            ),
          ),
          shadows: [
            BoxShadow(
              color: color.withValues(alpha: isAuth ? 0.08 : 0.02),
              blurRadius: isAuth ? 8.0 : 4.0,
              spreadRadius: 0.0,
            ),
          ],
        ),
        child: Icon(Icons.person_rounded, color: color, size: 24),
      ),
    );
  }
}

class _RankingButton extends StatelessWidget {
  final bool isAuthenticated;
  const _RankingButton({required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    final Color color = isAuthenticated
        ? GameColors.accentNeon
        : GameColors.textMuted;

    return GestureDetector(
      onTap: () {
        if (isAuthenticated) {
          Navigator.pushNamed(context, '/ranking');
        } else {
          Navigator.pushNamed(context, '/login');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: ShapeDecoration(
          color: GameColors.backgroundMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: color.withValues(alpha: isAuthenticated ? 0.3 : 0.1),
              width: 1.2,
            ),
          ),
          shadows: [
            BoxShadow(
              color: color.withValues(alpha: isAuthenticated ? 0.08 : 0.02),
              blurRadius: isAuthenticated ? 8.0 : 4.0,
              spreadRadius: 0.0,
            ),
          ],
        ),
        child: Icon(Icons.emoji_events_rounded, color: color, size: 24),
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
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isRunning
                  ? [const Color(0xFFE57373), const Color(0xFFC62828)]
                  : [const Color(0xFF90CAF9), const Color(0xFF1E88E5)],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              // 네온 글로우 효과
              BoxShadow(
                color: (isRunning ? GameColors.error : GameColors.accentNeon)
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
                height: 42,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(42),
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
                      size: 36,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isRunning
                          ? GameStrings.stopCaptureMode
                          : GameStrings.startCaptureMode,
                      style: GoogleFonts.fredoka(
                        color: Colors.white,
                        fontSize: 12.0,
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
      const Color(0xFF90CAF9),
      const Color(0xFF1E88E5),
    ];
    Color shadowColor = GameColors.accentNeon;
    VoidCallback? onPressed;

    final auth = context.read<AuthProvider>();

    if (isCapturing) {
      showButton = true;
      buttonText = GameStrings.cancel; // '취소'
      buttonIcon = Icons.stop_rounded;
      gradientColors = [const Color(0xFFE57373), const Color(0xFFC62828)];
      shadowColor = GameColors.error;
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
            gradientColors = [const Color(0xFF90CAF9), const Color(0xFF1E88E5)];
            shadowColor = GameColors.accentNeon;
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
          width: 96,
          height: 96,
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
                height: 42,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(42),
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
                    Icon(buttonIcon, color: Colors.white, size: 36),
                    const SizedBox(height: 1),
                    Text(
                      buttonText,
                      style: GoogleFonts.fredoka(
                        color: Colors.white,
                        fontSize: 12.0,
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

/// 요원의 현재 GP 재화 잔액 및 초당 GP 생산율을 표시하는 자금 관리 HUD 위젯
class _OperationGoldHud extends StatelessWidget {
  /// [_OperationGoldHud] 생성자
  const _OperationGoldHud();

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final double gold = game.currentGold;
    final int capturedCount = game.myCapturedCount;
    final double goldRate = game.goldRate;
    final double ratePerHour = capturedCount * goldRate;

    return ClipPath(
      clipper: ShapeBorderClipper(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: ShapeDecoration(
            color: GameColors.backgroundMedium.withValues(alpha: 0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: GameColors.accentNeon.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${gold.toStringAsFixed(0)} GP',
                style: GoogleFonts.fredoka(
                  color: GameColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '(+${ratePerHour.toStringAsFixed(1)}/h)',
                style: GoogleFonts.quicksand(
                  color: GameColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
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

/// 말풍선 본체 위젯 (BeveledRect 테두리 + BackdropBlur 배경)
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
