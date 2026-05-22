import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/hex_service.dart';
import 'tactical_compass.dart';

/// 인게임 HUD 오버레이 (점수판, 점령 버튼, 유틸리티 버튼, 위성 스캔 연동)
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final auth = context.watch<AuthProvider>();
    
    // 기기별 하단 제스처바/내비게이션바 안전 영역 높이 자동 산출
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    // 여백 조율을 위한 기본 하단 마진
    final double baseBottomMargin = bottomPadding > 0 ? 24.0 : 40.0;

    return Stack(
      children: [
        // 위성 스캔 활성화 시 화면 전술 데코레이션 오버레이 (가장 뒷레이어)
        if (auth.isAuthenticated && game.isScanMode)
          const _SatelliteScanFullscreenOverlay(),

        // 상단 좌측 컨트롤 (나침반 & 당일 작전 거리 HUD)
        Positioned(
          top: 60,
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const TacticalCompass(),
              const SizedBox(height: 10),
              if (auth.isAuthenticated) ...[
                const _OperationDistanceHud(),
                const SizedBox(height: 8),
                const _OperationGoldHud(),
              ],
            ],
          ),
        ),

        // 상단 우측 컨트롤 영역 (프로필)
        Positioned(
          top: 60,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: ShapeDecoration(
                  color: GameColors.backgroundTranslucent,
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: GameColors.accentNeon,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: GameColors.accentNeon,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      '[ 시스템: ${GameStrings.capturingZone} ]',
                      style: TextStyle(
                        color: GameColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
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
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: color.withValues(alpha: isAuth ? 0.4 : 0.15),
              width: 1.0,
            ),
          ),
          shadows: [
            BoxShadow(
              color: color.withValues(alpha: isAuth ? 0.15 : 0.05),
              blurRadius: isAuth ? 8.0 : 4.0,
              spreadRadius: 0.0,
            )
          ],
        ),
        child: Icon(
          Icons.person_rounded,
          color: color,
          size: 24,
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
  State<_StartStopCaptureButton> createState() => _StartStopCaptureButtonState();
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
                  ? [const Color(0xFFFF5252), const Color(0xFF900000)]
                  : [const Color(0xFF00FFD1), const Color(0xFF006859)],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              // 네온 글로우 효과
              BoxShadow(
                color: (isRunning ? GameColors.error : GameColors.accentNeon)
                    .withValues(alpha: _isPressed ? 0.2 : 0.45),
                blurRadius: _isPressed ? 8.0 : 16.0,
                spreadRadius: 1.0,
              ),
              // 하단 3D 어둠 그림자
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                offset: _isPressed ? const Offset(0, 2) : const Offset(0, 6),
                blurRadius: _isPressed ? 4.0 : 12.0,
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(42)),
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
              // 중앙 아이콘 및 한글 고정 텍스트 (다크 그레이 대비)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      color: const Color(0xFF0A1616),
                      size: 36,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isRunning ? GameStrings.stopCaptureMode : GameStrings.startCaptureMode,
                      style: const TextStyle(
                        color: Color(0xFF0A1616),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
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

/// 위성 스캔 모드 활성화 상태를 토글하는 전술 위성 버튼 위젯

/// 위성 스캔 모드가 켜졌을 때 화면 전체에 전술 레이더 스캔 효과를 제공하는 오버레이
class _SatelliteScanFullscreenOverlay extends StatelessWidget {
  /// [_SatelliteScanFullscreenOverlay] 생성자
  const _SatelliteScanFullscreenOverlay();

  @override
  Widget build(BuildContext context) {
    const double opacity = 0.015;
    const double borderOpacity = 0.15;
    const Color scanColor = Color(0xFFFF9900);

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
          // 정적 전술 조준선 및 스캔라인 효과
          Positioned.fill(
            child: CustomPaint(
              painter: _SatelliteScanPainter(
                color: scanColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 위성 스캔 화면에 동심 전술 링, Reticle(조준선), 가로 스캔라인 등의 그래픽을 그리는 정적 커스텀 페인터
class _SatelliteScanPainter extends CustomPainter {
  /// 페인팅에 사용할 기본 전술 색상
  final Color color;

  /// [_SatelliteScanPainter] 생성자
  _SatelliteScanPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide * 0.45;

    // 1. 스캔라인 (가로선) 그리기
    final scanlinePaint = Paint()
      ..color = color.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 4.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }

    // 2. 고정 동심 전술 링 (Static Tactical Rings)
    final staticRingPaint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, maxRadius * 0.5, staticRingPaint);
    canvas.drawCircle(center, maxRadius, staticRingPaint);

    // 3. 중앙 조준선 (Reticle)
    final reticlePaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 1.0;
    
    // 중앙 십자선 (중심부 살짝 비우기)
    const double gap = 8.0;
    const double len = 16.0;
    // 가로선
    canvas.drawLine(Offset(center.dx - len, center.dy), Offset(center.dx - gap, center.dy), reticlePaint);
    canvas.drawLine(Offset(center.dx + gap, center.dy), Offset(center.dx + len, center.dy), reticlePaint);
    // 세로선
    canvas.drawLine(Offset(center.dx, center.dy - len), Offset(center.dx, center.dy - gap), reticlePaint);
    canvas.drawLine(Offset(center.dx, center.dy + gap), Offset(center.dx, center.dy + len), reticlePaint);
  }

  @override
  bool shouldRepaint(covariant _SatelliteScanPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// 현재 선택된 타일에 대해 위성 점령 실행 또는 취소 작전을 수행하는 버튼 위젯
class _SatelliteCaptureActionButton extends StatefulWidget {
  /// 게임의 핵심 인게임 비즈니스 상태를 관리하는 GameProvider 인스턴스
  final GameProvider game;

  /// [_SatelliteCaptureActionButton] 생성자
  const _SatelliteCaptureActionButton({required this.game});

  @override
  State<_SatelliteCaptureActionButton> createState() => _SatelliteCaptureActionButtonState();
}

class _SatelliteCaptureActionButtonState extends State<_SatelliteCaptureActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final selectedId = game.selectedScanTileId;
    final bool isCapturing = game.isSatelliteCapturing;

    bool showButton = false;
    String buttonText = '';
    IconData buttonIcon = Icons.play_arrow_rounded;
    List<Color> gradientColors = [const Color(0xFF00FFD1), const Color(0xFF006859)];
    Color shadowColor = GameColors.accentNeon;
    VoidCallback? onPressed;

    final auth = context.read<AuthProvider>();

    if (isCapturing) {
      showButton = true;
      buttonText = GameStrings.cancel; // '취소'
      buttonIcon = Icons.stop_rounded;
      gradientColors = [const Color(0xFFFF5252), const Color(0xFF900000)];
      shadowColor = GameColors.error;
      onPressed = () => game.cancelSatelliteCapture();
    } else if (selectedId != null) {
      final existingTile = game.capturedTiles[selectedId];
      final isTileEmpty = existingTile == null || existingTile.userId == null || existingTile.userId == 'none';

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
            gradientColors = [const Color(0xFF00FFD1), const Color(0xFF006859)];
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
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              // 네온 글로우 효과
              BoxShadow(
                color: shadowColor.withValues(alpha: _isPressed ? 0.2 : 0.45),
                blurRadius: _isPressed ? 8.0 : 16.0,
                spreadRadius: 1.0,
              ),
              // 하단 3D 어둠 그림자
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                offset: _isPressed ? const Offset(0, 2) : const Offset(0, 6),
                blurRadius: _isPressed ? 4.0 : 12.0,
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(42)),
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
              // 중앙 아이콘 및 전술 한글 명칭
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      buttonIcon,
                      color: const Color(0xFF0A1616),
                      size: 36,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      buttonText,
                      style: const TextStyle(
                        color: Color(0xFF0A1616),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
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

/// 요원의 금일 누적 작전 이동 거리를 m/km 단위로 실시간 시각화하는 HUD 위젯
class _OperationDistanceHud extends StatelessWidget {
  /// [_OperationDistanceHud] 생성자
  const _OperationDistanceHud();

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationProvider>();
    final double dist = loc.dailyDistance;

    // 미터 혹은 킬로미터 포맷팅
    final String formattedDist = dist < 1000.0
        ? '${dist.toStringAsFixed(0)} m'
        : '${(dist / 1000.0).toStringAsFixed(2)} km';

    return ClipPath(
      clipper: ShapeBorderClipper(
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: ShapeDecoration(
            color: GameColors.backgroundMedium.withValues(alpha: 0.7),
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(
                color: GameColors.accentNeon.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
          ),
          child: Text(
            formattedDist,
            style: TextStyle(
              color: GameColors.accentNeon,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
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
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: ShapeDecoration(
            color: GameColors.backgroundMedium.withValues(alpha: 0.7),
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(
                color: GameColors.accentNeon.withValues(alpha: 0.35),
                width: 1.0,
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
                style: TextStyle(
                  color: GameColors.accentNeon,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(+${ratePerHour.toStringAsFixed(1)}/h)',
                style: TextStyle(
                  color: GameColors.textPrimary.withValues(alpha: 0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


