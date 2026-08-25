import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/game_config.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/error_translator.dart';
import '../../../core/utils/toast_helper.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/game_provider.dart';
import '../tactical_dialog.dart';

/// 닉네임 변경 다이얼로그를 표시합니다.
///
/// 중복 확인 → 골드 잔액 검증 → 서버 변경 순으로 진행되며,
/// 모든 실패 케이스는 토스트로 안내합니다.
void showNicknameChangeDialog(
  BuildContext context, {
  required AuthProvider auth,
  required GameProvider game,
}) {
  final nicknameController = TextEditingController(text: auth.profile?.nickname ?? '');
  final formKey = GlobalKey<FormState>();

  bool isNicknameChecked = false;
  bool isNicknameAvailable = false;
  bool isChecking = false;
  bool isSaving = false;

  final currentNickname = auth.profile?.nickname ?? '';
  const double cost = GameConfig.nicknameChangeCost;
  final bool hasEnoughGold = game.currentGold >= cost - 0.0001;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> checkNickname() async {
            final newNickname = nicknameController.text.trim();
            if (newNickname.isEmpty) {
              ToastHelper.show(context: context, message: GameStrings.enterNickname, isSuccess: false);
              return;
            }
            if (newNickname.contains(' ')) {
              ToastHelper.show(context: context, message: GameStrings.errorNicknameContainsSpace, isSuccess: false);
              return;
            }
            if (newNickname == currentNickname) {
              ToastHelper.show(context: context, message: GameStrings.nicknameChangeSame, isSuccess: false);
              return;
            }
            setState(() => isChecking = true);
            try {
              final available = await auth.isNicknameAvailable(newNickname);
              setState(() {
                isNicknameAvailable = available;
                isNicknameChecked = true;
              });
              if (context.mounted) {
                ToastHelper.show(
                  context: context,
                  message: available ? GameStrings.nicknameAvailable : GameStrings.errorNicknameExists,
                  isSuccess: available,
                );
              }
            } catch (e) {
              if (context.mounted) {
                ToastHelper.show(context: context, message: ErrorTranslator.translate(e), isSuccess: false);
              }
            } finally {
              setState(() => isChecking = false);
            }
          }

          Future<void> handleSave() async {
            final newNickname = nicknameController.text.trim();
            if (newNickname.contains(' ')) {
              ToastHelper.show(context: context, message: GameStrings.errorNicknameContainsSpace, isSuccess: false);
              return;
            }
            if (newNickname == currentNickname) {
              Navigator.pop(context);
              return;
            }
            if (!isNicknameChecked || !isNicknameAvailable) {
              ToastHelper.show(context: context, message: GameStrings.errorNicknameCheckRequired, isSuccess: false);
              return;
            }
            if (!hasEnoughGold) {
              ToastHelper.show(context: context, message: GameStrings.nicknameChangeGoldShortage, isSuccess: false);
              return;
            }
            setState(() => isSaving = true);
            try {
              await auth.changeNickname(
                newNickname: newNickname,
                currentGold: game.currentGold,
                cost: cost,
              );
              await game.syncGoldWithServer();
              if (context.mounted) {
                ToastHelper.show(context: context, message: GameStrings.nicknameChangeSuccess, isSuccess: true);
                Navigator.pop(context);
              }
            } catch (e) {
              if (context.mounted) {
                ToastHelper.show(context: context, message: ErrorTranslator.translate(e), isSuccess: false);
              }
            } finally {
              setState(() => isSaving = false);
            }
          }

          nicknameController.addListener(() {
            final val = nicknameController.text.trim();
            setState(() {
              if (isNicknameChecked && val != currentNickname) {
                isNicknameChecked = false;
                isNicknameAvailable = false;
              }
            });
          });

          Color getBorderColor() {
            if (isNicknameChecked) {
              return isNicknameAvailable ? GameColors.success : GameColors.error;
            }
            return GameColors.borderNeon;
          }

          final activeBorderColor = getBorderColor();

          return TacticalDialog(
            title: GameStrings.changeNickname,
            icon: Icons.edit_rounded,
            accentColor: GameColors.accentNeon,
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    GameStrings.changeNicknameSub,
                    style: TextStyle(color: GameColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nicknameController,
                    style: GoogleFonts.quicksand(color: GameColors.textPrimary, fontWeight: FontWeight.bold),
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                    decoration: InputDecoration(
                      hintText: GameStrings.enterNickname,
                      hintStyle: TextStyle(color: GameColors.textMuted),
                      filled: true,
                      fillColor: GameColors.backgroundMedium.withValues(alpha: 0.5),
                      contentPadding: const EdgeInsets.only(left: 16, right: 8, top: 14, bottom: 14),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      suffixIcon: isChecking
                          ? const Padding(
                              padding: EdgeInsets.only(right: 16),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Palette.accentCyan,
                                ),
                              ),
                            )
                          : isNicknameChecked
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Icon(
                                    isNicknameAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                    color: isNicknameAvailable ? GameColors.success : GameColors.error,
                                    size: 20,
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: TextButton(
                                    onPressed: nicknameController.text.trim().isEmpty ||
                                            nicknameController.text.trim() == currentNickname
                                        ? null
                                        : checkNickname,
                                    style: TextButton.styleFrom(
                                      foregroundColor: GameColors.accentNeon,
                                      disabledForegroundColor: GameColors.textMuted.withValues(alpha: 0.4),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    child: Text(
                                      GameStrings.checkDuplicate,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: activeBorderColor, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: activeBorderColor, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isNicknameChecked ? activeBorderColor : GameColors.accentNeon,
                          width: 2.0,
                        ),
                      ),
                    ),
                    maxLength: 10,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        GameStrings.nicknameChangeCost(
                          cost.toInt().toString(),
                          game.currentGold.toInt().toString(),
                        ),
                        style: TextStyle(
                          color: hasEnoughGold ? GameColors.textMuted : GameColors.error,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: GameColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(GameStrings.cancel),
              ),
              ElevatedButton(
                onPressed: (isNicknameChecked && isNicknameAvailable && hasEnoughGold && !isSaving) ? handleSave : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameColors.accentNeon,
                  foregroundColor: GameColors.tacticalBlack,
                  disabledBackgroundColor: GameColors.accentNeon.withValues(alpha: 0.15),
                  disabledForegroundColor: GameColors.textMuted.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 0,
                ),
                child: isSaving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: GameColors.tacticalBlack,
                        ),
                      )
                    : Text(GameStrings.confirm, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    },
  );
}
