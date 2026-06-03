import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/strings.dart';
import '../../providers/game_provider.dart';

/// 점령 시작/중지 버튼
class StartStopCaptureButton extends StatefulWidget {
  final GameProvider game;
  const StartStopCaptureButton({required this.game, super.key});

  @override
  State<StartStopCaptureButton> createState() => StartStopCaptureButtonState();
}

class StartStopCaptureButtonState extends State<StartStopCaptureButton> {
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
