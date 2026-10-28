import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/auth_provider.dart';
import 'tactical_press_button.dart';

class DailyRecordsActionButton extends StatelessWidget {
  final double size;
  final double iconSize;

  const DailyRecordsActionButton({
    this.size = 42,
    this.iconSize = 20,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Semantics(
      button: true,
      label: GameStrings.dailyRecordTitle,
      child: TacticalPressButton(
        size: size,
        onTap: () {
          if (!auth.isAuthenticated) {
            Navigator.pushNamed(context, AppRoutes.login);
            return;
          }
          Navigator.pushNamed(context, AppRoutes.dailyRecords);
        },
        child: Icon(
          Icons.calendar_month_rounded,
          color: GameColors.tacticalWhite,
          size: iconSize,
        ),
      ),
    );
  }
}
