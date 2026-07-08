import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../services/photo_service.dart';
import 'tactical_dialog.dart';

/// [신규] 특정 헥사곤 타일 내부 사진첩 갤러리를 전술풍 카드 스타일로 부드럽게 감상하고,
/// 현장 카메라 사진 촬영 및 업로드 파이프라인을 중계해주는 전용 갤러리 팝업 위젯
class TilePhotoViewerDialog extends StatefulWidget {
  final String tileId;

  const TilePhotoViewerDialog({super.key, required this.tileId});

  @override
  State<TilePhotoViewerDialog> createState() => _TilePhotoViewerDialogState();
}

class _TilePhotoViewerDialogState extends State<TilePhotoViewerDialog> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _photos = [];

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final game = context.read<GameProvider>();
      final loaded = await game.loadPhotosForTile(widget.tileId);
      if (mounted) {
        setState(() {
          _photos = loaded;
        });
      }
    } catch (e) {
      debugPrint('❌ 타일 사진 로딩 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCaptureAndUpload() async {
    final game = context.read<GameProvider>();
    final auth = context.read<AuthProvider>();
    final currentUserId = auth.user?.id;

    // 1인 1타일 1사진 업로드 규칙 위반 검사
    final bool alreadyUploaded = _photos.any((p) => p['user_id'] == currentUserId);
    if (alreadyUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(GameStrings.photoLimitReached),
          backgroundColor: GameColors.error,
        ),
      );
      return;
    }

    final photoService = PhotoService();

    // 1. 카메라 촬영 & 최적화 압축 가공 (150KB 규격)
    final File? imageFile = await photoService.captureCompressedPhoto();
    if (imageFile == null) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    // 2. Supabase 업로드 및 연동 DB 인서트 실행
    final String? errorMsg = await game.uploadPhotoForTile(widget.tileId, imageFile);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (errorMsg == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(GameStrings.photoUploadSuccess),
            backgroundColor: GameColors.success,
          ),
        );
        _loadPhotos(); // 목록 리프레시
        if (context.mounted) {
          context.read<AchievementProvider>().checkAndUnlock();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${GameStrings.photoUploadFail}\n사유: $errorMsg'),
            backgroundColor: GameColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleDeletePhoto(String photoId, String photoUrl) async {
    final game = context.read<GameProvider>();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => TacticalDialog(
        title: GameStrings.deletePhotoConfirmTitle,
        icon: Icons.delete_forever_rounded,
        accentColor: GameColors.error,
        content: Text(
          GameStrings.deletePhotoConfirmMessage,
          style: TextStyle(color: GameColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              GameStrings.cancel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
              GameStrings.confirm,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final String? errorMsg = await game.deletePhotoForTile(widget.tileId, photoId, photoUrl);

      if (!mounted) return;

      if (errorMsg == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(GameStrings.photoDeleteSuccess),
            backgroundColor: GameColors.success,
          ),
        );
        _loadPhotos(); // 목록 리프레시
        if (context.mounted) {
          context.read<AchievementProvider>().checkAndUnlock();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${GameStrings.photoDeleteFail}\n사유: $errorMsg'),
            backgroundColor: GameColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${GameStrings.photoDeleteFail}\n오류: $e'),
            backgroundColor: GameColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return TacticalDialog(
      title: GameStrings.tileGalleryTitle,
      icon: Icons.photo_library_rounded,
      accentColor: GameColors.colorAccent,
      content: SizedBox(
        width: size.width * 0.85,
        height: size.width * 0.85, // 1:1 정사이즈 비율 영역 확보
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(GameColors.colorAccent),
                ),
              )
            : _photos.isEmpty
                ? _buildEmptyState()
                : _buildPhotoSlider(),
      ),
      actions: [
        // 사진 등록 액션 버튼
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleCaptureAndUpload,
          style: ElevatedButton.styleFrom(
            backgroundColor: GameColors.colorAccent,
            foregroundColor: GameColors.tacticalBlack,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.photo_camera_rounded, size: 18),
          label: Text(
            GameStrings.uploadPhotoAction,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        // 닫기 버튼
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            GameStrings.confirm,
            style: TextStyle(
              color: GameColors.textSecondary,
              fontWeight: kIsWeb ? FontWeight.normal : FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.no_photography_rounded,
          color: GameColors.textMuted.withValues(alpha: 0.5),
          size: 56,
        ),
        const SizedBox(height: 16),
        Text(
          GameStrings.noPhotosInTile,
          style: TextStyle(
            color: GameColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPhotoSlider() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.user?.id;

    return PageView.builder(
      itemCount: _photos.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final photo = _photos[index];
        final String photoId = photo['id'] ?? '';
        final String uploaderId = photo['user_id'] ?? '';
        final bool isMyPhoto = currentUserId != null && uploaderId == currentUserId;
        final String photoUrl = photo['photo_url'] ?? '';
        final String uploader = photo['user_nickname'] ?? 'None';
        final String rawDate = photo['created_at'] ?? '';
        
        String dateString = '';
        try {
          if (rawDate.isNotEmpty) {
            final dt = DateTime.parse(rawDate).toLocal();
            dateString = '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          }
        } catch (_) {}

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Container(
            decoration: BoxDecoration(
              color: GameColors.tacticalGray.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: GameColors.dividerColor,
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 이미지 렌더링
                Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          GameColors.colorAccent,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: GameColors.error.withValues(alpha: 0.6),
                        size: 40,
                      ),
                    );
                  },
                ),
                // 하단 정보 그라데이션 오버레이
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.85),
                          Colors.black.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${GameStrings.photoUploader}: $uploader',
                          style: GoogleFonts.quicksand(
                            color: GameColors.colorAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (dateString.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            dateString,
                            style: GoogleFonts.quicksand(
                              color: GameColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // 슬라이더 인디케이터 수치 (예: 1 / 5)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1} / ${_photos.length}',
                      style: GoogleFonts.fredoka(
                        color: GameColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (isMyPhoto)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: GestureDetector(
                      onTap: () => _handleDeletePhoto(photoId, photoUrl),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: GameColors.error.withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          Icons.delete_forever_rounded,
                          color: GameColors.error,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
