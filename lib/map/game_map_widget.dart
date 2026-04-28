import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flame/game.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../game/conquest_game.dart';
import '../core/constants.dart';
import '../providers/game_provider.dart';

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

class _GameMapWidgetState extends State<GameMapWidget> {
  final MapController _mapController = MapController();
  bool _isFollowing = true;

  @override
  void didUpdateWidget(GameMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isFollowing && widget.initialLocation != oldWidget.initialLocation) {
      _mapController.move(widget.initialLocation, _mapController.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: GameConstants.tacticalBlack, // 지도가 없을 때 보여줄 기본 배경색
      child: Stack(
        children: [
          // 1. 지도 레이어 (OSM)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation,
              initialZoom: GameConstants.defaultZoom,
              minZoom: GameConstants.minZoom,
              maxZoom: GameConstants.maxZoom,
              backgroundColor: Colors.transparent, // 배경을 투명하게 하여 Container 색상이 보이게 함
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() => _isFollowing = false);
                }
                widget.game.updateProjection(_mapController);
              },
            ),
            children: [
              if (gameProvider.showMap)
                TileLayer(
                  urlTemplate: gameProvider.currentMapStyle.url,
                  subdomains: const ['a', 'b', 'c', 'd'], // 구글 위성은 subdomains를 사용하지 않지만 OSM 기반은 필요함
                  userAgentPackageName: 'com.conquest.mobile',
                ),
            ],
          ),

          // 2. 게임 엔진 레이어 (Flame - 헥사곤 점령 구역 표시)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: GameWidget(game: widget.game),
            ),
          ),

          // 3. 내 위치로 돌아가기 버튼 (상시 활성화)
          Positioned(
            right: 20,
            bottom: 40,
            child: FloatingActionButton.small(
              backgroundColor: Colors.black.withAlpha(200),
              child: Icon(
                Icons.my_location, 
                color: _isFollowing ? GameConstants.accentNeon : Colors.white
              ),
              onPressed: () {
                setState(() => _isFollowing = true);
                _mapController.move(widget.initialLocation, _mapController.camera.zoom);
              },
            ),
          ),
        ],
      ),
    );
  }
}
