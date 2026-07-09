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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return TacticalDialog(
      title: GameStrings.tileGalleryTitle,
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
                : _buildPhotoGrid(),
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
          onTap: () async {
            // 그리드 썸네일 탭 시 전체 화면 상세 슬라이더로 진입
            final bool? needsReload = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => TilePhotoDetailScreen(
                  initialPhotos: _photos,
                  initialIndex: index,
                  tileId: widget.tileId,
                ),
              ),
            );
            if (needsReload == true && mounted) {
              _loadPhotos(); // 삭제 이벤트 반영 리프레시
            }
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
}

/// [신규] 선택된 사진부터 가득 찬 전 화면 스와이프로 감상하며
/// 핀치 줌 확대와 상세 정보(코멘트 카드)를 보여주는 전체 화면 이미지 뷰어
class TilePhotoDetailScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initialPhotos;
  final int initialIndex;
  final String tileId;

  const TilePhotoDetailScreen({
    super.key,
    required this.initialPhotos,
    required this.initialIndex,
    required this.tileId,
  });

  @override
  State<TilePhotoDetailScreen> createState() => _TilePhotoDetailScreenState();
}

class _TilePhotoDetailScreenState extends State<TilePhotoDetailScreen> {
  late List<Map<String, dynamic>> _photos;
  late int _currentIndex;
  late PageController _pageController;
  bool _isLoading = false;
  bool _anyDeleted = false;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.initialPhotos);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

    setState(() {
      _isLoading = true;
    });

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
        
        _anyDeleted = true;
        setState(() {
          _photos.removeAt(_currentIndex);
          _isLoading = false;
          if (_photos.isEmpty) {
            // 모든 사진 삭제 시 그리드로 리턴
            Navigator.pop(context, true);
          } else {
            // 인덱스 교정
            if (_currentIndex >= _photos.length) {
              _currentIndex = _photos.length - 1;
            }
            _pageController.jumpToPage(_currentIndex);
          }
        });
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
        setState(() {
          _isLoading = false;
        });
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty || _currentIndex >= _photos.length) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.user?.id;
    final photo = _photos[_currentIndex];
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

    return PopScope(
      canPop: !_isLoading,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _anyDeleted) {
          // 뒤로가기 시 삭제 항목이 있었다면 그리드 팝업에게 리로드 시그널 반환
          Navigator.pop(context, true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. 전체 화면을 슬라이딩 스와이프하는 PageView 본체
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _photos.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final pagePhoto = _photos[index];
                  final String pagePhotoUrl = pagePhoto['photo_url'] ?? '';

                  return InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.0,
                    child: Hero(
                      tag: 'photo_hero_$index',
                      child: Image.network(
                        pagePhotoUrl,
                        fit: BoxFit.contain,
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
                    ),
                  );
                },
              ),
            ),

            // 2. 뒤로가기 단추
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context, _anyDeleted);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00FFCC).withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),

            // 3. 우측 상단 내 사진 전용 삭제 아이콘
            if (isMyPhoto)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => _handleDeletePhoto(photoId, photoUrl),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
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

            // 4. 슬라이더 상단 인디케이터 수치 (예: 3 / 8)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white12,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${GameStrings.photoDetailTitle}  |  ',
                        style: const TextStyle(
                          color: Color(0xFF00FFCC),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_currentIndex + 1} / ${_photos.length}',
                        style: GoogleFonts.fredoka(
                          color: GameColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.95),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                padding: EdgeInsets.fromLTRB(16, 24, 16, MediaQuery.of(context).padding.bottom + 24),
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
                            fontSize: 14,
                          ),
                        ),
                        if (dateString.isNotEmpty)
                          Text(
                            dateString,
                            style: GoogleFonts.quicksand(
                              color: GameColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    if (photo['comment'] != null && (photo['comment'] as String).isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF00FFCC).withValues(alpha: 0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          photo['comment'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.0,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // 로딩 오버레이
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FFCC)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
