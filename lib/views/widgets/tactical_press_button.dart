import 'package:flutter/material.dart';

/// HUD 원형 버튼의 공통 누름 상태(press-state) 애니메이션과 3D 젤리 스타일을
/// 캡슐화한 재사용 가능한 버튼 위젯.
///
/// [size] 버튼의 가로/세로 크기
/// [onTap] 버튼 탭 콜백
/// [child] 버튼 내부에 렌더링할 위젯 (Icon, 텍스트 등)
/// [pressedScale] 눌렸을 때 축소 비율 (기본 0.88)
/// [gradientColors] 상단-하단 그라데이션 색상 (기본 사이버 네온 시안)
class TacticalPressButton extends StatefulWidget {
  final double size;
  final VoidCallback onTap;
  final Widget child;
  final double pressedScale;
  final List<Color> gradientColors;
  final Color shadowColor;
  final double shadowBlur;

  const TacticalPressButton({
    required this.size,
    required this.onTap,
    required this.child,
    this.pressedScale = 0.88,
    this.gradientColors = const [Color(0xFF00E5FF), Color(0xFF00838F)],
    this.shadowColor = const Color(0xFF00E5FF),
    this.shadowBlur = 6.0,
    super.key,
  });

  @override
  State<TacticalPressButton> createState() => _TacticalPressButtonState();
}

class _TacticalPressButtonState extends State<TacticalPressButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double glowRadius = widget.size * 0.38;
    final double effectiveBlur =
        _isPressed ? widget.shadowBlur * 0.6 : widget.shadowBlur;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: widget.gradientColors,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor.withValues(alpha: 0.25),
                blurRadius: effectiveBlur,
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
              Center(child: widget.child),
            ],
          ),
        ),
      ),
    );
  }
}
