import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flame/game.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../game/conquest_game.dart';
import '../../core/constants.dart';
import '../../providers/game_provider.dart';

/// 지도(FlutterMap) + Flame 엔진 레이어를 결합한 위젯
class GameMapWidget extends StatefulWidget {
  final LatLng initialLocation;
  final ConquestGame game;

  const GameMapWidget({
    super.key,
    required this.initialLocation,
    required this.game,
  });

  @override
  State<GameMapWidget> createState() => _GameMapWidgetState();
}

class _GameMapWidgetState extends State<GameMapWidget>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _isFollowing = true;
  double _currentZoom = GameConstants.defaultZoom;

  // 2023-07 최신 경계선 데이터
  List<Polyline> _boundaryPolylines = [];
  List<Polyline> _sidoPolylines = [];
  bool _isLoadingBoundaries = true;

  @override
  void initState() {
    super.initState();
    _loadAllBoundaries();
  }

  @override
  void didUpdateWidget(GameMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 위치가 갱신되었고 '내 위치 추적' 모드라면 지도를 이동시킴
    if (_isFollowing && widget.initialLocation != oldWidget.initialLocation) {
      _animatedMapMove(widget.initialLocation, _currentZoom);
    }
  }

  Future<void> _loadAllBoundaries() async {
    // 부하 분산을 위해 순차적으로 로드
    await _loadBoundary('assets/data/korea_outline_2023.json', isOutline: true);
    await _loadBoundary('assets/data/korea_sido_2023.json', isOutline: false);

    if (mounted) {
      setState(() => _isLoadingBoundaries = false);
    }
  }

  /// 공통 GeoJSON 로드 로직
  Future<void> _loadBoundary(
    String assetPath, {
    required bool isOutline,
  }) async {
    try {
      final String jsonString = await rootBundle.loadString(assetPath);

      // 무거운 파싱 작업은 Isolate에서 수행
      final List<List<LatLng>> allPoints = await compute(
        _parseGeoJson,
        jsonString,
      );

      final color = isOutline
          ? GameConstants.accentNeon.withValues(alpha: 0.8)
          : Colors.white.withValues(alpha: 0.4);
      final strokeWidth = isOutline ? 1.5 : 0.8;

      final polylines = allPoints
          .map(
            (points) => Polyline(
              points: points,
              color: color,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
            ),
          )
          .toList();

      if (mounted) {
        setState(() {
          if (isOutline) {
            _boundaryPolylines = polylines;
          } else {
            _sidoPolylines = polylines;
          }
        });
        debugPrint('$assetPath 로드 완료: ${polylines.length}개 세그먼트');
      }
    } catch (e) {
      debugPrint('$assetPath 로드 오류: $e');
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );
    final rotationTween = Tween<double>(
      begin: _mapController.camera.rotation,
      end: 0.0,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    animation.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
      _mapController.rotate(rotationTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        return Stack(
          children: [
            // 베이스 맵 레이어
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.initialLocation,
                initialZoom: GameConstants.defaultZoom,
                minZoom: GameConstants.minZoom,
                maxZoom: GameConstants.maxZoom,
                // 남한 영토 기준 + 여유 공간(Margin)을 두어 러프하게 바운더리 제한 (GameConstants 외부 변수 참조)
                // contain 대신 containCenter를 사용하여 줌 아웃 시 화면이 바운더리보다 커져서 크래시나는 현상 방지
                cameraConstraint: CameraConstraint.containCenter(
                  bounds: LatLngBounds(
                    GameConstants.mapBoundSouthWest, // 남서 (마라도/백령도보다 더 넓게)
                    GameConstants.mapBoundNorthEast, // 북동 (고성/독도보다 더 넓게)
                  ),
                ),
                // 맵 회전(Rotation) 제스처 비활성화
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                backgroundColor: Colors.transparent,
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) setState(() => _isFollowing = false);
                  if (position.zoom != _currentZoom) {
                    setState(() => _currentZoom = position.zoom);
                  }
                  widget.game.updateProjection(_mapController);
                },
              ),
              children: [
                // 배경 지도 타일
                if (gameProvider.showMap &&
                    gameProvider.currentMapStyle.url.isNotEmpty)
                  TileLayer(
                    urlTemplate: gameProvider.currentMapStyle.url,
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.watercherry.conquestofkorea',
                  ),

                // 2023-07 최신 시도 내부 경계선
                if (gameProvider.showBoundaries &&
                    !_isLoadingBoundaries &&
                    _sidoPolylines.isNotEmpty)
                  PolylineLayer(polylines: _sidoPolylines),

                // 2023-07 최신 한반도 외곽 경계선
                if (gameProvider.showBoundaries &&
                    !_isLoadingBoundaries &&
                    _boundaryPolylines.isNotEmpty)
                  PolylineLayer(polylines: _boundaryPolylines),
              ],
            ),

            // Flame 게임 레이어 (터치 통과)
            Positioned.fill(
              child: IgnorePointer(child: GameWidget(game: widget.game)),
            ),

            // 로딩 인디케이터
            if (_isLoadingBoundaries)
              const Center(
                child: CircularProgressIndicator(
                  color: GameConstants.accentNeon,
                ),
              ),

            // 지도 컨트롤 UI
            Positioned(
              right: 16,
              bottom: 120,
              child: Column(
                children: [
                  _buildMapAction(
                    icon: _isFollowing
                        ? Icons.my_location
                        : Icons.location_searching,
                    onPressed: () {
                      setState(() => _isFollowing = true);
                      _animatedMapMove(
                        widget.initialLocation,
                        GameConstants.defaultZoom,
                      );
                    },
                    isActive: _isFollowing,
                  ),
                  const SizedBox(height: 8),
                  _buildMapAction(
                    icon: gameProvider.showBoundaries
                        ? Icons.layers
                        : Icons.layers_clear,
                    onPressed: () => gameProvider.toggleBoundaries(),
                    isActive: gameProvider.showBoundaries,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMapAction({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return FloatingActionButton.small(
      heroTag: null,
      onPressed: onPressed,
      backgroundColor: Colors.black.withValues(alpha: 0.7),
      foregroundColor: isActive ? GameConstants.accentNeon : Colors.white,
      shape: CircleBorder(
        side: BorderSide(
          color: isActive ? GameConstants.accentNeon : Colors.white24,
          width: 1,
        ),
      ),
      child: Icon(icon),
    );
  }
}

/// Isolate에서 실행될 GeoJSON 파서
List<List<LatLng>> _parseGeoJson(String jsonString) {
  final data = json.decode(jsonString);
  List<dynamic> geometries = [];
  List<List<LatLng>> result = [];

  if (data['type'] == 'FeatureCollection' && data['features'] != null) {
    for (var feature in data['features']) {
      if (feature['geometry'] != null) geometries.add(feature['geometry']);
    }
  } else if (data['type'] == 'GeometryCollection' &&
      data['geometries'] != null) {
    geometries.addAll(data['geometries']);
  } else {
    geometries.add(data);
  }

  for (var geometry in geometries) {
    String type = geometry['type'];
    var coordinates = geometry['coordinates'];

    if (type == 'Polygon') {
      for (var ring in coordinates) {
        List<LatLng> points = [];
        for (var coord in ring) {
          points.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
        }
        if (points.isNotEmpty) result.add(points);
      }
    } else if (type == 'MultiPolygon') {
      for (var polygon in coordinates) {
        for (var ring in polygon) {
          List<LatLng> points = [];
          for (var coord in ring) {
            points.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
          }
          if (points.isNotEmpty) result.add(points);
        }
      }
    }
  }
  return result;
}
