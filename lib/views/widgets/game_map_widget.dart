import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flame/game.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../game/conquest_game.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/map_config.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/hex_service.dart';
import '../../core/constants/strings.dart';

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

            // 위성 점령 말풍선 (탭한 타일 위에 동적 배치)
            if (gameProvider.isScanMode)
              Positioned.fill(
                child: IgnorePointer(
                  child: _SatelliteMapBubble(
                    gameProvider: gameProvider,
                    mapController: _mapController,
                  ),
                ),
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
        return AlertDialog(
          backgroundColor: GameColors.tacticalBlack.withValues(alpha: 0.95),
          shape: BeveledRectangleBorder(
            side: BorderSide(color: GameColors.error, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: GameColors.error, size: 24),
              const SizedBox(width: 8),
              Text(
                GameStrings.satelliteAbortTitle,
                style: TextStyle(
                  color: GameColors.error,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
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

/// 선택된 위성 조준 타일 위에 실시간으로 위치가 갱신되는 말풍선 위젯.
/// MapController를 통해 LatLng → 화면 좌표로 변환하므로 맵 스크롤/줌 시에도 타일을 정확히 추적합니다.
/// 앵커: 말풍선 하단 중앙 = 타일 중심 위치 (타일이 가려지지 않도록 본체는 타일 위에 표시됩니다).
class _SatelliteMapBubble extends StatefulWidget {
  final GameProvider gameProvider;
  final MapController mapController;

  const _SatelliteMapBubble({
    required this.gameProvider,
    required this.mapController,
  });

  @override
  State<_SatelliteMapBubble> createState() => _SatelliteMapBubbleState();
}

/// [_SatelliteMapBubble]의 주기적 화면 갱신을 담당하는 상태 클래스
class _SatelliteMapBubbleState extends State<_SatelliteMapBubble> {
  /// 1초 단위로 상태 정보(쿨타임/시간)를 동기화 갱신하기 위한 타이머
  Timer? _timer;
  /// 지도의 스크롤 및 줌 이벤트를 실시간 감지하여 말풍선 좌표를 즉각 갱신하기 위한 구독 스트림
  StreamSubscription? _mapEventSubscription;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // 지도 이벤트(드래그, 줌 등) 감지 시 말풍선 좌표 실시간 갱신 트리거
    _mapEventSubscription = widget.mapController.mapEventStream.listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapEventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.gameProvider;
    final tileLatLng = game.selectedScanTileLatLng;
    final selectedId = game.selectedScanTileId;

    if (tileLatLng == null || selectedId == null) return const SizedBox.shrink();

    // 화살표 비행 시간 동안 팝업 정보 말풍선 숨김 처리
    final auth = context.read<AuthProvider>();
    final bool isCapturing = game.isSatelliteCapturing;
    if (isCapturing) {
      double travelRatio = 0.8;
      final hqId = auth.profile?.mainBaseTileId;
      final targetId = game.satelliteCapturingTileId;
      if (hqId != null && targetId != null) {
        try {
          final partsBase = hqId.split('_');
          final bq = int.tryParse(partsBase[1]) ?? 0;
          final br = int.tryParse(partsBase[2]) ?? 0;
          final partsTarget = targetId.split('_');
          final tq = int.tryParse(partsTarget[1]) ?? 0;
          final tr = int.tryParse(partsTarget[2]) ?? 0;
          final dist = HexService.hexDistance(bq, br, tq, tr);
          final travelSeconds = dist.toDouble();
          const captureSeconds = 1.0;
          final total = travelSeconds + captureSeconds;
          if (total > 0.0) {
            travelRatio = travelSeconds / total;
          }
        } catch (_) {}
      }
      final bool isTraveling = game.satelliteCaptureProgress < travelRatio;
      if (isTraveling) {
        return const SizedBox.shrink(); // 화살표가 이동 중인 동안에는 팝업을 표시하지 않고 숨깁니다.
      }
    }

    // 1. 선택된 타일 ID에서 q, r 파싱
    int? q;
    int? r;
    final parts = selectedId.split('_');
    if (parts.length >= 3) {
      q = int.tryParse(parts[1]);
      r = int.tryParse(parts[2]);
    }

    // 2. 헥사곤 최상단(북쪽) 꼭짓점의 LatLng 좌표 계산
    LatLng? topCornerLatLng;
    if (q != null && r != null) {
      final corners = HexService.getHexCorners(q, r);
      if (corners.isNotEmpty) {
        // 위도(latitude)가 가장 큰 꼭짓점(가장 북쪽 = 최상단)을 선택
        topCornerLatLng = corners.reduce(
          (curr, next) => curr.latitude > next.latitude ? curr : next,
        );
      }
    }

    // LatLng → 현재 카메라 기준 화면 좌표 실시간 변환
    final Offset arrowTipPos;
    try {
      if (topCornerLatLng != null) {
        arrowTipPos = widget.mapController.camera.latLngToScreenOffset(topCornerLatLng);
      } else {
        arrowTipPos = widget.mapController.camera.latLngToScreenOffset(tileLatLng);
      }
    } catch (_) {
      return const SizedBox.shrink();
    }

    // --- 상태 계산 ---
    Color themeColor = GameColors.accentNeon;
    bool isError = false;
    bool isCooltime = false;
    String detailsText = GameStrings.satScanActive;
    String? distanceStr;
    String? timeStr;

    if (isCapturing) {
      final remainingSec = game.remainingSatelliteCaptureSeconds;
      detailsText = GameStrings.satCapturingAttempt;
      timeStr = '$remainingSec초';
    } else {
      final existingTile = game.capturedTiles[selectedId];
      final isTileEmpty = existingTile == null ||
          existingTile.userId == null ||
          existingTile.userId == 'none';

      if (isTileEmpty) {
        final satCooltime = game.remainingSatelliteCaptureCoolSeconds;
        final isConnected = game.checkSatelliteCaptureConnectivity(selectedId);

        if (satCooltime > 0) {
          final minutes = satCooltime ~/ 60;
          final seconds = satCooltime % 60;
          themeColor = const Color(0xFFFF9900);
          isCooltime = true;
          detailsText = GameStrings.satCooltimeWaitingLabel;
          timeStr =
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        } else if (!isConnected) {
          themeColor = GameColors.error;
          isError = true;
          detailsText = GameStrings.satDisconnectedLabel;
        } else {
          final durationSec = game.getSatelliteCaptureDurationSeconds(selectedId);
          detailsText = GameStrings.satLockOnReady;
          final mainBaseId = auth.profile?.mainBaseTileId;
          int distance = 0;
          if (mainBaseId != null && mainBaseId.isNotEmpty) {
            final partsBase = mainBaseId.split('_');
            final bq = int.tryParse(partsBase[1]) ?? 0;
            final br = int.tryParse(partsBase[2]) ?? 0;
            final partsTarget = selectedId.split('_');
            final tq = int.tryParse(partsTarget[1]) ?? 0;
            final tr = int.tryParse(partsTarget[2]) ?? 0;
            distance = HexService.hexDistance(bq, br, tq, tr);
            distanceStr = '$distance GP';
          }

          // 위성 점령 소모 재화(골드) 부족 여부 검증
          final double currentGold = game.currentGold;
          if (currentGold < distance) {
            themeColor = GameColors.error;
            isError = true;
            detailsText = '재화가 부족합니다';
          }

          timeStr = '$durationSec초';
        }
      } else {
        themeColor = GameColors.error;
        isError = true;
        detailsText = GameStrings.satAlreadyCapturedLabel;
      }
    }

    // --- 레이아웃 상수 ---
    const double bubbleW = 210.0;
    const double estimatedBodyH = 75.0; // 말풍선 본체 추정 높이 (패딩 포함)
    const double margin = 12.0;
    const double gap = 12.0; // 타일 상단 꼭짓점과 정보창 사이의 유격

    // 정보창 하단이 타일의 최상단 꼭짓점보다 gap(12px)만큼 위에 위치하도록:
    //   정보창 하단 y = arrowTipPos.dy - gap
    //   본체 상단(top) = 정보창 하단 y - estimatedBodyH
    return LayoutBuilder(
      builder: (context, constraints) {
        double left = arrowTipPos.dx - bubbleW / 2;
        left = left.clamp(margin, constraints.maxWidth - bubbleW - margin);

        final double arrowTipY = arrowTipPos.dy;
        double top = arrowTipY - estimatedBodyH - gap;

        // 화면 상단 여백 보장
        if (top < margin) top = margin;

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: bubbleW,
              child: _BubbleColumn(
                themeColor: themeColor,
                isError: isError,
                isCooltime: isCooltime,
                detailsText: detailsText,
                distanceStr: distanceStr,
                timeStr: timeStr,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 정보창 본체 위젯의 래퍼 Column 클래스 (구조 일관성 유지)
class _BubbleColumn extends StatelessWidget {
  final Color themeColor;
  final bool isError;
  final bool isCooltime;
  final String detailsText;
  final String? distanceStr;
  final String? timeStr;

  const _BubbleColumn({
    required this.themeColor,
    required this.isError,
    required this.isCooltime,
    required this.detailsText,
    this.distanceStr,
    this.timeStr,
  });

  @override
  Widget build(BuildContext context) {
    // 하단 삼각형 꼬리를 제거하고 본체만 렌더링합니다.
    return _BubbleBody(
      themeColor: themeColor,
      isError: isError,
      isCooltime: isCooltime,
      detailsText: detailsText,
      distanceStr: distanceStr,
      timeStr: timeStr,
    );
  }
}

/// 말풍선 본체 위젯 (BeveledRect 테두리 + BackdropBlur 배경)
class _BubbleBody extends StatelessWidget {
  final Color themeColor;
  final bool isError;
  final bool isCooltime;
  final String detailsText;
  final String? distanceStr;
  final String? timeStr;

  const _BubbleBody({
    required this.themeColor,
    required this.isError,
    required this.isCooltime,
    required this.detailsText,
    this.distanceStr,
    this.timeStr,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: ShapeBorderClipper(
        shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: ShapeDecoration(
            color: GameColors.backgroundMedium.withValues(alpha: 0.9),
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: themeColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태 텍스트
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(right: 6, top: 1),
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      detailsText,
                      style: TextStyle(
                        color:
                            isError ? GameColors.error : GameColors.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              // 메트릭 배지 (거리 / 시간)
              if (distanceStr != null || timeStr != null) ...[
                const SizedBox(height: 7),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (distanceStr != null) ...[
                      _buildBadge('재화', distanceStr!, themeColor),
                      const SizedBox(width: 8),
                    ],
                    if (timeStr != null)
                      _buildBadge(
                        isCooltime ? '대기' : '시간',
                        timeStr!,
                        themeColor,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: GameColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              fontFamily: 'Courier',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }
}
