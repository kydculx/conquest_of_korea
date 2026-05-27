import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// 하이테크 전술 테마용 미세 격자 백그라운드 페인터 (다이얼로그 전용)
class TacticalDialogGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GameColors.techGrid.withValues(alpha: 20 / 255)
      ..strokeWidth = 1.0;

    const double step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 하이테크 전술 다크 테마 공통 다이얼로그 위젯
class TacticalDialog extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? accentColor;
  final Widget? content;
  final List<Widget>? actions;
  final double maxWidth;

  const TacticalDialog({
    super.key,
    required this.title,
    this.icon,
    this.accentColor,
    this.content,
    this.actions,
    this.maxWidth = 320,
  });

  @override
  Widget build(BuildContext context) {
    final activeAccent = accentColor ?? GameColors.accentNeon;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: maxWidth,
          decoration: ShapeDecoration(
            color: GameColors.backgroundMedium.withValues(alpha: 0.95),
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: activeAccent.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            shadows: [
              BoxShadow(
                color: activeAccent.withValues(alpha: 0.15),
                blurRadius: 25,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.4,
                  child: CustomPaint(
                    painter: TacticalDialogGridPainter(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            color: activeAccent,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: GameColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      color: GameColors.dividerColor.withValues(alpha: 40 / 255),
                      height: 1,
                    ),
                    if (content != null) ...[
                      const SizedBox(height: 20),
                      content!,
                    ],
                    if (actions != null && actions!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: actions!.map((action) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: action,
                          );
                        }).toList(),
                      ),
                    ],
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
