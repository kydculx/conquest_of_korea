import 'package:flutter/material.dart';

/// 상단 우측 랭킹 버튼 (트로피 아이콘)
class RankingActionButton extends StatefulWidget {
  final double size;

  const RankingActionButton({required this.size, super.key});

  @override
  State<RankingActionButton> createState() => RankingActionButtonState();
}

class RankingActionButtonState extends State<RankingActionButton> {
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
