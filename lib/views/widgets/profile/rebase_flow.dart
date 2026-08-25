import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/error_translator.dart';
import '../../../core/utils/toast_helper.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/game_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../services/hex_service.dart';
import '../tactical_dialog.dart';

/// 본진 이전(Rebase) 플로우를 처리합니다.
///
/// GPS 위치 검증 → 본진 중복 여부 확인 → 골드 비용 계산/검증 →
/// 확인 다이얼로그 → 서버 반영 및 결과 토스트 순으로 진행됩니다.
Future<void> handleRebase(BuildContext context, AuthProvider auth) async {
  final loc = context.read<LocationProvider>();
  final game = context.read<GameProvider>();
  final currentLocation = loc.currentLocation;

  if (currentLocation == null) {
    ToastHelper.show(context: context, message: GameStrings.gpsSignalError, isSuccess: false);
    return;
  }

  final hex = HexService.latLngToHex(currentLocation);
  final tileId = HexService.tileId(hex['q']!, hex['r']!);

  final mainBaseId = auth.profile?.mainBaseTileId;
  if (mainBaseId == tileId) {
    await _showErrorDialog(context, GameStrings.rebaseSameLocationMessage);
    return;
  }

  final isFirstRebase = (auth.profile?.mainBaseMoveCount ?? 0) == 0;
  final distance = game.getTileDistance(tileId);
  final requiredGold = isFirstRebase ? 0.0 : (distance * 10.0);

  if (requiredGold > game.currentGold + 0.0001) {
    await _showErrorDialog(
      context,
      GameStrings.rebaseGoldShortageMessage(
        requiredGold.toInt().toString(),
        game.currentGold.toInt().toString(),
      ),
    );
    return;
  }

  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => TacticalDialog(
      title: GameStrings.rebaseConfirmTitle,
      icon: Icons.my_location_rounded,
      accentColor: GameColors.accentNeon,
      content: Text(
        isFirstRebase
            ? GameStrings.rebaseConfirmContentFirst(
                tileId: tileId,
                currentGold: game.currentGold.toInt().toString(),
              )
            : GameStrings.rebaseConfirmContent(
                tileId: tileId,
                cost: requiredGold.toInt().toString(),
                currentGold: game.currentGold.toInt().toString(),
              ),
        style: TextStyle(color: GameColors.textSecondary, fontSize: 13, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: GameColors.textMuted),
          child: Text(GameStrings.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: GameColors.accentNeon,
            foregroundColor: GameColors.tacticalBlack,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(GameStrings.rebaseButton, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  if (confirm == true && context.mounted) {
    try {
      final success = await game.rebaseMainBase(tileId, requiredGold);
      if (success && context.mounted) {
        ToastHelper.show(context: context, message: GameStrings.rebaseSuccessAlert(tileId), isSuccess: true);
      } else if (context.mounted) {
        ToastHelper.show(context: context, message: GameStrings.errorUnknown, isSuccess: false);
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.show(context: context, message: ErrorTranslator.translate(e), isSuccess: false);
      }
    }
  }
}

Future<void> _showErrorDialog(BuildContext context, String message) {
  return showDialog(
    context: context,
    builder: (context) => TacticalDialog(
      title: GameStrings.errorTitle,
      icon: Icons.error_outline_rounded,
      accentColor: GameColors.error,
      content: Text(message, style: TextStyle(color: GameColors.textSecondary, fontSize: 13)),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: GameColors.error,
            foregroundColor: GameColors.tacticalWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(GameStrings.confirm, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
