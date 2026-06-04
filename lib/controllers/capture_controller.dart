import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibration/vibration.dart';
import '../models/tile_model.dart';
import '../services/supabase_service.dart';
import '../services/hex_service.dart';
import '../core/constants/game_config.dart';
import '../core/constants/strings.dart';
import '../models/alert_model.dart';

/// 요원이 특정 헥사곤 타일 영역에 물리적으로 머물며 점령을 시도하는 프로세스를 감시 및 제어하는 컨트롤러 클래스
class CaptureController {
  /// DB 처리를 위한 Supabase 서비스 인스턴스
  final SupabaseService _supabase;

  /// 경고/성공 알림 이벤트를 메인 시스템에 전달하는 콜백
  final void Function(String message, AlertType type) onAlert;

  /// 점령 완료 시 영토 데이터 갱신을 전달하는 콜백
  final void Function(String tileId, HexTile tile, {required bool wasEnemyTile})
  onTileCaptured;

  /// 점령 완료 프로세스 직전(DB에 쓰기 전) 골드를 먼저 정산해줄 비동기 콜백
  final Future<void> Function()? onPreCapture;

  /// 상태 변경 시 화면 갱신을 지시하는 콜백
  final VoidCallback onStateChanged;

  /// 현재 점령 작전을 수행 중인 대상 타일 ID
  String? _capturingTileId;

  /// 점령을 시도하고 있는 요원 ID
  String? _userId;

  /// 점령 개시 시점의 물리적 GPS 위치
  LatLng? _startLocation;

  /// 요원의 전술 식별 색상 코드 (Hex)
  String? _colorHex;

  /// 점령이 시작된 일시
  DateTime? _startTime;

  /// 점령 완료에 소요되는 총 시간
  Duration? _targetDuration;

  /// 점령 성공 시 설정될 타일의 누적 점령 횟수 목표치
  int _targetCaptureCount = 1;

  /// 물리적 영토 점령 진행 진척도 (0.0 ~ 1.0)
  double _captureProgress = 0.0;

  /// 점령 시작 시점에 해당 타일이 상대방 소유였는지 여부
  bool _wasEnemyTile = false;

  /// 점령 상태(진행도 및 경계 이탈)를 주기적으로 갱신하기 위한 타이머
  Timer? _captureTimer;

  /// 점령 성공 후 서버에 정보 저장 API를 전송 중인지 여부
  bool _isSaving = false;

  /// 현재 물리 점령을 시도 중인 타일 ID를 반환합니다.
  String? get capturingTileId => _capturingTileId;

  /// 점령 중인 요원의 전술 식별 색상 코드
  String? get capturingColorHex => _colorHex;

  /// 물리 점령 진척도를 반환합니다. (0.0 ~ 1.0)
  double get captureProgress => _captureProgress;

  /// 현재 물리 점령 작전이 진행 중인지 여부를 반환합니다.
  bool get isCapturing => _capturingTileId != null;

  /// CaptureController 생성자로 서비스 의존성 및 콜백 리스너들을 주입받습니다.
  CaptureController({
    required SupabaseService supabase,
    required this.onAlert,
    required this.onTileCaptured,
    required this.onStateChanged,
    this.onPreCapture,
  }) : _supabase = supabase;

  /// 요원이 획득하고자 하는 특정 타일에 진입하여 점령 작전을 개시하고 주기 감시 타이머를 시작합니다.
  void startCapture({
    required String tileId,
    required LatLng location,
    required String userId,
    required String colorHex,
    required Duration duration,
    required int targetCaptureCount, // 목표 점령 횟수 인자 추가
    bool wasEnemyTile = false, // 상대방 구역 여부
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
    _captureTimer = Timer.periodic(
      const Duration(milliseconds: GameConfig.updateIntervalMs),
      (_) => checkCaptureStatus(),
    );
  }

  /// 지정 주기로 점령 상태를 추적하여 진행률을 연동하고, 위치 이탈 여부 및 점령 완료를 판정합니다.
  void checkCaptureStatus([LatLng? currentLocation]) {
    if (_capturingTileId == null || _isSaving) return;

    // [신규] 실시간 GPS 위치가 공급되었고, 그 위치의 타일ID가 시작 시 타일ID와 다르면 점령 즉시 취소!
    if (currentLocation != null) {
      final currentHex = HexService.latLngToHex(currentLocation);
      final currentTileId = HexService.tileId(currentHex['q']!, currentHex['r']!);
      if (currentTileId != _capturingTileId) {
        cancelCapture();
        onAlert(GameStrings.captureCanceledOutOfBoundary, AlertType.error);
        return;
      }
    }

    final elapsed = DateTime.now().difference(_startTime!);
    _captureProgress =
        (elapsed.inMilliseconds / _targetDuration!.inMilliseconds).clamp(
          0.0,
          1.0,
        );

    if (_captureProgress >= 1.0) {
      _saveCapture(currentLocation);
    } else {
      onStateChanged();
    }
  }

  /// 진행 중인 점령 작업을 파기하고 진행도를 0으로 초기화합니다.
  void cancelCapture() {
    if (_isSaving) return;
    _captureTimer?.cancel();
    _captureTimer = null;
    _capturingTileId = null;
    _captureProgress = 0.0;
    onStateChanged();
  }

  /// 점령이 완료된 타일 정보(위치, 경계 좌표, 소유자 색상 등)를 직렬화하여 Supabase DB에 적재합니다.
  Future<void> _saveCapture(LatLng? currentLocation) async {
    if (_isSaving) return;
    _isSaving = true;
    _captureTimer?.cancel();
    _vibrate(500);

    // [신규] 최종 저장 시점에도 현재 실시간 위치의 타일ID가 시작 시 타일ID와 동일한지 크로스 검증!
    if (currentLocation != null) {
      final currentHex = HexService.latLngToHex(currentLocation);
      final currentTileId = HexService.tileId(currentHex['q']!, currentHex['r']!);
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
      capturedAt: DateTime.now().toUtc(),
      captureCount: _targetCaptureCount, // 계산된 목표 점령 횟수를 데이터 모델에 주입
    );

    // [신규] DB에 점령 레코드를 쓰기 전에, 실시간 골드를 소수점 정밀도로 선제 정산하여 트리거 리셋 유실 방지
    if (onPreCapture != null) {
      try {
        await onPreCapture!();
      } catch (e) {
        debugPrint('⚠️ 점령 전 골드 정산 실패 (계속 진행): $e');
      }
    }

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

  /// 디바이스 진동 모터를 동작시켜 영토 전술 피드백을 전달합니다.
  void _vibrate(dynamic pattern) {
    try {
      Vibration.hasVibrator().then((has) {
        if (has == true) {
          if (pattern is List<int>) Vibration.vibrate(pattern: pattern);
          if (pattern is int) Vibration.vibrate(duration: pattern);
        }
      }).catchError((e) {
        debugPrint('⚠️ 진동 실행 실패: $e');
      });
    } catch (e) {
      debugPrint('⚠️ 진동 확인 실패: $e');
    }
  }

  /// 점령 컨트롤러 리소스 해제 시 점령 상태 모니터링 타이머를 중단합니다.
  void dispose() => _captureTimer?.cancel();
}
