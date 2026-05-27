import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flame/game.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../game/conquest_game.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/map_config.dart';
import '../../providers/game_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/hex_service.dart';
import '../../core/constants/strings.dart';
import 'tactical_dialog.dart';

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
  double _currentZoom = MapConfig.focusZoom;
  LocationProvider? _locProvider; // 추가: LocationProvider 참조 보관
  AnimationController? _animationController; // 추가: 내 위치 애니메이션 컨트롤러

  @override
  void initState() {
    super.initState();
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
    _stopAnimation();
    super.dispose();
  }

  void _onLocationProviderChanged() {
    if (!mounted || _locProvider == null) return;

    final loc = _locProvider!;
    if (loc.currentLocation == null) return;

    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    // 1. 위치 이동은 내 위치 추적 활성화 상태이고 사용자가 지도를 조작 중(터치/핀치)이 아니며, 이동 애니메이션이 진행 중이지 않을 때만 수행
    final isAnimating = _animationController != null && _animationController!.isAnimating;
    if (_isFollowing && !_isPinching && _pointerCount == 0 && !isAnimating) {
      _mapController.move(loc.currentLocation!, _currentZoom);
    }

    // 2. 회전은 위치 추적 여부와 관계없이 회전 모드 여부에 따라 항상 화면 중앙을 기준으로 동기화
    if (gameProvider.isMapRotationMode) {
      _mapController.rotate(-loc.heading);
    } else {
      if (_mapController.camera.rotation != 0.0) {
        _mapController.rotate(0.0);
      }
    }

    // Flame 엔진 프로젝션 업데이트 트리거
    widget.game.updateProjection(_mapController);

    // 3. Flame 엔진에 실시간 플레이어 위치 및 헤딩 동기화
    widget.game.updatePlayerLocation(loc.currentLocation!);
    widget.game.updatePlayerHeading(
      gameProvider.isMapRotationMode ? 0.0 : loc.heading,
    );
  }

  @override
  void didUpdateWidget(GameMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 위치가 갱신되었고 '내 위치 추적' 모드라면 지도를 이동시킴 (맵 회전 모드가 아닐 때만 딜레이 애니메이션 적용)
    if (_isFollowing && widget.initialLocation != oldWidget.initialLocation) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      if (!gameProvider.isMapRotationMode) {
        _animatedMapMove(widget.initialLocation, MapConfig.focusZoom, 0.0);
      }
    }
  }

  void _stopAnimation() {
    if (_animationController != null) {
      _animationController!.stop();
      _animationController!.dispose();
      _animationController = null;
    }
  }

  void _animatedMapMove(
    LatLng destLocation,
    double destZoom,
    double destRotation,
  ) {
    _stopAnimation();

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
    _animationController = controller;

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
      // Flame 엔진 프로젝션 실시간 업데이트 복구
      widget.game.updateProjection(_mapController);
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (_animationController == controller) {
          _animationController = null;
        }
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
                _stopAnimation();
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
                  initialZoom: MapConfig.focusZoom,
                  minZoom: MapConfig.minZoom,
                  maxZoom: MapConfig.maxZoom,
                  // 남한 영토 기준 + 여유 공간(Margin)을 두어 러프하게 바운더리 제한 (MapConfig 외부 변수 참조)
                  // contain 대신 containCenter를 사용하여 줌 아웃 시 화면이 바운더리보다 커져서 크래시나는 현상 방지
                  cameraConstraint: const CameraConstraint.unconstrained(),
                  // 맵 회전(Rotation) 제스처 비활성화
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  backgroundColor: GameColors.transparent,
                  onMapReady: () {
                    widget.game.updateProjection(_mapController);
                  },
                  onTap: (tapPosition, point) {
                    final hex = HexService.latLngToHex(point);
                    final tileId = 'hex_${hex['q']}_${hex['r']}';

                    if (gameProvider.isSatelliteCapturing &&
                        gameProvider.satelliteCapturingTileId == tileId) {
                      _showSatelliteCancelDialog(context, gameProvider);
                    } else if (gameProvider.isScanMode) {
                      gameProvider.selectScanTile(tileId);
                    }
                  },
                  onMapEvent: (event) {
                    if (event.source ==
                        MapEventSource.multiFingerGestureStart) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _isPinching = true);
                      });
                    } else if (event.source == MapEventSource.multiFingerEnd) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => _isPinching = false);
                          _onLocationProviderChanged();
                        }
                      });
                    }

                    if (event.source == MapEventSource.dragStart ||
                        event.source == MapEventSource.onDrag ||
                        event.source ==
                            MapEventSource.flingAnimationController) {
                      // 활성 포인터가 정확히 1개이고 핀치 줌 중이 아닐 때만 트래킹을 해제
                      if (_pointerCount == 1 && !_isPinching && _isFollowing) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _isFollowing = false);
                        });
                      }
                      _stopAnimation();
                    }
                    widget.game.updateProjection(_mapController);
                  },
                  onPositionChanged: (position, hasGesture) {
                    if (position.zoom != _currentZoom) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => _currentZoom = position.zoom);
                        }
                      });
                    }
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
                          userAgentPackageName:
                              'com.watercherry.conquestofkorea',
                        );

                        // 위성 스캔 모드일 때는 군용 위성 카메라 감성의 흑백(Grayscale) 모노 틴트 강제 주입
                        if (gameProvider.isScanMode) {
                          return ColorFiltered(
                            colorFilter: const ColorFilter.matrix(<double>[
                              0.2126 * 0.9, 0.7152 * 0.9, 0.0722 * 0.9, 0, 15,
                              0.2126 * 0.8, 0.7152 * 0.8, 0.0722 * 0.8, 0, 10,
                              0.2126 * 0.7, 0.7152 * 0.7, 0.0722 * 0.7, 0, 5,
                              0,            0,            0,            1, 0,
                            ]),
                            child: tileLayer,
                          );
                        }

                        if (style.colorMatrix != null) {
                          return ColorFiltered(
                            colorFilter: ColorFilter.matrix(style.colorMatrix!),
                            child: tileLayer,
                          );
                        }
                        return tileLayer;
                      },
                    ),
                ],
              ),
            ),

            // Flame 게임 레이어 (터치 통과)
            Positioned.fill(
              child: IgnorePointer(child: GameWidget(game: widget.game)),
            ),



            // 지도 컨트롤 UI
            Positioned(
              right: 16,
              bottom: 120,
              child: Column(
                children: [
                  _buildMapAction(
                    icon: Icons.satellite_alt_rounded,
                    onPressed: () {
                      gameProvider.toggleScanMode();
                    },
                    isActive: gameProvider.isScanMode,
                  ),
                  const SizedBox(height: 8),
                  _buildMapAction(
                    icon: !_isFollowing
                        ? Icons.location_searching
                        : (gameProvider.isMapRotationMode
                              ? Icons.explore
                              : Icons.my_location),
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
                              gameProvider.isMapRotationMode
                              ? -loc.heading
                              : 0.0;
                          _animatedMapMove(
                            loc.currentLocation!,
                            MapConfig.focusZoom,
                            targetRotation,
                          );
                        } else {
                          _animatedMapMove(
                            widget.initialLocation,
                            MapConfig.focusZoom,
                            0.0,
                          );
                        }
                      }
                    },
                    isActive: _isFollowing,
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

  void _showSatelliteCancelDialog(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return TacticalDialog(
          title: GameStrings.satelliteAbortTitle,
          icon: Icons.warning_amber_rounded,
          accentColor: GameColors.error,
          content: Text(
            GameStrings.satelliteAbortConfirm,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white30, width: 1.0),
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(GameStrings.satelliteKeepOperation),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: GameColors.error,
                side: BorderSide(color: GameColors.error, width: 1.0),
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: () {
                provider.cancelSatelliteCapture();
                Navigator.pop(context);
              },
              child: Text(GameStrings.satelliteCancelOperation),
            ),
          ],
        );
      },
    );
  }
}


