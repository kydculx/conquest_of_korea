import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/game_provider.dart';

class HudOverlay extends StatelessWidget {
  final Map<String, int> scores;
  final String teamName;
  final bool isCapturing;
  final double captureProgress;

  const HudOverlay({
    super.key,
    required this.scores,
    required this.teamName,
    this.isCapturing = false,
    this.captureProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return Stack(
      children: [
        // 상단 전술 점수판
        Positioned(
          top: 50,
          left: 30,
          right: 30,
          child: _buildTacticalScoreboard(),
        ),

        // 하단 안내 텍스트 (원형 게이지 제거)
        if (isCapturing)
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(180),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text('구역 점령 중...', 
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ),

        // 하단 중앙 점령 버튼 (메인 액션)
        if (!gameProvider.isAutoCapture && !isCapturing)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: _buildMainCaptureButton(gameProvider),
            ),
          ),

        // 우측 하단 유틸리티 버튼들 (내 위치 버튼과 겹침 방지 위해 세로 배치)
        Positioned(
          left: 20,
          bottom: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGpsReset(gameProvider),
              const SizedBox(height: 12),
              _buildMapToggle(gameProvider),
              const SizedBox(height: 12),
              _buildModeToggle(gameProvider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTacticalScoreboard() {
    final blueScore = scores['blue'] ?? 0;
    final redScore = scores['red'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(200),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(150),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTeamScore('블루', blueScore, GameConstants.teamBlue),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('VS', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
          ),
          _buildTeamScore('레드', redScore, GameConstants.teamRed),
        ],
      ),
    );
  }

  Widget _buildTeamScore(String label, int score, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label == '레드') _buildScoreText(score, color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color.withAlpha(200), fontSize: 14, fontWeight: FontWeight.w900)),
        const SizedBox(width: 8),
        if (label == '블루') _buildScoreText(score, color),
      ],
    );
  }

  Widget _buildScoreText(int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(100), width: 1),
      ),
      child: Text(score.toString(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
    );
  }

  Widget _buildMainCaptureButton(GameProvider provider) {
    final bool canCapture = provider.canCapture;
    final double accuracy = provider.currentAccuracy;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (provider.isGpsActive)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(150),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accuracy > GameConstants.captureAccuracyThreshold 
                    ? Colors.red.withAlpha(150) 
                    : Colors.green.withAlpha(150),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.gps_fixed, 
                  size: 12, 
                  color: accuracy > GameConstants.captureAccuracyThreshold ? Colors.red : Colors.green
                ),
                const SizedBox(width: 6),
                Text(
                  '오차: ${accuracy.toStringAsFixed(1)}m',
                  style: TextStyle(
                    color: accuracy > GameConstants.captureAccuracyThreshold ? Colors.red : Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        
        GestureDetector(
          onTap: canCapture ? () => provider.startManualCapture() : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: canCapture ? Colors.red.withAlpha(220) : Colors.grey.withAlpha(150),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(canCapture ? 200 : 50), width: 4),
              boxShadow: canCapture ? [
                BoxShadow(
                  color: Colors.red.withAlpha(150),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
              ] : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(canCapture ? Icons.radar : Icons.lock, color: Colors.white, size: 40),
                const SizedBox(height: 4),
                Text(
                  canCapture ? '점령하기' : '점령불가',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGpsReset(GameProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'GPS 리셋',
          style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => provider.resetGps(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(180),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.withAlpha(100)),
              ),
              child: const Icon(
                Icons.flash_on,
                color: Colors.orange,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapToggle(GameProvider provider) {
    final currentStyle = provider.currentMapStyle;
    IconData iconData;
    
    switch (currentStyle.icon) {
      case 'dark_mode': iconData = Icons.dark_mode; break;
      case 'light_mode': iconData = Icons.light_mode; break;
      case 'satellite_alt': iconData = Icons.satellite_alt; break;
      case 'terrain': iconData = Icons.terrain; break;
      case 'add_road': iconData = Icons.add_road; break;
      case 'explore': iconData = Icons.explore; break;
      case 'brightness_5': iconData = Icons.brightness_5; break;
      case 'map': iconData = Icons.map; break;
      case 'public': iconData = Icons.public; break;
      case 'straighten': iconData = Icons.straighten; break;
      case 'filter_hdr': iconData = Icons.filter_hdr; break;
      case 'landscape': iconData = Icons.landscape; break;
      case 'directions_bike': iconData = Icons.directions_bike; break;
      case 'layers_clear': iconData = Icons.layers_clear; break;
      default: iconData = Icons.map;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          currentStyle.name,
          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => provider.cycleMapStyle(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(180),
                shape: BoxShape.circle,
                border: Border.all(color: provider.showMap ? Colors.white10 : GameConstants.accentNeon.withAlpha(100)),
              ),
              child: Icon(
                iconData,
                color: provider.showMap ? Colors.white : GameConstants.accentNeon,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeToggle(GameProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          provider.isAutoCapture ? '자동' : '수동',
          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => provider.toggleAutoCapture(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(180),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: Icon(
                provider.isAutoCapture ? Icons.sync : Icons.touch_app,
                color: provider.isAutoCapture ? GameConstants.accentNeon : Colors.white54,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

}
