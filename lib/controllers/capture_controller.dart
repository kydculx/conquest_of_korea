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
  final void Function(String tileId, HexTile tile, {required bool wasEnemyTile}) onTileCaptured;
  final VoidCallback onStateChanged;

  String? _capturingTileId;
  String? _userId;
  LatLng? _startLocation;
  String? _colorHex;
  DateTime? _startTime;
  Duration? _targetDuration;
  int _targetCaptureCount = 1; // 점령 성공 시 저장할 목표 점령 횟수
  double _captureProgress = 0.0;
  bool _wasEnemyTile = false; // 점령 시작 시 상대방 구역이었는지 여부
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
    required int targetCaptureCount, // 목표 점령 횟수 인자 추가
    bool wasEnemyTile = false,       // 상대방 구역 여부
  }) {
    if (_isSaving || _capturingTileId == tileId) return;

    cancelCapture();
    _capturingTileId = tileId;
    _startLocation = location;
    _userId = userId;
    _colorHex = colorHex;
    _startTime = DateTime.now();
    _targetDuration = duration;
    _targetCaptureCount = targetCaptureCount;
    _wasEnemyTile = wasEnemyTile;

    _vibrate([0, 50, 30, 50]);
    _captureTimer = Timer.periodic(const Duration(milliseconds: GameConstants.updateIntervalMs), (_) => checkCaptureStatus());
  }

  void checkCaptureStatus([LatLng? currentLocation]) {
    if (_capturingTileId == null || _isSaving) return;

    // [신규] 실시간 GPS 위치가 공급되었고, 그 위치의 타일ID가 시작 시 타일ID와 다르면 점령 즉시 취소!
    if (currentLocation != null) {
      final currentHex = HexService.latLngToHex(currentLocation);
      final currentTileId = 'hex_${currentHex['q']}_${currentHex['r']}';
      if (currentTileId != _capturingTileId) {
        cancelCapture();
        onAlert(GameStrings.captureCanceledOutOfBoundary, AlertType.error);
        return;
      }
    }

    final elapsed = DateTime.now().difference(_startTime!);
    _captureProgress = (elapsed.inMilliseconds / _targetDuration!.inMilliseconds).clamp(0.0, 1.0);

    if (_captureProgress >= 1.0) {
      _saveCapture(currentLocation);
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

  Future<void> _saveCapture(LatLng? currentLocation) async {
    if (_isSaving) return;
    _isSaving = true;
    _captureTimer?.cancel();
    _vibrate(500);

    // [신규] 최종 저장 시점에도 현재 실시간 위치의 타일ID가 시작 시 타일ID와 동일한지 크로스 검증!
    if (currentLocation != null) {
      final currentHex = HexService.latLngToHex(currentLocation);
      final currentTileId = 'hex_${currentHex['q']}_${currentHex['r']}';
      if (currentTileId != _capturingTileId) {
        _isSaving = false;
        _capturingTileId = null;
        _captureProgress = 0.0;
        onAlert(GameStrings.captureCanceledOutOfBoundary, AlertType.error);
        onStateChanged();
        return;
      }
    }

    final hex = HexService.latLngToHex(_startLocation!);
    final tile = HexTile(
      id: _capturingTileId!,
      q: hex['q']!,
      r: hex['r']!,
      userId: _userId,
      colorHex: _colorHex,
      bounds: HexService.getHexCorners(hex['q']!, hex['r']!).map((l) => [l.latitude, l.longitude]).toList(),
      capturedAt: DateTime.now().toUtc(),
      captureCount: _targetCaptureCount, // 계산된 목표 점령 횟수를 데이터 모델에 주입
    );

    final success = await _supabase.captureTile(tile);
    if (success) {
      onTileCaptured(tile.id, tile, wasEnemyTile: _wasEnemyTile);
      onAlert(GameStrings.captureSuccessAlert, AlertType.success);
    } else {
      onAlert(GameStrings.captureFailedPreempted, AlertType.error);
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
