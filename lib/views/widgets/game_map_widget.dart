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
import '../../providers/location_provider.dart'; // 추가: LocationProvider 임포트

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
  bool _isPinching = false; // 추가: 핀치 줌 진행 중 여부 플래그
  int _pointerCount = 0; // 추가: 화면에 터치 중인 활성 포인터(손가락) 개수
  double _currentZoom = GameConstants.focusZoom;
  LocationProvider? _locProvider; // 추가: LocationProvider 참조 보관

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLoc = Provider.of<LocationProvider>(context, listen: false);
    if (_locProvider != newLoc) {
      _locProvider?.removeListener(_onLocationProviderChanged);
      _locProvider = newLoc;
      _locProvider?.addListener(_onLocationProviderChanged);
    }
  }

  @override
  void dispose() {
    _locProvider?.removeListener(_onLocationProviderChanged);
    super.dispose();
  }

  void _onLocationProviderChanged() {
    if (!mounted || _locProvider == null) return;

    final loc = _locProvider!;
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    if (_isFollowing && loc.currentLocation != null) {
      if (gameProvider.isMapRotationMode) {
        if (!_isPinching) {
          _mapController.move(loc.currentLocation!, _currentZoom);
        }
        _mapController.rotate(-loc.heading);
      } else {
        if (!_isPinching) {
          _mapController.move(loc.currentLocation!, _currentZoom);
        }
        if (_mapController.camera.rotation != 0.0) {
          _mapController.rotate(0.0);
        }
      }
      // Flame 엔진 프로젝션 업데이트 트리거
      widget.game.updateProjection(_mapController);
    }
  }

  @override
  void didUpdateWidget(GameMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 위치가 갱신되었고 '내 위치 추적' 모드라면 지도를 이동시킴 (맵 회전 모드가 아닐 때만 딜레이 애니메이션 적용)
    if (_isFollowing && widget.initialLocation != oldWidget.initialLocation) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      if (!gameProvider.isMapRotationMode) {
        _animatedMapMove(widget.initialLocation, GameConstants.focusZoom, 0.0);
      }
    }
  }

  Future<void> _loadAllBoundaries() async {
    // 부하 분산을 위해 순차적으로 로드
    await _loadBoundary(GameConstants.boundaryOutlineAsset, isOutline: true);
    await _loadBoundary(GameConstants.boundarySidoAsset, isOutline: false);

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
          ? GameColors.accentNeon.withValues(alpha: 0.8)
          : GameColors.tacticalWhite.withValues(alpha: 0.4);
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

  void _animatedMapMove(LatLng destLocation, double destZoom, double destRotation) {
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
      end: destRotation,
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
      if (!mounted) return;
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
      _mapController.rotate(rotationTween.evaluate(animation));
      // Flame 엔진 프로젝션 실시간 업데이트
      widget.game.updateProjection(_mapController);
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
            Listener(
              onPointerDown: (event) {
                _pointerCount++;
              },
              onPointerUp: (event) {
                _pointerCount = (_pointerCount - 1).clamp(0, 10);
              },
              onPointerCancel: (event) {
                _pointerCount = (_pointerCount - 1).clamp(0, 10);
              },
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: widget.initialLocation,
                  initialZoom: GameConstants.focusZoom,
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
                  backgroundColor: GameColors.transparent,
                  onMapEvent: (event) {
                    if (event.source == MapEventSource.multiFingerGestureStart) {
                      setState(() => _isPinching = true);
                    } else if (event.source == MapEventSource.multiFingerEnd) {
                      setState(() => _isPinching = false);
                      _onLocationProviderChanged();
                    }

                    if (event.source == MapEventSource.dragStart ||
                        event.source == MapEventSource.onDrag ||
                        event.source == MapEventSource.flingAnimationController) {
                      // 활성 포인터가 정확히 1개인 경우(순수 드래그)에만 트래킹을 즉시 해제
                      if (_pointerCount == 1 && _isFollowing) {
                        setState(() => _isFollowing = false);
                      }
                    }
                  },
                  onPositionChanged: (position, hasGesture) {
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
                  Builder(
                    builder: (context) {
                      final style = gameProvider.currentMapStyle;
                      final tileLayer = TileLayer(
                        urlTemplate: style.url,
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.watercherry.conquestofkorea',
                      );

                      if (style.colorMatrix != null) {
                        return ColorFiltered(
                          colorFilter: ColorFilter.matrix(style.colorMatrix!),
                          child: tileLayer,
                        );
                      }
                      return tileLayer;
                    },
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
          ),

            // Flame 게임 레이어 (터치 통과)
            Positioned.fill(
              child: IgnorePointer(child: GameWidget(game: widget.game)),
            ),

            // 로딩 인디케이터
            if (_isLoadingBoundaries)
              Center(
                child: CircularProgressIndicator(color: GameColors.accentNeon),
              ),

            // 지도 컨트롤 UI
            Positioned(
              right: 16,
              bottom: 120,
              child: Column(
                children: [
                  _buildMapAction(
                    icon: !_isFollowing
                        ? Icons.location_searching
                        : (gameProvider.isMapRotationMode ? Icons.explore : Icons.my_location),
                    onPressed: () {
                      final loc = _locProvider;
                      if (_isFollowing) {
                        gameProvider.toggleMapRotationMode();
                        if (loc != null && loc.currentLocation != null) {
                          if (gameProvider.isMapRotationMode) {
                            _mapController.rotate(-loc.heading);
                          } else {
                            _mapController.rotate(0.0);
                          }
                          widget.game.updateProjection(_mapController);
                        }
                      } else {
                        setState(() => _isFollowing = true);
                        if (loc != null && loc.currentLocation != null) {
                          final double targetRotation =
                              gameProvider.isMapRotationMode ? -loc.heading : 0.0;
                          _animatedMapMove(
                            loc.currentLocation!,
                            GameConstants.focusZoom,
                            targetRotation,
                          );
                        } else {
                          _animatedMapMove(
                            widget.initialLocation,
                            GameConstants.focusZoom,
                            0.0,
                          );
                        }
                      }
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
                  const SizedBox(height: 8),
                  _buildMapAction(
                    icon: _getMapStyleIcon(gameProvider.currentMapStyle.icon),
                    onPressed: () => gameProvider.cycleMapStyle(),
                    isActive: !gameProvider.showMap,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getMapStyleIcon(String iconName) {
    const iconMap = <String, IconData>{
      'dark_mode': Icons.dark_mode,
      'satellite_alt': Icons.satellite_alt,
      'terrain': Icons.terrain,
      'add_road': Icons.add_road,
      'explore': Icons.explore,
      'brightness_5': Icons.brightness_5,
      'map': Icons.map,
      'public': Icons.public,
      'straighten': Icons.straighten,
      'filter_hdr': Icons.filter_hdr,
      'landscape': Icons.landscape,
      'directions_bike': Icons.directions_bike,
      'layers_clear': Icons.layers_clear,
    };
    return iconMap[iconName] ?? Icons.map;
  }

  Widget _buildMapAction({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return SizedBox(
      width: 40,
      height: 40,
      child: FloatingActionButton.small(
        heroTag: null,
        onPressed: onPressed,
        backgroundColor: GameColors.backgroundMedium.withValues(alpha: 0.85),
        foregroundColor: isActive
            ? GameColors.accentNeon
            : GameColors.tacticalWhite,
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isActive ? GameColors.accentNeon : GameColors.dividerColor,
            width: 1.2,
          ),
        ),
        child: Icon(icon, size: 18),
      ),
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
