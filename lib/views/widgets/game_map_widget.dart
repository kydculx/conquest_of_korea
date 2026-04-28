import 'package:flutter/material.dart';
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

class _GameMapWidgetState extends State<GameMapWidget> {
  final MapController _mapController = MapController();
  bool _isFollowing = true;

  @override
  void didUpdateWidget(GameMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isFollowing &&
        widget.initialLocation != oldWidget.initialLocation) {
      _mapController.move(
          widget.initialLocation, _mapController.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: GameConstants.tacticalBlack,
      child: Stack(
        children: [
          // 지도 레이어
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation,
              initialZoom: GameConstants.defaultZoom,
              minZoom: GameConstants.minZoom,
              maxZoom: GameConstants.maxZoom,
              backgroundColor: Colors.transparent,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) setState(() => _isFollowing = false);
                widget.game.updateProjection(_mapController);
              },
            ),
            children: [
              if (gameProvider.showMap)
                TileLayer(
                  urlTemplate: gameProvider.currentMapStyle.url,
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.conquest.mobile',
                ),
            ],
          ),

          // Flame 게임 레이어 (터치 통과)
          Positioned.fill(
            child: IgnorePointer(
              child: GameWidget(game: widget.game),
            ),
          ),

          // 내 위치로 이동 버튼
          Positioned(
            right: 20,
            bottom: 40,
            child: FloatingActionButton.small(
              backgroundColor: Colors.black.withAlpha(200),
              onPressed: () {
                setState(() => _isFollowing = true);
                _mapController.move(
                    widget.initialLocation, _mapController.camera.zoom);
              },
              child: Icon(
                Icons.my_location,
                color: _isFollowing
                    ? GameConstants.accentNeon
                    : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
