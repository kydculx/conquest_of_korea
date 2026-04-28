import 'package:flutter/material.dart';
import '../../models/alert_model.dart';

/// 전술 알림 아이템 위젯
class AlertWidget extends StatelessWidget {
  final GameAlert alert;

  const AlertWidget({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.type) {
      AlertType.success => Colors.green,
      AlertType.warn    => Colors.orange,
      AlertType.error   => Colors.red,
      AlertType.info    => Colors.blueGrey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(200),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(100)),
      ),
      child: Text(
        alert.message,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
