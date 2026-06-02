import 'dart:ui';
import 'package:flame/game.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'components/player_component.dart';
import 'components/hex_tile_component.dart';
import 'components/hq_base_marker.dart';
import 'components/scan_target_marker.dart';
import '../services/hex_service.dart';
import '../models/tile_model.dart';
import '../providers/game_provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/game_config.dart';

/// Flame 게임 엔진을 상속받아 인게임 전술 지도상에 헥사곤 타일 영역, 요원의 물리 위치 마커, 본부 기지(HQ), 위성 조준 마커 등을 렌더링하고 업데이트를 감시하는 커스텀 게임 엔진 클래스
/// 줌 레벨별 동적 LOD(Level of Detail) 타일 규격 계층화 및 실시간 영토 병합(Clustering) 시스템을 이식받아 60 FPS 드래그 및 전국구 줌아웃 성능을 완벽 보장합니다.
class ConquestGame extends FlameGame {
  /// 요원 본인을 지도 상에 나타내는 2D 방향 컴포넌트
  late PlayerComponent player;

  /// 화면 좌표와 지도 좌표 간 변환(투영)을 수행하는 FlutterMap 지도 컨트롤러 캐시 객체
  MapController? _mapController;

  /// 마지막으로 전달받은 서버 기준 점령 타일 목록 캐시
  Map<String, HexTile> _lastCapturedTiles = {};

  /// 최근에 빌드 완료된 LOD 병합 영토 타일 맵 캐시
  Map<String, HexTile> _lastClusteredTiles = {};

  /// 최근 렌더링에 사용 중인 LOD 레벨 상태 캐시 (-1: 초기값, 0 ~ 3: LOD 레벨)
  int _lastLodLevel = -1;

  /// 최근에 렌더링을 감지했던 카메라 지리적 중심좌표 캐시 (순간이동 Culling 가드용)
  LatLng? _lastCameraCenter;

  /// 렌더링에 사용 중인 Flame 개별 컴포넌트 맵 (Key: 타일 ID, Value: 헥사곤 컴포넌트)
  final Map<String, HexTileComponent> _tileMap = {};

  /// 타일 ID 기준 중심점 LatLng 지리적 불변 캐싱 맵 (중복 삼각함수 연산 차단)
  final Map<String, LatLng> _tileCenterCache = {};

  /// 타일 ID 기준 6개 꼭짓점 LatLng 지리적 불변 캐싱 맵 (중복 꼭짓점 산출 차단)
  final Map<String, List<LatLng>> _tileCornersCache = {};

  /// 본부 기지(HQ) 아이콘 및 링 반경 연출을 시각화하는 마커 컴포넌트
  HQBaseMarker? _hqMarker;

  /// 위성 궤도 스캔 시 락온(Lock-on) 연출 및 게이지를 그리는 조준마커 컴포넌트
  ScanTargetMarker? _scanTargetMarker;

  /// 현재 설정된 요원의 본부 기지(HQ) 타일 ID
  String? _currentHQTileId;

  /// 최근에 점령 시도에 사용된 전술 식별 색상 코드
  String? _lastCapturingColorHex;

  /// 현재 위성 궤도 스캔 조준 장치 활성화 여부 상태 캐시
  bool _isScanMode = false;

  /// 현재 로그인된 요원의 ID 정보 캐시
  String? _currentUserId;

  /// 현재 위성 원격 타일 점령이 진행 중인지 여부 상태 캐시
  bool _isSatelliteCapturing = false;

  /// 현재 위성 점령의 상태 단계
  SatelliteCapturePhase _satelliteCapturePhase = SatelliteCapturePhase.none;

  /// 현재 위성 빔 비행 진행률 (0.0 ~ 1.0)
  double _satelliteTravelProgress = 0.0;

  /// 현재 위성 점령의 게이지 진행률 (0.0 ~ 1.0)
  double _satelliteCaptureProgress = 0.0;

  /// 위성 점령을 개시한 대상 타일 ID 캐시
  String? _satelliteCapturingTileId;

  /// 투영을 담당하는 내부 맵 컨트롤러 반환
  MapController? get mapController => _mapController;

  /// 본부 기지가 설치된 타일 ID 반환
  String? get currentHQTileId => _currentHQTileId;

  /// 현재 사용자 ID 반환
  String? get currentUserId => _currentUserId;

  /// 최근 서버 데이터 기준 캐싱된 전체 점령지 맵 반환
  Map<String, HexTile> get lastCapturedTiles => _lastCapturedTiles;

  /// 현재 위성 점령이 활성화되어 시도 중인지 여부
  bool get isSatelliteCapturing => _isSatelliteCapturing;

  /// 현재 위성 점령의 상태 단계 반환
  SatelliteCapturePhase get satelliteCapturePhase => _satelliteCapturePhase;

  /// 위성 빔 비행 진행률 반환
  double get satelliteTravelProgress => _satelliteTravelProgress;

  /// 위성 점령의 퍼센트 수치 반환
  double get satelliteCaptureProgress => _satelliteCaptureProgress;

  /// 위성 점령 중인 목적지 타일 ID 반환
  String? get satelliteCapturingTileId => _satelliteCapturingTileId;

  /// 위성 궤도 조준경 모드 사용 여부
  bool get isScanMode => _isScanMode;

  /// 최근에 점령 시도에 사용된 전술 식별 색상 코드
  String? get lastCapturingColorHex => _lastCapturingColorHex;

  @override
  Color backgroundColor() => GameColors.transparent;

  @override
  Future<void> onLoad() async {
    player = PlayerComponent()..priority = 20;
    player.isVisible = true;
    add(player);

    if (_mapController != null) _updateAllPositions();
  }

  /// 프레임 갱신 주기를 제어하기 위해 누적 보관하는 델타 타임 합산 값
  double _dtSum = 0.0;

  /// 프레임 오차를 방지하고 연산을 규격화하기 위해 60 FPS 주기로 강제하는 고정 타임 기준값 (1/60초)
  static const double _fixedDeltaTime = 1 / 60; // 60 FPS 강제 제한

  /// Flame 엔진의 생명주기 갱신 콜백으로, 고정 델타 타임을 기반으로 하여 컴포넌트 트리를 규칙적으로 갱신합니다.
  @override
  void updateTree(double dt) {
    _dtSum += dt;
    if (_dtSum >= _fixedDeltaTime) {
      super.updateTree(_fixedDeltaTime);
      _dtSum -= _fixedDeltaTime;
    }
  }

  /// 지도 투영 업데이트 → 컴포넌트 위치 재계산
  void updateProjection(MapController controller) {
    _mapController = controller;
    if (_tileMap.isEmpty && _lastCapturedTiles.isNotEmpty) {
      updateCapturedTiles(
        capturedTiles: _lastCapturedTiles,
        mainBaseTileId: _currentHQTileId,
        selectedScanTileId: _scanTargetMarker != null
            ? 'hex_${_scanTargetMarker!.q}_${_scanTargetMarker!.r}'
            : null,
        isScanMode: _scanTargetMarker != null,
        capturingColorHex: _lastCapturingColorHex,
        currentUserId: _currentUserId,
        isSatelliteCapturing: _isSatelliteCapturing,
        satelliteCapturePhase: _satelliteCapturePhase,
        satelliteTravelProgress: _satelliteTravelProgress,
        satelliteCaptureProgress: _satelliteCaptureProgress,
      );
    } else {
      _updateAllPositions();
    }
  }

  /// 현재 줌 레벨에 맞는 헥사곤 미터 규격(Size) 반환
  double _getHexSizeForZoom(double zoom) {
    if (zoom >= GameConfig.lodZoomThreshold0) return GameConfig.lodSize0;
    if (zoom >= GameConfig.lodZoomThreshold1) return GameConfig.lodSize1;
    if (zoom >= GameConfig.lodZoomThreshold2) return GameConfig.lodSize2;
    if (zoom >= GameConfig.lodZoomThreshold3) return GameConfig.lodSize3;
    return GameConfig.lodSize4;
  }

  /// 현재 줌 레벨에 맞는 LOD 레벨(0 ~ 4) 반환
  int _getLodLevelForZoom(double zoom) {
    if (zoom >= GameConfig.lodZoomThreshold0) return 0;
    if (zoom >= GameConfig.lodZoomThreshold1) return 1;
    if (zoom >= GameConfig.lodZoomThreshold2) return 2;
    if (zoom >= GameConfig.lodZoomThreshold3) return 3;
    return 4;
  }

  /// 줌 레벨 스케일(LOD)에 맞춘 고유 타일 ID 생성
  String _getTileId(int q, int r, double hexSize) {
    if (hexSize == GameConfig.lodSize0) {
      return 'hex_${q}_$r';
    }
    return 'hex_${hexSize.toInt()}_${q}_$r';
  }

  /// 소형 100m 기준의 타일 데이터를 현재 LOD dynamicSize 규격에 맞게 실시간 뭉뚱그려(Clustering) 병합
  void _rebuildClusteredTiles(
    Map<String, HexTile> capturedTiles,
    double dynamicSize,
  ) {
    if (dynamicSize == GameConfig.lodSize0) {
      _lastClusteredTiles = Map.from(capturedTiles);
      return;
    }

    final Map<String, HexTile> clustered = {};
    capturedTiles.forEach((id, tile) {
      // 100m 소형 기준의 지리 중심 획득
      final smallCenter = _getTileCenter(
        tile.q,
        tile.r,
        id,
        GameConfig.lodSize0,
      );

      // dynamicHexSize 기준의 q, r 헥사 좌표 역산
      final dynamicHex = HexService.latLngToHex(
        smallCenter,
        hexSize: dynamicSize,
      );
      final dq = dynamicHex['q']!;
      final dr = dynamicHex['r']!;
      final String clusterId = _getTileId(dq, dr, dynamicSize);

      final existing = clustered[clusterId];
      if (existing == null) {
        clustered[clusterId] = HexTile(
          id: clusterId,
          q: dq,
          r: dr,
          userId: tile.userId,
          capturedAt: tile.capturedAt,
        );
      } else {
        // 대표 영토 지배권: 내 영토가 하나라도 뭉쳐있다면 내 진영색으로 마킹
        if (tile.userId == _currentUserId) {
          clustered[clusterId] = HexTile(
            id: clusterId,
            q: dq,
            r: dr,
            userId: _currentUserId!,
            capturedAt: tile.capturedAt,
          );
        }
      }
    });

    _lastClusteredTiles = clustered;
  }

  /// 타일 ID에 상응하는 지리적 중심점 캐시 반환
  LatLng _getTileCenter(int q, int r, String id, double hexSize) {
    return _tileCenterCache.putIfAbsent(
      id,
      () => HexService.hexToLatLng(q, r, hexSize: hexSize),
    );
  }

  /// 타일 ID에 상응하는 지리적 6개 꼭짓점 캐시 반환
  List<LatLng> _getTileCorners(int q, int r, String id, double hexSize) {
    return _tileCornersCache.putIfAbsent(
      id,
      () => HexService.getHexCorners(q, r, hexSize: hexSize),
    );
  }

  /// 점령 타일 렌더링 업데이트 (LOD 병합 및 캐싱 최적화 버전)
  void updateCapturedTiles({
    required Map<String, HexTile> capturedTiles,
    String? capturingTileId,
    double captureProgress = 0.0,
    String? capturingColorHex,
    LatLng? currentLocation,
    String? mainBaseTileId,
    String? selectedScanTileId,
    bool isScanMode = false,
    String? currentUserId,
    bool isSatelliteCapturing = false,
    SatelliteCapturePhase satelliteCapturePhase = SatelliteCapturePhase.none,
    double satelliteTravelProgress = 0.0,
    double satelliteCaptureProgress = 0.0,
    String? satelliteCapturingTileId,
  }) {
    _lastCapturedTiles = capturedTiles;
    _lastCapturingColorHex = capturingColorHex;
    _isScanMode = isScanMode;
    _currentUserId = currentUserId;
    _isSatelliteCapturing = isSatelliteCapturing;
    _satelliteCapturePhase = satelliteCapturePhase;
    _satelliteTravelProgress = satelliteTravelProgress;
    _satelliteCaptureProgress = satelliteCaptureProgress;
    _satelliteCapturingTileId = satelliteCapturingTileId;
    if (isLoaded) {
      player.isVisible = true;
    }
    _updateHQMarker(mainBaseTileId, capturingColorHex);
    _updateScanTargetMarker(selectedScanTileId, isScanMode);
    if (_mapController == null) return;

    // [순간이동 가드] 카메라 중심점이 급변(1km 이상)했을 경우, 잔상 방지를 위해 기존 헥사 컴포넌트 즉시 강제 전체 소거
    final LatLng currentCenter = _mapController!.camera.center;
    if (_lastCameraCenter != null) {
      final double dist = HexService.calculateDistance(
        _lastCameraCenter!,
        currentCenter,
      );
      if (dist > 1000.0) {
        _tileMap.clear();
        final toRemove = children.whereType<HexTileComponent>().toList();
        removeAll(toRemove);
      }
    }
    _lastCameraCenter = currentCenter;

    // 현재 LOD 레벨 및 규격 파악
    final double currentZoom = _mapController!.camera.zoom;
    final int currentLod = _getLodLevelForZoom(currentZoom);
    final double dynamicHexSize = _getHexSizeForZoom(currentZoom);

    // LOD 세대교체가 발생했거나 데이터 리프레시 필요 시 클러스터링 가동
    if (_lastLodLevel != currentLod || _lastClusteredTiles.isEmpty) {
      _rebuildClusteredTiles(capturedTiles, dynamicHexSize);
      // LOD 가 변했으므로 기존 컴포넌트들을 강제로 일괄 파기 및 무대 완벽 청소
      _tileMap.clear();
      final toRemove = children.whereType<HexTileComponent>().toList();
      removeAll(toRemove);
      _lastLodLevel = currentLod;
    }

    // [초최적화 위경도 Frustum Culling] 뷰포트 지리지형 경계선 획득 및 안전 마진 정의
    final bounds = _mapController!.camera.visibleBounds;
    final sw = bounds.southWest;
    final ne = bounds.northEast;

    // 안전 렌더링 버퍼 확보를 위해 위경도 임계 범위 마진 가미 (약 0.02도)
    final double marginLat = 0.02;
    final double marginLng = 0.02;
    final double minLat = sw.latitude - marginLat;
    final double maxLat = ne.latitude + marginLat;
    final double minLng = sw.longitude - marginLng;
    final double maxLng = ne.longitude + marginLng;

    // 1. 뷰포트 내 가식 영역에 포함되는 타일 데이터 선별 (O(K) 1차원 루프로 줌아웃 CPU 랙 원천 해결)
    final Set<String> visibleIds = {};
    final List<HexTile> visibleTiles = [];

    _lastClusteredTiles.forEach((id, tile) {
      final centerLatLng = _getTileCenter(tile.q, tile.r, id, dynamicHexSize);
      final double lat = centerLatLng.latitude;
      final double lng = centerLatLng.longitude;

      if (lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng) {
        // [적군 영토 은폐 가드] 1순위 초고속 필터: 투영 및 지리 연산 전에 적군 타일을 선결 거름으로써 CPU 부하 99% 제거
        if (dynamicHexSize >= GameConfig.lodSize3 && tile.userId != _currentUserId) {
          return;
        }
        visibleIds.add(id);
        visibleTiles.add(tile);
      }
    });

    // 2. 화면 영역 밖으로 벗어났거나 실제 점령 데이터가 없는 기존 컴포넌트 타일들은 즉시 소멸시켜 CPU/메모리 부하 차단 (단, 현재 점령 진행 중인 타일은 예외 수호)
    final existingIds = _tileMap.keys.toSet();
    for (final id in existingIds) {
      final isStillCapturing = id == capturingTileId ||
          (isSatelliteCapturing && id == satelliteCapturingTileId);
      if (!visibleIds.contains(id) && !isStillCapturing) {
        final component = _tileMap.remove(id);
        if (component != null) remove(component);
      }
    }

    // 3. 화면 내 가식 영역에 속하는 타일들만 생성/업데이트
    for (final tileData in visibleTiles) {
      final String id = tileData.id;
      final int q = tileData.q;
      final int r = tileData.r;

      final centerLatLng = _getTileCenter(q, r, id, dynamicHexSize);
      final cornerLatLngs = _getTileCorners(q, r, id, dynamicHexSize);
      final screenOffset = _mapController!.camera.latLngToScreenOffset(centerLatLng);

      final targetTileColorHex = (tileData.userId == _currentUserId)
          ? GameColors.myTileColorHex
          : GameColors.enemyTileColorHex;

      if (_tileMap.containsKey(id)) {
        _tileMap[id]!.position = Vector2(screenOffset.dx, screenOffset.dy);
        _tileMap[id]!.updateData(colorHex: targetTileColorHex);
      } else {
        final component = HexTileComponent(
          q: q,
          r: r,
          centerLatLng: centerLatLng,
          cornerLatLngs: cornerLatLngs,
          colorHex: targetTileColorHex,
          hexSize: dynamicHexSize,
        )
          ..position = Vector2(screenOffset.dx, screenOffset.dy)
          ..priority = 0;
        _tileMap[id] = component;
        add(component);
      }
    }

    // 점령 중인 타일 특수 상태 처리 (일반 점령 - 모든 LOD 단계에서 실시간 가시화 보장)
    if (capturingTileId != null) {
      _updateActiveCaptureTile(
        tileId: capturingTileId,
        progress: captureProgress,
        colorHex: capturingColorHex,
        isCapturing: true,
        fallbackLocation: currentLocation,
        hexSize: dynamicHexSize,
      );
    }

    // 점령 중인 타일 특수 상태 처리 (위성 원격 점령 - 모든 LOD 단계에서 실시간 가시화 보장)
    if (isSatelliteCapturing && satelliteCapturingTileId != null) {
      final bool shouldAnimateTile =
          _satelliteCapturePhase == SatelliteCapturePhase.capturing;
      _updateActiveCaptureTile(
        tileId: satelliteCapturingTileId,
        progress: shouldAnimateTile ? _satelliteCaptureProgress : 0.0,
        colorHex: capturingColorHex,
        isCapturing: shouldAnimateTile,
        hexSize: dynamicHexSize,
      );
    }

    // 점령 중이 아닌 타일 상태 초기화
    _tileMap.forEach((id, tile) {
      final isStillCapturing =
          id == capturingTileId ||
          (isSatelliteCapturing && id == satelliteCapturingTileId);
      if (!isStillCapturing && tile.isCapturing) {
        tile.updateData(isCapturing: false, progress: 0.0);
      }
    });
  }

  /// 점령이 진행 중인 특정 타일(일반 물리 점령 및 위성 원격 점령 공용)의
  /// 실시간 점령 게이지 데이터 및 펄싱 여부를 동적으로 렌더링하고 동기화합니다.
  void _updateActiveCaptureTile({
    required String tileId,
    required double progress,
    required String? colorHex,
    required bool isCapturing,
    LatLng? fallbackLocation,
    required double hexSize,
  }) {
    if (_tileMap.containsKey(tileId)) {
      _tileMap[tileId]!.updateData(
        isCapturing: isCapturing,
        progress: progress,
        capturingColorHex: colorHex,
      );
    } else {
      // 맵에 존재하지 않는 중립 구역인 경우
      int? q;
      int? r;
      final parsed = HexService.parseTileId(tileId);
      if (parsed != null) {
        q = parsed['q'];
        r = parsed['r'];
      } else if (fallbackLocation != null) {
        final hex = HexService.latLngToHex(fallbackLocation, hexSize: hexSize);
        q = hex['q'];
        r = hex['r'];
      }

      if (q != null && r != null) {
        // [중요 가드] 점령 중인 단일 타일의 화면 가시성 판정
        final bounds = _mapController!.camera.visibleBounds;
        final double minLat = bounds.southWest.latitude - 0.02;
        final double maxLat = bounds.northEast.latitude + 0.02;
        final double minLng = bounds.southWest.longitude - 0.02;
        final double maxLng = bounds.northEast.longitude + 0.02;

        final centerLatLng = _getTileCenter(q, r, tileId, hexSize);
        final double lat = centerLatLng.latitude;
        final double lng = centerLatLng.longitude;
        final bool isGeographicallyVisible =
            lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;

        if (isGeographicallyVisible) {
          final cornerLatLngs = _getTileCorners(q, r, tileId, hexSize);
          final screenOffset = _mapController!.camera.latLngToScreenOffset(centerLatLng);

          final tempTile = HexTileComponent(
            q: q,
            r: r,
            centerLatLng: centerLatLng,
            cornerLatLngs: cornerLatLngs,
            colorHex: null, // 점령 진행 중인 중립 구역은 채우기 색상 null
            hexSize: hexSize,
            isCapturing: isCapturing,
            progress: progress,
            capturingColorHex: colorHex,
          )
            ..position = Vector2(screenOffset.dx, screenOffset.dy)
            ..priority = 0;
          _tileMap[tileId] = tempTile;
          add(tempTile);
        }
      }
    }
  }

  /// 화면 스크린 변화 감지 시 렌더링 중인 플레이어 및 타일 컴포넌트들의 스크린 좌표를 일괄 재계산하여 이동시킵니다.
  void _updateAllPositions() {
    if (_mapController == null) return;

    // [순간이동 가드] 카메라 중심점이 급변(1km 이상)했을 경우, 잔상 방지를 위해 기존 헥사 컴포넌트 즉시 강제 전체 소거
    final LatLng currentCenter = _mapController!.camera.center;
    if (_lastCameraCenter != null) {
      final double dist = HexService.calculateDistance(
        _lastCameraCenter!,
        currentCenter,
      );
      if (dist > 1000.0) {
        _tileMap.clear();
        final toRemove = children.whereType<HexTileComponent>().toList();
        removeAll(toRemove);
      }
    }
    _lastCameraCenter = currentCenter;

    // 현재 LOD 레벨 및 규격 파악
    final double currentZoom = _mapController!.camera.zoom;
    final int currentLod = _getLodLevelForZoom(currentZoom);
    final double dynamicHexSize = _getHexSizeForZoom(currentZoom);

    // LOD 가 변했으면 타일들을 강제 리빌드 및 소멸 처리
    if (_lastLodLevel != currentLod || _lastClusteredTiles.isEmpty) {
      _rebuildClusteredTiles(_lastCapturedTiles, dynamicHexSize);
      // LOD 가 변했으므로 기존 컴포넌트들을 강제로 일괄 파기 및 무대 완벽 청소
      _tileMap.clear();
      final toRemove = children.whereType<HexTileComponent>().toList();
      removeAll(toRemove);
      _lastLodLevel = currentLod;
    }

    // [초최적화 위경도 Frustum Culling] 뷰포트 지리지형 경계선 획득 및 안전 마진 정의
    final bounds = _mapController!.camera.visibleBounds;
    final sw = bounds.southWest;
    final ne = bounds.northEast;

    // 안전 렌더링 버퍼 확보를 위해 위경도 임계 범위 마진 가미 (약 0.02도)
    final double marginLat = 0.02;
    final double marginLng = 0.02;
    final double minLat = sw.latitude - marginLat;
    final double maxLat = ne.latitude + marginLat;
    final double minLng = sw.longitude - marginLng;
    final double maxLng = ne.longitude + marginLng;

    // 1. 뷰포트 내 가식 영역에 포함되는 타일 데이터 선별 (O(K) 1차원 루프로 줌아웃 CPU 랙 원천 해결)
    final Set<String> visibleIds = {};
    final List<HexTile> visibleTiles = [];

    _lastClusteredTiles.forEach((id, tile) {
      final centerLatLng = _getTileCenter(tile.q, tile.r, id, dynamicHexSize);
      final double lat = centerLatLng.latitude;
      final double lng = centerLatLng.longitude;

      if (lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng) {
        // [적군 영토 은폐 가드] 1순위 초고속 필터: 투영 및 지리 연산 전에 적군 타일을 선결 거름으로써 CPU 부하 99% 제거
        if (dynamicHexSize >= GameConfig.lodSize3 && tile.userId != _currentUserId) {
          return;
        }
        visibleIds.add(id);
        visibleTiles.add(tile);
      }
    });

    // 2. 화면 영역 밖으로 벗어났거나 실제 점령 데이터가 없는 기존 컴포넌트 타일들은 즉시 소멸시켜 CPU/메모리 부하 차단 (단, 현재 점령 진행 중인 타일은 예외 수호)
    final existingIds = _tileMap.keys.toSet();
    for (final id in existingIds) {
      final component = _tileMap[id];
      final isStillCapturing = component != null && component.isCapturing;
      if (!visibleIds.contains(id) && !isStillCapturing) {
        _tileMap.remove(id);
        if (component != null) remove(component);
      }
    }

    // 3. 화면 내 가식 영역에 속하는 타일들만 생성/좌표 업데이트
    for (final tileData in visibleTiles) {
      final String id = tileData.id;
      final int q = tileData.q;
      final int r = tileData.r;

      final centerLatLng = _getTileCenter(q, r, id, dynamicHexSize);
      final cornerLatLngs = _getTileCorners(q, r, id, dynamicHexSize);
      final screenOffset = _mapController!.camera.latLngToScreenOffset(centerLatLng);

      final targetTileColorHex = (tileData.userId == _currentUserId)
          ? GameColors.myTileColorHex
          : GameColors.enemyTileColorHex;

      if (_tileMap.containsKey(id)) {
        _tileMap[id]!.position = Vector2(screenOffset.dx, screenOffset.dy);
        _tileMap[id]!.updateData(colorHex: targetTileColorHex);
      } else {
        final component = HexTileComponent(
          q: q,
          r: r,
          centerLatLng: centerLatLng,
          cornerLatLngs: cornerLatLngs,
          colorHex: targetTileColorHex,
          hexSize: dynamicHexSize,
        )
          ..position = Vector2(screenOffset.dx, screenOffset.dy)
          ..priority = 0;
        _tileMap[id] = component;
        add(component);
      }
    }

    // 플레이어 위치 갱신
    if (isLoaded) {
      player.isVisible = true;
      _updatePlayerScreenPosition();
    }
  }

  void updatePlayerLocation(LatLng location) {
    if (isLoaded) {
      player.updateLocation(location);
      _updatePlayerScreenPosition();
    }
  }

  void updatePlayerHeading(double heading) {
    if (isLoaded) player.updateHeading(heading);
  }

  /// 요원의 현재 지도 GPS 위치(LatLng)를 기반으로 하여 디바이스 화면 상의 픽셀 좌표값으로 최종 정렬시킵니다.
  void _updatePlayerScreenPosition() {
    if (_mapController != null) {
      final offset = _mapController!.camera.latLngToScreenOffset(
        player.location,
      );
      player.updateScreenPosition(Offset(offset.dx, offset.dy));
    }
  }

  /// 본부 기지(HQ) 설정 변화를 탐지하여 이전에 설치된 마커를 파기하거나 신규 생성 및 색상 갱신을 진행합니다.
  void _updateHQMarker(String? newHQTileId, String? colorHex) {
    if (_currentHQTileId == newHQTileId) {
      _hqMarker?.updateColor(colorHex);
      return;
    }

    _currentHQTileId = newHQTileId;
    if (_hqMarker != null) {
      remove(_hqMarker!);
      _hqMarker = null;
    }

    if (newHQTileId != null && newHQTileId.isNotEmpty) {
      final parsed = HexService.parseTileId(newHQTileId);
      if (parsed != null) {
        final int q = parsed['q'];
        final int r = parsed['r'];
        _hqMarker = HQBaseMarker(q: q, r: r, colorHex: colorHex);
        add(_hqMarker!);
      }
    }
  }

  /// 위성 궤도 스캔 조준 상태 혹은 진행 중인 위성 점령 타일에 타겟 링 마커를 바인딩하고 좌표를 갱신합니다.
  void _updateScanTargetMarker(String? selectedScanTileId, bool isScanMode) {
    int? targetQ;
    int? targetR;

    // 위성 점령이 진행 중일 때는 위성 모드가 꺼져 있어도 마커를 계속 유지함
    final activeTileId = _isSatelliteCapturing
        ? _satelliteCapturingTileId
        : (isScanMode ? selectedScanTileId : null);

    if (activeTileId != null && activeTileId.isNotEmpty) {
      final parsed = HexService.parseTileId(activeTileId);
      if (parsed != null) {
        targetQ = parsed['q'];
        targetR = parsed['r'];
      }
    }

    if (_scanTargetMarker != null) {
      // 이미 같은 타일의 마커가 조준되어 있다면 새로 삭제/생성하지 않고 재사용함
      if (targetQ != null &&
          targetR != null &&
          _scanTargetMarker!.q == targetQ &&
          _scanTargetMarker!.r == targetR) {
        return;
      }
      remove(_scanTargetMarker!);
      _scanTargetMarker = null;
    }

    if (targetQ != null && targetR != null) {
      _scanTargetMarker = ScanTargetMarker(q: targetQ, r: targetR);
      add(_scanTargetMarker!);
    }
  }
}
