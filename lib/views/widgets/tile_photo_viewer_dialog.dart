import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/achievement_provider.dart';
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
  int? _selectedPhotoIndex;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
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

  Future<bool> _handleDeletePhoto(String photoId, String photoUrl) async {
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

    if (confirm != true) return false;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final String? errorMsg = await game.deletePhotoForTile(widget.tileId, photoId, photoUrl);

      if (!mounted) return false;

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
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${GameStrings.photoDeleteFail}\n사유: $errorMsg'),
            backgroundColor: GameColors.error,
          ),
        );
        return false;
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
      return false;
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
      title: _selectedPhotoIndex == null ? GameStrings.tileGalleryTitle : '사진 상세',
      icon: Icons.photo_library_rounded,
      accentColor: GameColors.colorAccent,
      content: SizedBox(
        width: size.width * 0.85,
        height: size.width * 0.85, // 1:1 정사각형 공간
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(GameColors.colorAccent),
                ),
              )
            : _photos.isEmpty
                ? _buildEmptyState()
                : (_selectedPhotoIndex == null ? _buildPhotoGrid() : _buildPhotoDetailSlider()),
      ),
      actions: [
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

  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        final String photoUrl = photo['photo_url'] ?? '';

        return GestureDetector(
          onTap: () {
            _pageController = PageController(initialPage: index);
            setState(() {
              _selectedPhotoIndex = index;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: GameColors.tacticalGray.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: GameColors.dividerColor.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Hero(
              tag: 'photo_hero_$index',
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FFCC)),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white24,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoDetailSlider() {
    if (_selectedPhotoIndex == null || _selectedPhotoIndex! >= _photos.length) {
      return const SizedBox.shrink();
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.user?.id;
    
    // 현재 가리키고 있는 개별 사진 정보 획득
    final photo = _photos[_selectedPhotoIndex!];
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

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. 좌/우 스와이프를 가능케 하는 PageView 슬라이더 본체
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _photos.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _selectedPhotoIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final pagePhoto = _photos[index];
                final String pagePhotoUrl = pagePhoto['photo_url'] ?? '';

                return Hero(
                  tag: 'photo_hero_$index',
                  child: Image.network(
                    pagePhotoUrl,
                    fit: BoxFit.contain, // aspect ratio 유지하여 찌그러짐 방지
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00FFCC)),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white30,
                          size: 40,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),

        // 2. 뒤로가기 버튼 (격자형 앨범 목록으로 복귀)
        Positioned(
          top: 12,
          left: 12,
          child: GestureDetector(
            onTap: () {
              _pageController?.dispose();
              _pageController = null;
              setState(() {
                _selectedPhotoIndex = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00FFCC).withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),

        // 3. 우측 상단 내 사진 전용 삭제 아이콘
        if (isMyPhoto)
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () async {
                final bool deleted = await _handleDeletePhoto(photoId, photoUrl);
                if (deleted) {
                  // 삭제 성공 시, 만약 목록이 완전히 비었다면 그리드로 회귀
                  if (_photos.isEmpty) {
                    _pageController?.dispose();
                    _pageController = null;
                    setState(() {
                      _selectedPhotoIndex = null;
                    });
                  } else {
                    // 남은 사진이 있는 경우 뷰어 인덱스 범위 보정 바인딩
                    setState(() {
                      if (_selectedPhotoIndex! >= _photos.length) {
                        _selectedPhotoIndex = _photos.length - 1;
                      }
                      _pageController?.jumpToPage(_selectedPhotoIndex!);
                    });
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GameColors.error.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: GameColors.error,
                  size: 16,
                ),
              ),
            ),
          ),

        // 4. 슬라이더 상단 인디케이터 수치 (예: 2 / 5)
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white12,
                  width: 0.8,
                ),
              ),
              child: Text(
                '${_selectedPhotoIndex! + 1} / ${_photos.length}',
                style: GoogleFonts.fredoka(
                  color: GameColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // 5. 하단 상세 정보 그라데이션 박스
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.95),
                  Colors.black.withValues(alpha: 0.0),
                ],
              ),
            ),
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${GameStrings.photoUploader}: $uploader',
                      style: GoogleFonts.quicksand(
                        color: const Color(0xFF00FFCC),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    if (dateString.isNotEmpty)
                      Text(
                        dateString,
                        style: GoogleFonts.quicksand(
                          color: GameColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                if (photo['comment'] != null && (photo['comment'] as String).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF00FFCC).withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      photo['comment'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.0,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
