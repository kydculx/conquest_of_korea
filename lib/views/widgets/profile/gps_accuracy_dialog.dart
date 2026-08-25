import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../providers/game_provider.dart';
import '../tactical_dialog.dart';

/// GPS 수신 정확도 선택 다이얼로그를 표시합니다.
/// 항목 선택 즉시 설정이 저장되고 다이얼로그가 닫힙니다.
void showGpsAccuracyDialog(BuildContext context, {required GameProvider game}) {
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final currentLevel = game.gpsAccuracyLevel;

          Widget buildRadioItem(String level, String titleText) {
            final isSelected = currentLevel == level;
            return InkWell(
              onTap: () async {
                await game.updateGpsAccuracy(level);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? GameColors.colorAccent.withValues(alpha: 20 / 255)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? GameColors.colorAccent
                        : GameColors.dividerColor,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: isSelected ? GameColors.colorAccent : GameColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        titleText,
                        style: TextStyle(
                          color: isSelected ? GameColors.textPrimary : GameColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return TacticalDialog(
            title: GameStrings.gpsAccuracySettings,
            icon: Icons.gps_fixed_rounded,
            accentColor: GameColors.colorAccent,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  GameStrings.gpsAccuracySettingsSub,
                  style: TextStyle(color: GameColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                buildRadioItem('high', GameStrings.gpsAccuracyHigh),
                buildRadioItem('best', GameStrings.gpsAccuracyBest),
                buildRadioItem('bestForNavigation', GameStrings.gpsAccuracyBestForNav),
                buildRadioItem('medium', GameStrings.gpsAccuracyMedium),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameColors.dividerColor,
                  foregroundColor: GameColors.textSecondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(GameStrings.cancel, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    },
  );
}
