import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibration/vibration.dart';
import '../models/tile_model.dart';
import '../services/supabase_service.dart';
import '../services/hex_service.dart';
import '../core/constants.dart';
import '../core/constants/strings.dart';
import '../models/alert_model.dart';

class CaptureController {
  final SupabaseService _supabase;
  final void Function(String message, AlertType type) onAlert;
  final void Function(String tileId, HexTile tile) onTileCaptured;
  final VoidCallback onStateChanged;

  String? _capturingTileId;
  String? _userId;
  LatLng? _startLocation;
  String? _colorHex;
  DateTime? _startTime;
  Duration? _targetDuration;
  double _captureProgress = 0.0;
  Timer? _captureTimer;
  bool _isSaving = false;

  String? get capturingTileId => _capturingTileId;
  String? get capturingColorHex => _colorHex;
  double get captureProgress => _captureProgress;
  bool get isCapturing => _capturingTileId != null;

  CaptureController({
    required SupabaseService supabase,
    required this.onAlert,
    required this.onTileCaptured,
    required this.onStateChanged,
  }) : _supabase = supabase;

  void startCapture({
    required String tileId,
    required LatLng location,
    required String userId,
    required String colorHex,
    required Duration duration,
  }) {
    if (_isSaving || _capturingTileId == tileId) return;

    cancelCapture();
    _capturingTileId = tileId;
    _startLocation = location;
    _userId = userId;
    _colorHex = colorHex;
    _startTime = DateTime.now();
    _targetDuration = duration;

    _vibrate([0, 50, 30, 50]);
    _captureTimer = Timer.periodic(const Duration(milliseconds: GameConstants.updateIntervalMs), (_) => checkCaptureStatus());
  }

  void checkCaptureStatus() {
    if (_capturingTileId == null || _isSaving) return;

    final elapsed = DateTime.now().difference(_startTime!);
    _captureProgress = (elapsed.inMilliseconds / _targetDuration!.inMilliseconds).clamp(0.0, 1.0);

    if (_captureProgress >= 1.0) {
      _saveCapture();
    } else {
      onStateChanged();
    }
  }

  void cancelCapture() {
    if (_isSaving) return;
    _captureTimer?.cancel();
    _captureTimer = null;
    _capturingTileId = null;
    _captureProgress = 0.0;
    onStateChanged();
  }

  Future<void> _saveCapture() async {
    if (_isSaving) return;
    _isSaving = true;
    _captureTimer?.cancel();
    _vibrate(500);

    final hex = HexService.latLngToHex(_startLocation!);
    final tile = HexTile(
      id: _capturingTileId!,
      q: hex['q']!,
      r: hex['r']!,
      userId: _userId,
      colorHex: _colorHex,
      bounds: HexService.getHexCorners(hex['q']!, hex['r']!).map((l) => [l.latitude, l.longitude]).toList(),
      capturedAt: DateTime.now(),
    );

    final success = await _supabase.captureTile(tile);
    if (success) {
      onTileCaptured(tile.id, tile);
      onAlert(GameStrings.captureSuccessAlert, AlertType.success);
    } else {
      onAlert(GameStrings.captureFailAlert, AlertType.error);
    }

    _isSaving = false;
    _capturingTileId = null;
    _captureProgress = 0.0;
    onStateChanged();
  }

  void _vibrate(dynamic pattern) {
    try {
      Vibration.hasVibrator().then((has) {
        if (has == true) {
          if (pattern is List<int>) Vibration.vibrate(pattern: pattern);
          if (pattern is int) Vibration.vibrate(duration: pattern);
        }
      });
    } catch (_) {}
  }

  void dispose() => _captureTimer?.cancel();
}
