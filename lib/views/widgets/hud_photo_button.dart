import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/location_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../services/hex_service.dart';
import '../../services/photo_service.dart';
import 'tactical_press_button.dart';
import 'tactical_dialog.dart';

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
      onTap: () async {
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

        final game = context.read<GameProvider>();
        final currentUserId = auth.user?.id;

        // 1. 이미 등록한 사진이 있는지 Supabase에서 목록 비동기 대조
        final photos = await game.loadPhotosForTile(tileId);
        final bool alreadyUploaded = photos.any((p) => p['user_id'] == currentUserId);

        if (alreadyUploaded) {
          // 이미 촬영 완료했다면 스낵바 경고 후 즉시 차단
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(GameStrings.photoLimitReached),
                backgroundColor: GameColors.error,
              ),
            );
          }
          return;
        }

        // 2. 사진촬영 즉시 실행 (카메라 활성화)
        final photoService = PhotoService();
        final imageFile = await photoService.captureCompressedPhoto();
        if (imageFile == null) return; // 촬영 취소

        if (!context.mounted) return;

        // 3. 코멘트 작성 팝업 띄우기
        final String? comment = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final controller = TextEditingController();
            return TacticalDialog(
              title: GameStrings.photoCommentLabel,
              icon: Icons.chat_bubble_outline_rounded,
              accentColor: const Color(0xFF00FFCC),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    GameStrings.photoCommentHint,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLength: 35,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      counterStyle: const TextStyle(color: Colors.white30, fontSize: 10),
                      filled: true,
                      fillColor: Colors.black38,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF00FFCC)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, ""), // 스킵
                  child: const Text('스킵', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, controller.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFCC),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );

        if (comment == null) return; // 코멘트 창 취소 시 중단

        if (!context.mounted) return;

        // 4. 업로드 실행
        final String? errorMsg = await game.uploadPhotoForTile(
          tileId,
          imageFile,
          comment: comment.isEmpty ? null : comment,
        );

        if (!context.mounted) return;

        if (errorMsg == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(GameStrings.photoUploadSuccess),
              backgroundColor: GameColors.success,
            ),
          );
          // 업적 체크 연계
          context.read<AchievementProvider>().checkAndUnlock();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${GameStrings.photoUploadFail}\n사유: $errorMsg'),
              backgroundColor: GameColors.error,
            ),
          );
        }
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
