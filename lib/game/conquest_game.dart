import 'dart:ui';
import 'package:flame/game.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'components/player_component.dart';
import 'components/hex_tile_component.dart';
import 'components/hub_component.dart';
import '../services/hex_service.dart';
import '../core/hubs.dart';
import '../providers/game_provider.dart';

class ConquestGame extends FlameGame {
  late PlayerComponent player;
  final List<HubComponent> _hubComponents = [];
  MapController? _mapController;
  Map<String, Map<String, dynamic>> _lastCapturedTiles = {};

  @override
  Color backgroundColor() => const Color(0x00000000); // 투명 배경

  @override
  Future<void> onLoad() async {
    player = PlayerComponent()..priority = 20;
    add(player);

    // 거점 초기 생성 (위치는 나중에 updateProjection에서 결정)
    for (var hub in tacticalHubs) {
      final component = HubComponent(
        name: hub.name,
        type: hub.type,
        screenPosition: Offset.zero,
      )..priority = 10;
      _hubComponents.add(component);
      add(component);
    }

    // 로딩 완료 후 즉시 위치 업데이트 (이미 맵 컨트롤러가 있다면)
    if (_mapController != null) {
      _updateAllComponentPositions();
    }
  }

  /// 지도의 투영(Projection) 정보를 업데이트하여 컴포넌트 위치 재계산
  void updateProjection(MapController controller) {
    _mapController = controller;
    _updateAllComponentPositions();
  }

  final Map<String, HexTileComponent> _tileMap = {}; // ID 기반 타일 관리

  /// 점령된 타일 목록을 받아서 렌더링 업데이트
  void updateCapturedTiles(GameProvider provider) {
    _lastCapturedTiles = provider.capturedTiles;
    _refreshTiles(provider);
  }

  void _refreshTiles(GameProvider gameProvider) {
    if (_mapController == null) return;

    final currentIds = _lastCapturedTiles.keys.toSet();
    final existingIds = _tileMap.keys.toSet();

    // 1. 없어진 타일 제거
    for (var id in existingIds.difference(currentIds)) {
      final tile = _tileMap.remove(id);
      if (tile != null) remove(tile);
    }

    // 2. 새 타일 추가 또는 기존 타일 업데이트
    _lastCapturedTiles.forEach((id, data) {
      final q = data['q'] as int;
      final r = data['r'] as int;
      final owner = data['owner'] as String;
      
      final corners = HexService.getHexCorners(q, r);
      final screenCorners = corners.map((latLng) {
        final offset = _mapController!.camera.latLngToScreenOffset(latLng);
        return Offset(offset.dx, offset.dy);
      }).toList();

      if (_tileMap.containsKey(id)) {
        // 기존 타일 업데이트 (재사용)
        _tileMap[id]!.updateData(owner: owner, corners: screenCorners);
      } else {
        // 새 타일 생성
        final tile = HexTileComponent(owner: owner, corners: screenCorners)..priority = 0;
        _tileMap[id] = tile;
        add(tile);
      }
    });

    // 3. 점령 중인 타일 특수 상태 업데이트
    final capturingId = gameProvider.capturingTileId;
    final captureProgress = gameProvider.captureProgress;

    if (capturingId != null) {
      final myTeam = gameProvider.selectedTeam;
      if (_tileMap.containsKey(capturingId)) {
        // 기존 점령된 타일을 재점령 중인 경우
        _tileMap[capturingId]!.updateData(
          isCapturing: true, 
          progress: captureProgress,
          capturingTeam: myTeam,
        );
      } else {
        // 완전히 새로운 타일을 점령 중인 경우 (임시 생성)
        final hex = HexService.latLngToHex(gameProvider.currentLocation!);
        final corners = HexService.getHexCorners(hex['q']!, hex['r']!);
        final screenCorners = corners.map((latLng) {
          final offset = _mapController!.camera.latLngToScreenOffset(latLng);
          return Offset(offset.dx, offset.dy);
        }).toList();

        final tempTile = HexTileComponent(
          owner: 'none', // 아직 주인 없음
          corners: screenCorners,
          isCapturing: true,
          progress: captureProgress,
          capturingTeam: myTeam,
        )..priority = 0;
        
        _tileMap[capturingId] = tempTile;
        add(tempTile);
      }
    }

    // 다른 모든 타일의 점령 상태 해제 (capturingId가 아닌 경우)
    _tileMap.forEach((id, tile) {
      if (id != capturingId && tile.isCapturing) {
        tile.updateData(isCapturing: false, progress: 0.0);
      }
    });
  }

  void _updateAllComponentPositions() {
    if (_mapController == null) return;

    // 1. 거점 위치 업데이트
    if (_hubComponents.length != tacticalHubs.length) {
      for (var hub in _hubComponents) {
        remove(hub);
      }
      _hubComponents.clear();
      
      for (var hub in tacticalHubs) {
        final component = HubComponent(
          name: hub.name,
          type: hub.type,
          screenPosition: Offset.zero,
        )..priority = 10;
        _hubComponents.add(component);
        add(component);
      }
    }

    // 위치 갱신
    for (int i = 0; i < tacticalHubs.length; i++) {
      final hubData = tacticalHubs[i];
      final component = _hubComponents[i];
      final offset = _mapController!.camera.latLngToScreenOffset(hubData.location);
      component.position = Vector2(offset.dx, offset.dy);
    }

    // 2. 타일 위치 업데이트
    _tileMap.forEach((id, tile) {
      final data = _lastCapturedTiles[id];
      if (data != null) {
        final q = data['q'] as int;
        final r = data['r'] as int;
        final corners = HexService.getHexCorners(q, r);
        final screenCorners = corners.map((latLng) {
          final offset = _mapController!.camera.latLngToScreenOffset(latLng);
          return Offset(offset.dx, offset.dy);
        }).toList();
        tile.updateData(corners: screenCorners);
      }
    });

    // 3. 플레이어 위치 업데이트
    if (player.isLoaded) {
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
    if (isLoaded) {
      player.updateHeading(heading);
    }
  }

  void _updatePlayerScreenPosition() {
    if (_mapController != null) {
      final offset = _mapController!.camera.latLngToScreenOffset(player.location);
      player.updateScreenPosition(Offset(offset.dx, offset.dy));
    }
  }
}
