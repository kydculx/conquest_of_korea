import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/location_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/hex_service.dart';
import 'tactical_press_button.dart';
import 'tactical_dialog.dart';
import 'tile_photo_viewer_dialog.dart';

/// [신규] 플레이어가 밟고 서 있는 현재 타일의 사진첩 갤러리를 확인하고
/// 즉시 현장 사진을 촬영해 등록할 수 있게 하는 카메라 솜사탕 젤리 액션 버튼
class TilePhotoActionButton extends StatelessWidget {
  final double size;
  final double iconSize;

  const TilePhotoActionButton({
    this.size = 42.0,
    this.iconSize = 20.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocationProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return TacticalPressButton(
      size: size,
      onTap: () {
        // 🔒 로그인 인증 상태 체크 가드 (미인증 시 로그인 화면으로 리다이렉션)
        if (!auth.isAuthenticated) {
          Navigator.pushNamed(context, AppRoutes.login);
          return;
        }

        final currentLocation = loc.currentLocation;
        if (currentLocation == null) {
          _showErrorDialog(context, GameStrings.gpsSignalError);
          return;
        }

        final hex = HexService.latLngToHex(currentLocation);
        final tileId = HexService.tileId(hex['q']!, hex['r']!);

        showDialog(
          context: context,
          builder: (context) => TilePhotoViewerDialog(tileId: tileId),
        );
      },
      child: Icon(
        Icons.photo_camera_rounded,
        color: GameColors.tacticalWhite,
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
