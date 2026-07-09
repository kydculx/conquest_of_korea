import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/hex_service.dart';
import 'tactical_press_button.dart';
import 'tactical_dialog.dart';

/// [신규] 내 본부 기지(HQ)로 카메라 지도를 신속 슬라이딩 이동시키고,
/// 본진이 없을 경우 현재 플레이어의 GPS 위치에 본진을 바로 선언/설정해주는 전술 젤리 액션 버튼
class HQMoveButton extends StatelessWidget {
  final double size;
  final double iconSize;

  const HQMoveButton({
    this.size = 42.0,
    this.iconSize = 20.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final loc = Provider.of<LocationProvider>(context);

    final mainBaseTileId = auth.profile?.mainBaseTileId;
    final bool hasHQ = mainBaseTileId != null &&
        mainBaseTileId.isNotEmpty &&
        mainBaseTileId != 'none';

    return TacticalPressButton(
      size: size,
      onTap: () {
        // 🔒 로그인 인증 상태 체크 가드 (미인증 시 로그인 화면으로 리다이렉션)
        if (!auth.isAuthenticated) {
          Navigator.pushNamed(context, AppRoutes.login);
          return;
        }

        if (hasHQ) {
          // 본진이 있으면 본진 좌표로 맵 이동
          final parsed = HexService.parseTileId(mainBaseTileId);
          if (parsed != null) {
            final hqLatLng = HexService.hexToLatLng(parsed['q']!, parsed['r']!);
            game.requestMapMove(hqLatLng);
            // 본진으로 이동했으므로 내 위치 트래킹(Following)은 일시 정지
            game.setFollowingUser(false);
          }
        } else {
          // 본진이 아직 설정되지 않았으면 현재 위치에 본진 설정 유도 팝업 노출
          final currentLocation = loc.currentLocation;
          if (currentLocation == null) {
            _showErrorDialog(context, GameStrings.gpsSignalError);
            return;
          }

          showDialog(
            context: context,
            builder: (context) => TacticalDialog(
              title: GameStrings.setHQConfirmTitle,
              icon: Icons.home_work_rounded,
              accentColor: GameColors.colorAccent,
              content: Text(
                GameStrings.setHQConfirmMessage,
                style: TextStyle(color: GameColors.textSecondary, fontSize: 13),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    GameStrings.cancel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final hex = HexService.latLngToHex(currentLocation);
                    final tileId = HexService.tileId(hex['q']!, hex['r']!);
                    await auth.updateMainBase(tileId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameColors.colorAccent,
                    foregroundColor: GameColors.tacticalBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    GameStrings.confirm,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }
      },
      child: Icon(
        Icons.home_work_rounded,
        color: hasHQ ? GameColors.tacticalWhite : GameColors.textMuted,
        size: iconSize,
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => TacticalDialog(
        title: GameStrings.errorTitle,
        icon: Icons.error_outline_rounded,
        accentColor: GameColors.error,
        content: Text(
          message,
          style: TextStyle(color: GameColors.textSecondary, fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: GameColors.error,
              foregroundColor: GameColors.tacticalWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              GameStrings.confirm,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
