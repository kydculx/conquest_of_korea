import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
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
    
    // 기기별 하단 제스처바/내비게이션바 안전 영역 높이 자동 산출
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    // 여백 조율을 위한 기본 하단 마진
    final double baseBottomMargin = bottomPadding > 0 ? 24.0 : 40.0;

    return Stack(
      children: [
        // 위성 스캔 활성화 시 화면 전술 데코레이션 오버레이 (가장 뒷레이어)
        if (auth.isAuthenticated && game.isScanMode)
          const _SatelliteScanFullscreenOverlay(),

        // 상단 좌측 나침반 버튼
        const Positioned(
          top: 60,
          left: 20,
          child: TacticalCompass(),
        ),

        // 상단 우측 컨트롤 영역 (프로필 & 위성 스캔 모드 토글)
        if (auth.isAuthenticated)
          Positioned(
            top: 60,
            right: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SatelliteCaptureToggleButton(game: game),
                const SizedBox(width: 10),
                if (!game.isScanMode) // 스캔 모드일 때는 화면 집중에 방해되므로 프로필은 숨김
                  _AuthProfileButton(auth: auth),
              ],
            ),
          )
        else
          Positioned(
            top: 60,
            right: 20,
            child: _AuthProfileButton(auth: auth),
          ),

        // [신규] 위성 점령 HUD 패널 (상단 중앙 배치 및 좌우 정렬 일치)
        if (auth.isAuthenticated && game.isScanMode)
          Positioned(
            top: 124,
            left: 20,
            right: 20,
            child: _SatelliteCapturePanel(game: game),
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
                       isRunning ? GameStrings.stopCaptureModeKo : GameStrings.startCaptureModeKo,
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

class _SatelliteCaptureToggleButton extends StatelessWidget {
  final GameProvider game;
  const _SatelliteCaptureToggleButton({required this.game});

  @override
  Widget build(BuildContext context) {
    final bool isScanMode = game.isScanMode;
    // 활성화 시 네온 청록색, 비활성화 시 연한 회색
    final Color themeColor = isScanMode ? GameColors.accentNeon : GameColors.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            game.toggleScanMode();
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: ShapeDecoration(
              color: GameColors.backgroundMedium,
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: themeColor.withValues(alpha: isScanMode ? 0.4 : 0.15),
                  width: 1.0,
                ),
              ),
              shadows: isScanMode
                  ? [
                      BoxShadow(
                        color: themeColor.withValues(alpha: 0.15),
                        blurRadius: 6.0,
                        spreadRadius: 0.0,
                      )
                    ]
                  : null,
            ),
            child: Icon(
              Icons.satellite_alt_rounded,
              color: themeColor,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

class _SatelliteCapturePanel extends StatefulWidget {
  final GameProvider game;
  const _SatelliteCapturePanel({required this.game});

  @override
  State<_SatelliteCapturePanel> createState() => _SatelliteCapturePanelState();
}

class _SatelliteCapturePanelState extends State<_SatelliteCapturePanel> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final selectedId = game.selectedScanTileId;
    final auth = context.read<AuthProvider>();

    final bool isCapturing = game.isSatelliteCapturing;

    Color themeColor = GameColors.accentNeon;
    bool isError = false;
    bool isCooltime = false;
    String detailsText = '위성 스캔 활성화됨. 타일을 조준하십시오.';
    String? distanceStr;
    String? timeStr;

    if (isCapturing) {
      final remainingSec = game.remainingSatelliteCaptureSeconds;
      themeColor = GameColors.accentNeon;
      detailsText = '전술 위성 채널 점령 시도 중...';
      timeStr = '$remainingSec초';
    } else if (selectedId != null) {
      final existingTile = game.capturedTiles[selectedId];
      final isTileEmpty = existingTile == null || existingTile.userId == null || existingTile.userId == 'none';

      if (isTileEmpty) {
        final satCooltime = game.remainingSatelliteCaptureCoolSeconds;
        final isConnected = game.checkSatelliteCaptureConnectivity(selectedId);

        if (satCooltime > 0) {
          final minutes = satCooltime ~/ 60;
          final seconds = satCooltime % 60;
          final timeVal = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
          themeColor = const Color(0xFFFF9900);
          isCooltime = true;
          detailsText = '위성 재충전 대기 중';
          timeStr = timeVal;
        } else if (!isConnected) {
          themeColor = GameColors.error;
          isError = true;
          detailsText = '메인 기지 및 점령지 미연결 (점령 불가)';
        } else {
          final durationSec = game.getSatelliteCaptureDurationSeconds(selectedId);
          themeColor = GameColors.accentNeon;
          detailsText = '위성 락온 완료. 데이터 전송 대기.';

          final mainBaseId = auth.profile?.mainBaseTileId;
          if (mainBaseId != null && mainBaseId.isNotEmpty) {
            final partsBase = mainBaseId.split('_');
            final bq = int.tryParse(partsBase[1]) ?? 0;
            final br = int.tryParse(partsBase[2]) ?? 0;
            final partsTarget = selectedId.split('_');
            final tq = int.tryParse(partsTarget[1]) ?? 0;
            final tr = int.tryParse(partsTarget[2]) ?? 0;
            final dist = HexService.hexDistance(bq, br, tq, tr);
            distanceStr = '$dist타일';
          }
          timeStr = '$durationSec초';
        }
      } else {
        themeColor = GameColors.error;
        isError = true;
        detailsText = '이미 점령된 구역입니다.';
      }
    }

    return ClipPath(
      clipper: ShapeBorderClipper(
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: ShapeDecoration(
            color: GameColors.backgroundMedium.withValues(alpha: 0.65),
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: themeColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    detailsText,
                    style: TextStyle(
                      color: isError ? GameColors.error : GameColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (distanceStr != null || timeStr != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (distanceStr != null) ...[
                          _buildMetricItem('DIST', distanceStr, themeColor),
                          const SizedBox(width: 12),
                        ],
                        if (timeStr != null)
                          _buildMetricItem(
                            isCooltime ? 'COOL' : 'TIME',
                            timeStr,
                            themeColor,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: GameColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              fontFamily: 'Courier',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }
}

class _SatelliteScanFullscreenOverlay extends StatelessWidget {
  const _SatelliteScanFullscreenOverlay();

  @override
  Widget build(BuildContext context) {
    const double opacity = 0.015;
    const double borderOpacity = 0.12;
    
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFFF9900).withValues(alpha: borderOpacity),
            width: 1.0,
          ),
        ),
        child: Stack(
          children: [
            // 화면 구석 전술 브래킷 표시
            _buildCornerBracket(Alignment.topLeft),
            _buildCornerBracket(Alignment.topRight),
            _buildCornerBracket(Alignment.bottomLeft),
            _buildCornerBracket(Alignment.bottomRight),
            
            // 화면 전체에 은은하게 퍼지는 오렌지색 틴트
            Container(
              color: const Color(0xFFFF9900).withValues(alpha: opacity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerBracket(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 18,
        height: 18,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: _getBorderForAlignment(alignment),
        ),
      ),
    );
  }

  Border _getBorderForAlignment(Alignment alignment) {
    const Color orange = Color(0xFFFF9900);
    const BorderSide side = BorderSide(color: orange, width: 1.0);
    const BorderSide none = BorderSide.none;

    if (alignment == Alignment.topLeft) {
      return const Border(top: side, left: side, right: none, bottom: none);
    } else if (alignment == Alignment.topRight) {
      return const Border(top: side, right: side, left: none, bottom: none);
    } else if (alignment == Alignment.bottomLeft) {
      return const Border(bottom: side, left: side, top: none, right: none);
    } else {
      return const Border(bottom: side, right: side, top: none, left: none);
    }
  }
}

class _SatelliteCaptureActionButton extends StatelessWidget {
  final GameProvider game;
  const _SatelliteCaptureActionButton({required this.game});

  @override
  Widget build(BuildContext context) {
    final selectedId = game.selectedScanTileId;
    final bool isCapturing = game.isSatelliteCapturing;

    bool showButton = false;
    String buttonText = '';
    Color buttonColor = GameColors.accentNeon;
    VoidCallback? onPressed;

    if (isCapturing) {
      showButton = true;
      buttonText = '취소';
      buttonColor = GameColors.error;
      onPressed = () => game.cancelSatelliteCapture();
    } else if (selectedId != null) {
      final existingTile = game.capturedTiles[selectedId];
      final isTileEmpty = existingTile == null || existingTile.userId == null || existingTile.userId == 'none';

      if (isTileEmpty) {
        final satCooltime = game.remainingSatelliteCaptureCoolSeconds;
        final isConnected = game.checkSatelliteCaptureConnectivity(selectedId);

        if (satCooltime <= 0 && isConnected) {
          showButton = true;
          buttonText = '점령 실행';
          buttonColor = GameColors.accentNeon;
          onPressed = () => game.executeSatelliteCapture(selectedId);
        }
      }
    }

    if (!showButton) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 160,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor,
          side: BorderSide(color: buttonColor, width: 1.5),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: GameColors.backgroundMedium.withValues(alpha: 0.8),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onPressed,
        child: Text(
          buttonText,
          style: TextStyle(
            color: buttonColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
