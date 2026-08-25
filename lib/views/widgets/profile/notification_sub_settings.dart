import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../providers/game_provider.dart';
import '../profile_widgets.dart';

/// 알림 마스터 스위치가 켜져 있을 때 하위 세부 알림 토글 목록을 표시합니다.
class NotificationSubSettings extends StatelessWidget {
  final GameProvider game;

  const NotificationSubSettings({required this.game, super.key});

  @override
  Widget build(BuildContext context) {
    if (!game.isNotificationEnabled) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 12, bottom: 8, top: 4),
      color: GameColors.backgroundMedium.withValues(alpha: 0.2),
      child: Column(
        children: [
          ProfileSubMenuItem(
            title: GameStrings.notifTerritoryAttackTitle,
            subtitle: GameStrings.notifTerritoryAttackSub,
            value: game.isNotifTerritoryAttack,
            onChanged: (val) => game.toggleNotifTerritoryAttack(),
          ),
          const ProfileSubDivider(),
          ProfileSubMenuItem(
            title: GameStrings.notifSatelliteCompleteTitle,
            subtitle: GameStrings.notifSatelliteCompleteSub,
            value: game.isNotifSatelliteComplete,
            onChanged: (val) => game.toggleNotifSatelliteComplete(),
          ),
          const ProfileSubDivider(),
          ProfileSubMenuItem(
            title: GameStrings.notifSystemNoticeTitle,
            subtitle: GameStrings.notifSystemNoticeSub,
            value: game.isNotifSystemNotice,
            onChanged: (val) => game.toggleNotifSystemNotice(),
          ),
        ],
      ),
    );
  }
}
