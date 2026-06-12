import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// 어플리케이션 전반에서 일관된 스타일의 토스트(SnackBar)를 띄우기 위한 유틸리티 클래스
class ToastHelper {
  /// 지정한 메시지와 상태(성공, 에러, 일반 등)에 따른 공통 플로팅 스낵바를 출력합니다.
  static void show({
    required BuildContext context,
    required String message,
    bool isSuccess = true,
  }) {
    final statusColor = isSuccess ? GameColors.success : GameColors.error;
    final statusIcon = isSuccess 
        ? Icons.check_circle_outline_rounded 
        : Icons.error_outline_rounded;

    // 기존 스낵바가 띄워져 있다면 즉시 닫고 새로운 스낵바를 매끄럽게 노출
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: GameColors.backgroundMedium,
        content: Row(
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  color: GameColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: statusColor.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
