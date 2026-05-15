import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibration/vibration.dart';
import '../models/alert_model.dart';
import '../models/tile_model.dart';
import '../services/supabase_service.dart';
import '../services/hex_service.dart';
import '../core/constants.dart';

/// 점령 비즈니스 로직 전담 컨트롤러
/// GameProvider가 소유하며, 콜백을 통해 상태 변경을 통지한다.
class CaptureController {
  final SupabaseService _supabase;
  final void Function(String message, AlertType type) onAlert;
  final void Function(String tileId, HexTile tile) onTileCaptured;
  final VoidCallback onStateChanged;

  String? _capturingTileId;
  String? _capturingColorHex;
  double _captureProgress = 0.0;
  Timer? _captureTimer;

  String? get capturingTileId => _capturingTileId;
  String? get capturingColorHex => _capturingColorHex;
  double get captureProgress => _captureProgress;
  bool get isCapturing => _capturingTileId != null;

  CaptureController({
    required SupabaseService supabase,
    required this.onAlert,
    required this.onTileCaptured,
    required this.onStateChanged,
  }) : _supabase = supabase;

  /// 점령 시작
  void startCapture({
    required String tileId,
    required LatLng location,
    required String userId,
    required String colorHex,
    required bool isEnemyTile,
  }) {
    cancelCapture();
    _capturingTileId = tileId;
    _capturingColorHex = colorHex;
    _captureProgress = 0.0;

    Vibration.vibrate(pattern: [0, 50, 30, 50]);

    final duration = isEnemyTile
        ? GameConstants.enemyTileDuration
        : GameConstants.emptyTileDuration;
    final totalSteps =
        duration.inMilliseconds / GameConstants.updateIntervalMs;
    final stepIncrement = 1.0 / totalSteps;

    _captureTimer = Timer.periodic(
      const Duration(milliseconds: GameConstants.updateIntervalMs),
      (timer) {
        _captureProgress += stepIncrement;
        if (_captureProgress >= 1.0) {
          _captureProgress = 1.0;
          _finishCapture(tileId, location, userId, colorHex);
          timer.cancel();
        }
        onStateChanged();
      },
    );
  }

  /// 점령 취소
  void cancelCapture() {
    if (_capturingTileId != null) {
      _captureTimer?.cancel();
      _capturingTileId = null;
      _capturingColorHex = null;
      _captureProgress = 0.0;
      onStateChanged();
    }
  }

  /// 점령 완료 처리
  Future<void> _finishCapture(
      String tileId, LatLng location, String userId, String colorHex) async {
    Vibration.vibrate(duration: 500);

    final hex = HexService.latLngToHex(location);
    final corners = HexService.getHexCorners(hex['q']!, hex['r']!);
    final bounds =
        corners.map((latlng) => [latlng.latitude, latlng.longitude]).toList();

    final tile = HexTile(
      id: tileId,
      q: hex['q']!,
      r: hex['r']!,
      userId: userId,
      colorHex: colorHex,
      bounds: bounds,
      capturedAt: DateTime.now(),
    );

    try {
      final success = await _supabase.captureTile(tile);
      if (success) {
        onTileCaptured(tileId, tile);
        onAlert('구역을 점령했습니다!', AlertType.success);
      } else {
        onAlert('점령 실패: 이미 점령된 구역일 수 있습니다.', AlertType.error);
      }
    } catch (e) {
      debugPrint('점령 서버 전송 실패: $e');
      onAlert('통신 오류: 점령 정보 전송에 실패했습니다.', AlertType.error);
    } finally {
      _capturingTileId = null;
      _capturingColorHex = null;
      _captureProgress = 0.0;
      onStateChanged();
    }
  }

  void dispose() {
    _captureTimer?.cancel();
  }
}
