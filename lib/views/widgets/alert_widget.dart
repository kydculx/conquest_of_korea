import 'package:flutter/material.dart';
import '../../models/alert_model.dart';
import '../../core/constants.dart';

/// 전술 알림 아이템 위젯
class AlertWidget extends StatelessWidget {
  final GameAlert alert;

  const AlertWidget({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.type) {
      AlertType.success => GameColors.success,
      AlertType.warn    => GameColors.warning,
      AlertType.error   => GameColors.error,
      AlertType.info    => GameColors.info,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 200 / 255),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GameColors.textPrimary.withValues(alpha: 100 / 255)),
      ),
      child: Text(
        alert.message,
        style: TextStyle(
            color: GameColors.textPrimary, fontWeight: FontWeight.bold),
      ),
    );
  }
}
