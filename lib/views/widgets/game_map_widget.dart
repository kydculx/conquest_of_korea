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
  bool _lastIsFollowing = true; // 추가: 이전 추적 상태 캐싱
  bool _isPinching = false; // 추가: 핀치 줌 진행 중 여부 플래그
  int _pointerCount = 0; // 추가: 화면에 터치 중인 활성 포인터(손가락) 개수
  double _currentZoom = MapConfig.focusZoom;
  LocationProvider? _locProvider; // 추가: LocationProvider 참조 보관
  GameProvider? _gameProvider; // 추가: GameProvider 참조 보관
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

    final newGameProvider = Provider.of<GameProvider>(context, listen: false);
    if (_gameProvider != newGameProvider) {
      _gameProvider?.removeListener(_onGameProviderChanged);
      _gameProvider = newGameProvider;
      _gameProvider?.addListener(_onGameProviderChanged);
    }
  }

  @override
  void dispose() {
    _locProvider?.removeListener(_onLocationProviderChanged);
    _gameProvider?.removeListener(_onGameProviderChanged);
    _stopAnimation();
    super.dispose();
  }

  void _onGameProviderChanged() {
    if (!mounted || _gameProvider == null) return;
    final gameProvider = _gameProvider!;

    // 전역 추적 상태 전이 감지 및 내 위치 애니메이션 복귀
    if (gameProvider.isFollowingUser && !_lastIsFollowing) {
      _lastIsFollowing = true;
      final loc = _locProvider;
      if (loc != null && loc.currentLocation != null) {
        final double targetRotation =
            gameProvider.isMapRotationMode ? -loc.heading : 0.0;
        _animatedMapMove(
          loc.currentLocation!,
          MapConfig.focusZoom,
          targetRotation,
        );
      }
    } else if (!gameProvider.isFollowingUser && _lastIsFollowing) {
      _lastIsFollowing = false;
    }

    // [최적화] 맵 회전 모드 또는 내 위치 추적 상태 변경 시, 지도의 회전 및 투영 상태를 즉각 동기화 반영
    _onLocationProviderChanged();
  }

  void _onLocationProviderChanged() {
    if (!mounted || _locProvider == null) return;

    final loc = _locProvider!;
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    bool hasMoved = false;

    // 1. 위치 이동은 내 위치 추적 활성화 상태이고 사용자가 지도를 조작 중(터치/핀치)이 아니며, 이동 애니메이션이 진행 중이지 않을 때만 수행
    final isAnimating =
        _animationController != null && _animationController!.isAnimating;
    if (loc.currentLocation != null &&
        gameProvider.isFollowingUser &&
        !_isPinching &&
        _pointerCount == 0 &&
        !isAnimating) {
      // 실제 카메라 센터 위치와 목적지의 변위 차이를 판별하여 유효 이동이 일어났을 때만 move 기동
      final double latDiff = (_mapController.camera.center.latitude - loc.currentLocation!.latitude).abs();
      final double lngDiff = (_mapController.camera.center.longitude - loc.currentLocation!.longitude).abs();
      if (latDiff > 0.00001 || lngDiff > 0.00001) {
        _mapController.move(loc.currentLocation!, _currentZoom);
        hasMoved = true;
      }
    }

    // 2. 회전은 위치 추적 여부와 관계없이 회전 모드 여부에 따라 항상 화면 중앙을 기준으로 동기화
    bool hasRotated = false;
    if (gameProvider.isMapRotationMode) {
      final double currentRot = _mapController.camera.rotation;
      final double targetRot = -loc.heading;
      // 미세 오차 임계치(0.1도) 이상 변위 발생 시에만 실제 rotate 처리 및 플래그 ON
      if ((currentRot - targetRot).abs() > 0.1) {
        _mapController.rotate(targetRot);
        hasRotated = true;
      }
    } else {
      if (_mapController.camera.rotation != 0.0) {
        _mapController.rotate(0.0);
        hasRotated = true;
      }
    }

    // 3. [초근본 최적화] 지도가 물리적으로 이동했거나 실제로 회전 변형이 일어났을 때만 고비용 프로젝션 업데이트 기동
    if (hasMoved || hasRotated) {
      widget.game.updateProjection(_mapController);
    }

    // 4. Flame 엔진에 실시간 플레이어 위치 및 헤딩 동기화
    if (loc.currentLocation != null) {
      widget.game.updatePlayerLocation(loc.currentLocation!);
    }

    // 헤딩은 위치 좌표 획득 여부와 무관하게 무조건 동기화하여 화살표 및 나침반 방향 전환 즉각 반응 보장
    widget.game.updatePlayerHeading(
      gameProvider.isMapRotationMode ? 0.0 : loc.heading,
    );
  }

  @override
  void didUpdateWidget(GameMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 위치가 갱신되었고 '내 위치 추적' 모드라면 지도를 이동시킴 (맵 회전 모드가 아닐 때만 딜레이 애니메이션 적용)
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    if (gameProvider.isFollowingUser && widget.initialLocation != oldWidget.initialLocation) {
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
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

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
                gameProvider.selectScanTile(tileId);
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
                  if (_pointerCount == 1 && !_isPinching && gameProvider.isFollowingUser) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        gameProvider.setFollowingUser(false);
                      }
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
                // [Desync 박멸] 부드러운 줌(관성 및 핀치 줌 포함) 시 1프레임 시차도 없도록 지리-화면 투영을 매 프레임 실시간 강제 정렬
                widget.game.updateProjection(_mapController);
              },
            ),
            children: [
              // 배경 지도 타일 (Selector로 감싸 스타일 변경 시에만 리빌드 격리)
              Selector<GameProvider, (bool, MapStyle)>(
                selector: (_, provider) => (provider.showMap, provider.currentMapStyle),
                builder: (context, state, child) {
                  final showMap = state.$1;
                  final style = state.$2;

                  if (!showMap || style.url.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final tileLayer = TileLayer(
                    urlTemplate: style.url,
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName:
                        'com.watercherry.conquestofkorea',
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
            ],
          ),
        ),

        // Flame 게임 레이어 (터치 통과)
        Positioned.fill(
          child: IgnorePointer(child: GameWidget(game: widget.game)),
        ),
      ],
    );
  }
}
