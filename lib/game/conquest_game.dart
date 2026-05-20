import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'components/player_component.dart';
import 'components/hex_tile_component.dart';
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

  MapController? get mapController => _mapController;

  @override
  Color backgroundColor() => GameColors.transparent;

  @override
  Future<void> onLoad() async {
    player = PlayerComponent()..priority = 20;
    add(player);

    // FPS 실시간 카운터 추가 (상단 중앙 배치)
    _fpsComponent = FpsTextComponent(
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 60),
      priority: 100,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF00FF00), // 네온 그린 (디버깅용)
          fontSize: 14,
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0x60000000), // 가독성을 위한 불투명 백그라운드
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
    _updateAllPositions();
  }

  /// 점령 타일 렌더링 업데이트 (복구)
  void updateCapturedTiles({
    required Map<String, HexTile> capturedTiles,
    String? capturingTileId,
    double captureProgress = 0.0,
    String? capturingColorHex,
    LatLng? currentLocation,
  }) {
    _lastCapturedTiles = capturedTiles;
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
    if (player.isLoaded) _updatePlayerScreenPosition();
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
}
