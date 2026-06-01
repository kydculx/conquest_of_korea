import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/alert_model.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';

/// 전술 알림 아이템 위젯
class AlertWidget extends StatelessWidget {
  final GameAlert alert;

  const AlertWidget({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.type) {
      AlertType.success => GameColors.success,
      AlertType.warn => GameColors.warning,
      AlertType.error => GameColors.error,
      AlertType.info => GameColors.info,
    };

    final icon = switch (alert.type) {
      AlertType.success => Icons.check_circle_outline_rounded,
      AlertType.warn => Icons.warning_amber_rounded,
      AlertType.error => Icons.error_outline_rounded,
      AlertType.info => Icons.info_outline_rounded,
    };

    final typeLabel = switch (alert.type) {
      AlertType.success => GameStrings.alertSuccess,
      AlertType.warn => GameStrings.alertWarn,
      AlertType.error => GameStrings.alertError,
      AlertType.info => GameStrings.alertInfo,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: ShapeDecoration(
        color: GameColors.backgroundMedium.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.2),
        ),
        shadows: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // 좌측 상태 지시형 컬러 바
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 전술 타입 아이콘
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            // 알림 메시지 영역
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '[ $typeLabel ]',
                      style: GoogleFonts.fredoka(
                        color: color.withValues(alpha: 0.8),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alert.message,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: GoogleFonts.quicksand(
                        color: GameColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
