import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/auth_provider.dart';
import '../../services/hex_service.dart';
import '../../services/photo_service.dart';
import '../widgets/tactical_app_bar.dart';
import '../widgets/tile_photo_viewer_dialog.dart';

/// 현재 위치에서 가까운 순서대로 전체 타일 사진을 격자 형태로 보여주는 갤러리 화면.
/// 하단 스크롤 시 다음 페이지를 추가로 로드합니다.
class NearbyGalleryScreen extends StatefulWidget {
  final LatLng currentLocation;

  const NearbyGalleryScreen({super.key, required this.currentLocation});

  @override
  State<NearbyGalleryScreen> createState() => _NearbyGalleryScreenState();
}

class _NearbyGalleryScreenState extends State<NearbyGalleryScreen> {
  static const int _pageSize = 60;
  static const int _maxPages = 30;
  static const List<int> _distanceSteps = [100, 200, 300, 400, 500];

  final PhotoService _photoService = PhotoService();
  final ScrollController _scrollController = ScrollController();
  final Map<String, int> _distanceCache = {};
  int? _baseQ;
  int? _baseR;
  String? _userId;

  /// 서버에서 받아온 원본 (필터 전)
  List<Map<String, dynamic>> _fetched = [];

  /// 화면에 보여주는 목록 (정렬 + 거리 + 탭 필터 적용 후)
  List<Map<String, dynamic>> _photos = [];
  int _maxTileDistance = 100;
  bool _mineOnly = false;
  int _loadedPages = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    final baseHex = HexService.latLngToHex(widget.currentLocation);
    _baseQ = baseHex['q'];
    _baseR = baseHex['r'];
    _userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
    _scrollController.addListener(_onScroll);
    _loadFirst();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 600) {
      _loadMore();
    }
  }

  int _tileDistanceOf(Map<String, dynamic> photo) {
    final tileId = (photo['tile_id'] as String?) ?? '';
    final cached = _distanceCache[tileId];
    if (cached != null) return cached;

    int distance = 1 << 30;
    final parsed = HexService.parseTileId(tileId);
    if (parsed != null && _baseQ != null && _baseR != null) {
      distance = HexService.hexDistance(
        _baseQ!,
        _baseR!,
        parsed['q'] as int,
        parsed['r'] as int,
      );
    }
    _distanceCache[tileId] = distance;
    return distance;
  }

  void _applyFilters() {
    final list = List<Map<String, dynamic>>.from(_fetched);
    list.sort((a, b) {
      final da = _tileDistanceOf(a);
      final db = _tileDistanceOf(b);
      if (da != db) return da.compareTo(db);
      return ((b['created_at'] as String?) ?? '')
          .compareTo((a['created_at'] as String?) ?? '');
    });
    _photos = list
        .where((photo) =>
            _tileDistanceOf(photo) <= _maxTileDistance &&
            (!_mineOnly || photo['user_id'] == _userId))
        .toList();
  }

  Future<void> _loadFirst() async {
    setState(() {
      _isLoading = true;
    });
    _fetched = [];
    _photos = [];
    _distanceCache.clear();
    _loadedPages = 0;
    _hasMore = true;
    await _loadMore(isFirst: true);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore({bool isFirst = false}) async {
    if (_isLoadingMore || !_hasMore || _loadedPages >= _maxPages) return;
    if (!isFirst) {
      setState(() {
        _isLoadingMore = true;
      });
    }

    final from = _loadedPages * _pageSize;
    final rows = await _photoService.fetchRecentPhotos(
      from: from,
      to: from + _pageSize - 1,
    );

    if (!mounted) return;
    setState(() {
      if (rows.length < _pageSize) _hasMore = false;
      if (rows.isNotEmpty) {
        _loadedPages++;
        _fetched.addAll(rows);
        _applyFilters();
      } else {
        _hasMore = false;
      }
      _isLoadingMore = false;
    });

    // 받아온 사진이 모두 필터 밖이면 다음 페이지를 이어서 탐색
    if (mounted &&
        _photos.isEmpty &&
        _hasMore &&
        _loadedPages < _maxPages &&
        rows.length == _pageSize) {
      await _loadMore();
    }
  }

  String _formatTileDistance(int tiles) {
    if (tiles > _maxTileDistance) return '';
    return GameStrings.tileUnit(tiles);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.tacticalBlack,
      appBar: TacticalAppBar(
        titleText: GameStrings.nearbyGalleryTitle,
        showBackButton: true,
        backgroundColor: GameColors.tacticalBlack,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(GameStrings.nearbyGalleryAll),
                  icon: const Icon(Icons.grid_view_rounded, size: 16),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(GameStrings.nearbyGalleryMine),
                  icon: const Icon(Icons.person_rounded, size: 16),
                ),
              ],
              selected: {_mineOnly},
              showSelectedIcon: false,
              onSelectionChanged: (selected) {
                setState(() {
                  _mineOnly = selected.first;
                  _applyFilters();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.straighten_rounded,
                  size: 16,
                  color: Colors.white54,
                ),
                Expanded(
                  child: Slider(
                    value: _maxTileDistance.toDouble(),
                    min: _distanceSteps.first.toDouble(),
                    max: _distanceSteps.last.toDouble(),
                    divisions: _distanceSteps.length - 1,
                    label: GameStrings.tileUnit(_maxTileDistance),
                    onChanged: (value) {
                      final next = value.round();
                      if (next == _maxTileDistance) return;
                      setState(() {
                        _maxTileDistance = next;
                        _applyFilters();
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    GameStrings.tileUnit(_maxTileDistance),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _photos.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadFirst,
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: _photos.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _photos.length) {
                              return const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                            final photo = _photos[index];
                            final distanceText =
                                _formatTileDistance(_tileDistanceOf(photo));
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TilePhotoDetailScreen(
                                      initialPhotos: _photos,
                                initialIndex: index,
                                tileId: (photo['tile_id'] as String?) ?? '',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: GameColors.tacticalGray
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    (photo['photo_url'] as String?) ?? '',
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }
                                      return const Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) {
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
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: GameColors.dividerColor
                                            .withValues(alpha: 0.55),
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (distanceText.isNotEmpty)
                                Positioned(
                                  left: 6,
                                  bottom: 6,
                                  child: IgnorePointer(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        distanceText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                            ),
                          ),
                        ),
                      ],
                    ),
              );
            }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.no_photography_rounded,
            color: GameColors.textMuted.withValues(alpha: 0.5),
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            GameStrings.nearbyGalleryEmpty,
            style: TextStyle(
              color: GameColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
