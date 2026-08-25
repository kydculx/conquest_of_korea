import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../tactical_dialog.dart';

/// 로그아웃 확인 다이얼로그. 사용자가 확인하면 true를 반환합니다.
Future<bool?> showLogoutConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => TacticalDialog(
      title: GameStrings.logoutConfirmTitle,
      icon: Icons.warning_amber_rounded,
      accentColor: GameColors.error,
      content: Text(
        GameStrings.logoutConfirmMessage,
        style: TextStyle(color: GameColors.textSecondary, fontSize: 13),
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
            backgroundColor: GameColors.error,
            foregroundColor: GameColors.tacticalWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            GameStrings.logout,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

/// 회원 탈퇴 확인 다이얼로그. 동의 체크 후에만 진행 버튼이 활성화됩니다.
/// 사용자가 확인하면 true를 반환합니다.
Future<bool?> showDeleteAccountConfirmDialog(BuildContext context) {
  bool isAgreed = false;
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return TacticalDialog(
            title: GameStrings.deleteAccountConfirmTitle,
            icon: Icons.dangerous_rounded,
            accentColor: GameColors.error,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  GameStrings.deleteAccountConfirmMessage,
                  style: TextStyle(
                    color: GameColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => setState(() => isAgreed = !isAgreed),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isAgreed,
                          onChanged: (v) => setState(() => isAgreed = v ?? false),
                          activeColor: GameColors.error,
                          checkColor: GameColors.tacticalWhite,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(color: GameColors.textMuted, width: 1.5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            GameStrings.deleteAccountCheckboxLabel,
                            style: TextStyle(
                              color: GameColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(foregroundColor: GameColors.textMuted),
                child: Text(GameStrings.cancel),
              ),
              ElevatedButton(
                onPressed: isAgreed ? () => Navigator.pop(context, true) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameColors.error,
                  foregroundColor: GameColors.tacticalWhite,
                  disabledBackgroundColor: GameColors.textMuted.withValues(alpha: 0.15),
                  disabledForegroundColor: GameColors.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  GameStrings.deleteAccount,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
