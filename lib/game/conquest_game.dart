import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'components/player_component.dart';
import 'components/hex_tile_component.dart';
import 'components/hq_base_marker.dart';
import 'components/scan_target_marker.dart';
import '../services/hex_service.dart';
import '../models/tile_model.dart';
import '../core/constants.dart';

/// Flame 게임 엔진 — 거점 마커 및 점령 타일 렌더링 담당
class ConquestGame extends FlameGame {
  late PlayerComponent player;
  MapController? _mapController;
  Map<String, HexTile> _lastCapturedTiles = {};
  final Map<String, HexTileComponent> _tileMap = {};
  FpsTextComponent? _fpsComponent;
  HQBaseMarker? _hqMarker;
  ScanTargetMarker? _scanTargetMarker;
  String? _currentHQTileId;
  String? _lastCapturingColorHex;
  bool _isScanMode = false; // 추가: 위성 스캔 모드 상태 캐싱
  String? _currentUserId; // 추가: 현재 로그인 사용자 ID 캐싱
  bool _isSatelliteCapturing = false; // 추가: 위성 점령 상태 캐싱
  double _satelliteCaptureProgress = 0.0; // 추가: 위성 점령 진행률 캐싱
  String? _satelliteCapturingTileId; // 추가: 위성 점령 목적지 타일 ID 캐싱

  MapController? get mapController => _mapController;
  String? get currentHQTileId => _currentHQTileId;
  String? get currentUserId => _currentUserId;
  Map<String, HexTile> get lastCapturedTiles => _lastCapturedTiles;
  bool get isSatelliteCapturing => _isSatelliteCapturing; // 추가
  double get satelliteCaptureProgress => _satelliteCaptureProgress; // 추가
  String? get satelliteCapturingTileId => _satelliteCapturingTileId; // 추가
  bool get isScanMode => _isScanMode; // 추가

  @override
  Color backgroundColor() => GameColors.transparent;

  @override
  Future<void> onLoad() async {
    player = PlayerComponent()..priority = 20;
    player.isVisible = !_isScanMode;
    add(player);

    // FPS 실시간 카운터 추가 (상단 중앙 배치 - 시각적 인지 부하 감소를 위해 크기 축소 및 투명화)
    _fpsComponent = FpsTextComponent(
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 60),
      priority: 100,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0x88CBD5E1), // 반투명 소프트 실버
          fontSize: 10,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.5,
        ),
      ),
    );
    add(_fpsComponent!);

    if (_mapController != null) _updateAllPositions();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_fpsComponent != null && isLoaded) {
      _fpsComponent!.position = Vector2(size.x / 2, 60);
    }
  }

  double _dtSum = 0.0;
  static const double _fixedDeltaTime = 1 / 60; // 60 FPS 강제 제한

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
        selectedScanTileId: _scanTargetMarker != null ? 'hex_${_scanTargetMarker!.q}_${_scanTargetMarker!.r}' : null,
        isScanMode: _scanTargetMarker != null,
        capturingColorHex: _lastCapturingColorHex,
        currentUserId: _currentUserId,
        isSatelliteCapturing: _isSatelliteCapturing,
        satelliteCaptureProgress: _satelliteCaptureProgress,
      );
    } else {
      _updateAllPositions();
    }
  }

  /// 점령 타일 렌더링 업데이트 (복구)
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
    double satelliteCaptureProgress = 0.0,
    String? satelliteCapturingTileId,
  }) {
    _lastCapturedTiles = capturedTiles;
    _lastCapturingColorHex = capturingColorHex;
    _isScanMode = isScanMode;
    _currentUserId = currentUserId;
    _isSatelliteCapturing = isSatelliteCapturing;
    _satelliteCaptureProgress = satelliteCaptureProgress;
    _satelliteCapturingTileId = satelliteCapturingTileId;
    if (isLoaded) {
      player.isVisible = !isScanMode;
    }
    _updateHQMarker(mainBaseTileId, capturingColorHex);
    _updateScanTargetMarker(selectedScanTileId, isScanMode);
    if (_mapController == null) return;

    final currentIds = capturedTiles.keys.toSet();
    final existingIds = _tileMap.keys.toSet();

    // 제거된 타일 삭제
    for (final id in existingIds.difference(currentIds)) {
      final tile = _tileMap.remove(id);
      if (tile != null) remove(tile);
    }

    // 신규/업데이트 타일 처리
    capturedTiles.forEach((id, data) {
      final screenCorners = _calcScreenCorners(data.q, data.r);
      if (_tileMap.containsKey(id)) {
        _tileMap[id]!.updateData(
          colorHex: data.colorHex,
          corners: screenCorners,
        );
      } else {
        final tile = HexTileComponent(
          colorHex: data.colorHex,
          corners: screenCorners,
        )..priority = 0;
        _tileMap[id] = tile;
        add(tile);
      }
    });

    // 점령 중인 타일 특수 상태 처리
    if (capturingTileId != null) {
      if (_tileMap.containsKey(capturingTileId)) {
        _tileMap[capturingTileId]!.updateData(
          isCapturing: true,
          progress: captureProgress,
          capturingColorHex: capturingColorHex,
        );
      } else if (currentLocation != null) {
        final hex = HexService.latLngToHex(currentLocation);
        final screenCorners = _calcScreenCorners(hex['q']!, hex['r']!);
        final tempTile = HexTileComponent(
          colorHex: null,
          corners: screenCorners,
          isCapturing: true,
          progress: captureProgress,
          capturingColorHex: capturingColorHex,
        )..priority = 0;
        _tileMap[capturingTileId] = tempTile;
        add(tempTile);
      }
    }

    // 점령 중이 아닌 타일 상태 초기화
    _tileMap.forEach((id, tile) {
      if (id != capturingTileId && tile.isCapturing) {
        tile.updateData(isCapturing: false, progress: 0.0);
      }
    });
  }

  List<Offset> _calcScreenCorners(int q, int r) {
    final corners = HexService.getHexCorners(q, r);
    return corners.map((latlng) {
      final offset = _mapController!.camera.latLngToScreenOffset(latlng);
      return Offset(offset.dx, offset.dy);
    }).toList();
  }

  void _updateAllPositions() {
    if (_mapController == null) return;

    // 타일 위치 갱신
    _tileMap.forEach((id, tile) {
      final data = _lastCapturedTiles[id];
      if (data != null) {
        tile.updateData(corners: _calcScreenCorners(data.q, data.r));
      }
    });

    // 플레이어 위치 갱신
    if (isLoaded) {
      player.isVisible = !_isScanMode;
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

  void _updatePlayerScreenPosition() {
    if (_mapController != null) {
      final offset = _mapController!.camera.latLngToScreenOffset(
        player.location,
      );
      player.updateScreenPosition(Offset(offset.dx, offset.dy));
    }
  }

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
      final parts = newHQTileId.split('_');
      if (parts.length == 3 && parts[0] == 'hex') {
        final q = int.tryParse(parts[1]);
        final r = int.tryParse(parts[2]);
        if (q != null && r != null) {
          _hqMarker = HQBaseMarker(q: q, r: r, colorHex: colorHex);
          add(_hqMarker!);
        }
      }
    }
  }

  void _updateScanTargetMarker(String? selectedScanTileId, bool isScanMode) {
    int? targetQ;
    int? targetR;

    // 위성 점령이 진행 중일 때는 위성 모드가 꺼져 있어도 마커를 계속 유지함
    final activeTileId = _isSatelliteCapturing ? _satelliteCapturingTileId : (isScanMode ? selectedScanTileId : null);

    if (activeTileId != null && activeTileId.isNotEmpty) {
      final parts = activeTileId.split('_');
      if (parts.length == 3 && parts[0] == 'hex') {
        targetQ = int.tryParse(parts[1]);
        targetR = int.tryParse(parts[2]);
      }
    }

    if (_scanTargetMarker != null) {
      // 이미 같은 타일의 마커가 조준되어 있다면 새로 삭제/생성하지 않고 재사용함
      if (targetQ != null && targetR != null && _scanTargetMarker!.q == targetQ && _scanTargetMarker!.r == targetR) {
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
