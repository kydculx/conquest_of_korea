import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/alert_model.dart';
import '../services/preferences_service.dart';
import '../models/tile_model.dart';
import '../services/supabase_service.dart';
import '../services/hex_service.dart';
import '../core/constants/game_config.dart';
import '../core/constants/strings.dart';

/// 위성 원격 점령의 진행 단계를 구분하는 상태 열거형
enum SatelliteCapturePhase {
  /// 대기 상태
  none,

  /// 본진에서 대상 타일까지 빔 화살표가 날아가는 상태
  flying,

  /// 빔 도착 후 타일을 점령(오렌지 게이지 누적) 중인 상태
  capturing,
}

/// 위성 원격 점령(Satellite Capture) 프로세스를 전담 제어하는 컨트롤러 클래스.
/// GameProvider로부터 위성 점령 관련 상태, 타이머, 경로 탐색 로직을 분리합니다.
class SatelliteCaptureController {
  // --- 콜백 (GameProvider에서 주입) ---

  /// 경고/성공 알림 이벤트를 메인 시스템에 전달하는 콜백
  final void Function(String message, AlertType type) onAlert;

  /// 위성 점령 완료 시 영토 데이터 갱신을 전달하는 콜백
  final void Function(String tileId, HexTile tile) onCaptureSuccess;

  /// 상태 변경 시 화면 갱신을 지시하는 콜백
  final VoidCallback onStateChanged;

  // --- 데이터 접근자 (순환 의존성 방지를 위해 GameProvider에서 주입) ---

  /// 현재 점령된 타일 맵을 반환하는 접근자
  final Map<String, HexTile> Function() getCapturedTiles;

  /// 현재 로그인된 요원의 ID를 반환하는 접근자
  final String? Function() getUserId;

  /// 현재 로그인된 요원의 전술 색상 Hex 코드를 반환하는 접근자
  final String? Function() getColorHex;

  /// 현재 로그인된 요원의 본진 타일 ID를 반환하는 접근자
  final String? Function() getMainBaseTileId;

  /// 현재 보유 골드를 반환하는 접근자
  final double Function() getCurrentGold;

  /// 낙관적 업데이트용 골드 차감 함수
  final double Function(double amount) deductGold;

  /// 현재 로그인된 요원의 ID를 반환하는 접근자 (getUserId와 동일하나 편의 제공)
  final String Function() getCurrentUserId;

  /// 프로필 정보를 서버에서 다시 로드하는 함수
  final Future<void> Function() refreshProfile;

  /// 물리 GPS 점령이 진행 중인지 확인하는 접근자
  final bool Function() isPhysicalCapturing;

  /// 물리 GPS 점령을 취소하는 함수
  final VoidCallback cancelPhysicalCapture;

  /// Supabase DB 서비스 인스턴스
  final SupabaseService _supabase;

  // --- 상태 필드 ---

  /// 현재 위성 점령의 상태 단계
  SatelliteCapturePhase _phase = SatelliteCapturePhase.none;

  /// 현재 위성 점령을 시도 중인 대상 타일 ID
  String? _capturingTileId;

  /// 위성 빔 비행 진행률 (0.0 ~ 1.0)
  double _travelProgress = 0.0;

  /// 위성 원격 타일 점령 진행률 (0.0 ~ 1.0)
  double _captureProgress = 0.0;

  /// 위성 점령 주기 업데이트 타이머
  Timer? _timer;

  /// 위성 점령 특정 단계(비행 또는 점령)를 시작한 일시
  DateTime? _phaseStartTime;

  /// 위성 빔 비행 완료에 소요되는 총 시간
  Duration? _travelDuration;

  /// 위성 타일 점령 완료에 소요되는 총 시간
  Duration? _captureDuration;

  /// 마지막으로 성공한 위성 점령 일시
  DateTime? _lastCaptureTime;

  /// 위성 점령 정보의 서버 저장 진행 여부
  bool _isSaving = false;

  // --- 생성자 ---

  SatelliteCaptureController({
    required SupabaseService supabase,
    required this.onAlert,
    required this.onCaptureSuccess,
    required this.onStateChanged,
    required this.getCapturedTiles,
    required this.getUserId,
    required this.getColorHex,
    required this.getMainBaseTileId,
    required this.getCurrentGold,
    required this.deductGold,
    required this.getCurrentUserId,
    required this.refreshProfile,
    required this.isPhysicalCapturing,
    required this.cancelPhysicalCapture,
  }) : _supabase = supabase;

  // --- 공개 Getters ---

  /// 현재 위성 점령의 상태 단계
  SatelliteCapturePhase get phase => _phase;

  /// 현재 위성 점령 진행 중인 타일 ID
  String? get capturingTileId => _capturingTileId;

  /// 위성 빔 비행 진행률 (0.0 ~ 1.0)
  double get travelProgress => _travelProgress;

  /// 위성 점령 진행률 (0.0 ~ 1.0)
  double get captureProgress => _captureProgress;

  /// 위성 점령 시도가 활성화 중인지 여부
  bool get isCapturing => _phase != SatelliteCapturePhase.none;

  /// 마지막으로 위성 점령에 성공한 일시
  DateTime? get lastCaptureTime => _lastCaptureTime;

  /// 위성 점령이 완료될 때까지 남은 초 단위 시간 (비행 시간과 점령 시간의 잔여분 합산)
  int get remainingSeconds {
    if (_phase == SatelliteCapturePhase.none || _phaseStartTime == null) {
      return 0;
    }
    final now = DateTime.now();
    if (_phase == SatelliteCapturePhase.flying) {
      final elapsed = now.difference(_phaseStartTime!);
      final remainingTravel =
          (_travelDuration!.inSeconds - elapsed.inSeconds)
              .clamp(0, double.infinity)
              .toInt();
      final remainingCapture = _captureDuration!.inSeconds;
      return remainingTravel + remainingCapture;
    } else {
      final elapsed = now.difference(_phaseStartTime!);
      final remainingCapture =
          (_captureDuration!.inSeconds - elapsed.inSeconds)
              .clamp(0, double.infinity)
              .toInt();
      return remainingCapture;
    }
  }

  /// 위성 조준 장비의 재충전 쿨타임 남은 시간 (초)
  int get remainingCoolSeconds {
    if (_lastCaptureTime == null) return 0;
    final diff = DateTime.now().difference(_lastCaptureTime!);
    final remaining =
        GameConfig.satelliteCaptureCooltime.inSeconds - diff.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  // --- 공개 메서드 ---

  /// 저장된 마지막 위성 점령 시간을 로드합니다.
  void loadLastCaptureTime(String? savedTime) {
    if (savedTime != null) {
      _lastCaptureTime = DateTime.parse(savedTime);
    }
  }

  /// 지정한 대상 헥사곤 타일에 대한 위성 연결 점령 타이머를 구동하여 점령을 실행합니다.
  void executeCapture(String tileId) {
    if (tileId.isEmpty || _isSaving) return;

    // 쿨타임 검증
    if (remainingCoolSeconds > 0) {
      onAlert(GameStrings.satelliteCooltimeAlert, AlertType.error);
      return;
    }

    final capturedTiles = getCapturedTiles();

    // 빈 타일 여부 검증 (이미 누군가가 점령했다면 불가능)
    final existingTile = capturedTiles[tileId];
    final isTileEmpty =
        existingTile == null ||
        existingTile.userId == null ||
        existingTile.userId == 'none';
    if (!isTileEmpty) {
      onAlert(GameStrings.satelliteAlreadyCapturedAlert, AlertType.error);
      return;
    }

    // 연결성 검증
    if (!checkConnectivity(tileId)) {
      onAlert(GameStrings.satelliteDisconnectedAlert, AlertType.error);
      return;
    }

    final mainBaseId = getMainBaseTileId();
    if (mainBaseId == null || mainBaseId.isEmpty) {
      onAlert(GameStrings.satelliteNoHQAlert, AlertType.error);
      return;
    }

    // 내 영토로부터의 최단 거리에 비례하여 점령 소요 시간 및 골드 비용 계산
    final dist = getTileDistance(tileId);

    // 위성 점령 소모 재화 부족 검증 (거리가 D이면 D GP 소모)
    if (getCurrentGold() < dist) {
      onAlert(
        GameStrings.satGoldShortageDetail(
          dist.toString(),
          getCurrentGold().toInt().toString(),
        ),
        AlertType.error,
      );
      return;
    }

    // 물리 GPS 점령 진행 중인 경우 중단
    if (isPhysicalCapturing()) {
      cancelPhysicalCapture();
    }

    cancelCapture();

    _capturingTileId = tileId;
    _phase = SatelliteCapturePhase.flying;
    _travelProgress = 0.0;
    _captureProgress = 0.0;
    _phaseStartTime = DateTime.now();
    _travelDuration = Duration(
      seconds: dist < 1 ? 1 : dist,
    );
    _captureDuration = Duration(
      milliseconds: (GameConfig.satelliteCaptureSecondsPerTile * 1000).toInt(),
    );

    _timer = Timer.periodic(
      const Duration(milliseconds: GameConfig.updateIntervalMs),
      (_) {
        if (_capturingTileId == null || _isSaving) return;

        final now = DateTime.now();
        if (_phase == SatelliteCapturePhase.flying) {
          final elapsed = now.difference(_phaseStartTime!);
          _travelProgress =
              (elapsed.inMilliseconds / _travelDuration!.inMilliseconds)
                  .clamp(0.0, 1.0);

          if (_travelProgress >= 1.0) {
            // 1단계 비행 완료 ➔ 2단계 실제 점령 모드로 순차 전환
            _phase = SatelliteCapturePhase.capturing;
            _phaseStartTime = now;
            _captureProgress = 0.0;
          }
          onStateChanged();
        } else if (_phase == SatelliteCapturePhase.capturing) {
          final elapsed = now.difference(_phaseStartTime!);
          _captureProgress =
              (elapsed.inMilliseconds / _captureDuration!.inMilliseconds)
                  .clamp(0.0, 1.0);

          if (_captureProgress >= 1.0) {
            _saveCapture(tileId);
          } else {
            onStateChanged();
          }
        }
      },
    );

    onStateChanged();
  }

  /// 현재 시도 중인 위성 원격 점령 지연 프로세스를 중단하고 취소합니다.
  void cancelCapture() {
    if (_isSaving) return;
    _timer?.cancel();
    _timer = null;
    _capturingTileId = null;
    _phase = SatelliteCapturePhase.none;
    _travelProgress = 0.0;
    _captureProgress = 0.0;
    _travelDuration = null;
    _captureDuration = null;
    _phaseStartTime = null;
    onStateChanged();
  }

  /// 리소스 해제
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  // --- 내부 메서드 ---

  /// 위성 점령 데이터 DB 저장 및 쿨타임 갱신
  Future<void> _saveCapture(String tileId) async {
    if (_isSaving) return;
    _isSaving = true;
    _timer?.cancel();

    final myId = getUserId();
    final myColor = getColorHex();

    if (myId == null || myColor == null) {
      onAlert(GameStrings.satelliteUserInvalid, AlertType.error);
      _isSaving = false;
      cancelCapture();
      return;
    }

    final parts = tileId.split('_');
    final q = int.tryParse(parts[1]) ?? 0;
    final r = int.tryParse(parts[2]) ?? 0;

    final capturedTiles = getCapturedTiles();
    final existing = capturedTiles[tileId];
    final targetCaptureCount = (existing?.captureCount ?? 0) + 1;

    final tile = HexTile(
      id: tileId,
      q: q,
      r: r,
      userId: myId,
      colorHex: myColor,
      capturedAt: DateTime.now().toUtc(),
      captureCount: targetCaptureCount,
    );

    final success = await _supabase.captureTile(tile);
    if (success) {
      _lastCaptureTime = DateTime.now();

      // 쿨타임 저장은 백그라운드 비동기로 처리
    PreferencesService.setLastSatelliteCaptureTime(
      _lastCaptureTime!.toIso8601String(),
    ).catchError((e) {
      debugPrint('PreferencesService 쿨타임 저장 실패: $e');
    });

      // 위성 점령에 소모된 거리 비례 골드 차감
      try {
        final mainBaseId = getMainBaseTileId();
        if (mainBaseId != null && mainBaseId.isNotEmpty) {
          final dist = getTileDistance(tileId);

          // 실시간 축적분이 담긴 최신 goldManager 기준으로 거리 차감 진행
          deductGold(dist.toDouble());

          // 차감된 골드 정보 백엔드 저장
          await _supabase.client.from('profiles').update({
            'gold': getCurrentGold(),
            'last_gold_updated_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('id', myId);
        }
      } catch (e) {
        debugPrint('⚠️ 위성 점령 재화 차감 중 오류 발생: $e');
      }

      onCaptureSuccess(tileId, tile);
      onAlert(GameStrings.satelliteCaptureSuccess, AlertType.success);

      // 위성 원격 점령 성공 시 푸시 알림 발송
      try {
        debugPrint('📡 위성 원격 점령 성공 푸시 알림 발송 요청 시작');
        _supabase.client.functions.invoke(
          'send-push',
          body: {
            'topic': 'user_$myId',
            'title': GameStrings.notifSatelliteCompleteTitle,
            'body': GameStrings.satelliteCaptureSuccess,
            'data_payload': {
              'type': 'satellite_complete',
            },
          },
        ).then((response) {
          debugPrint('🎯 위성 점령 푸시 알림 발송 결과: ${response.status}');
        }).catchError((e) {
          debugPrint('⚠️ 위성 점령 푸시 알림 발송 중 에러 발생: $e');
        });
      } catch (e) {
        debugPrint('⚠️ 위성 점령 푸시 알림 발송 예외 발생: $e');
      }

      // 프로필 갱신
      await refreshProfile();
    } else {
      final errMsg = _supabase.lastError != null
          ? ': ${_supabase.lastError}'
          : '';
      onAlert('${GameStrings.satelliteCaptureFail}$errMsg', AlertType.error);
    }

    _isSaving = false;
    _capturingTileId = null;
    _phase = SatelliteCapturePhase.none;
    _travelProgress = 0.0;
    _captureProgress = 0.0;
    _travelDuration = null;
    _captureDuration = null;
    _phaseStartTime = null;
    onStateChanged();
  }

  // --- 경로 탐색 메서드 ---

  /// 본진 기지에서 시작하여 플레이어가 소유한 타일망을 통해서만 이동하여 대상 타일까지 도달하는 최단 BFS 경로를 탐색합니다.
  List<String>? _findShortestPathToHQ(String targetTileId) {
    final mainBaseId = getMainBaseTileId();
    final myId = getUserId();
    final capturedTiles = getCapturedTiles();
    if (mainBaseId == null || mainBaseId.isEmpty || myId == null) {
      return null;
    }

    if (mainBaseId == targetTileId) {
      return [mainBaseId];
    }

    final partsTarget = targetTileId.split('_');
    if (partsTarget.length != 3 || partsTarget[0] != 'hex') return null;
    final tq = int.tryParse(partsTarget[1]);
    final tr = int.tryParse(partsTarget[2]);
    if (tq == null || tr == null) return null;

    final partsBase = mainBaseId.split('_');
    if (partsBase.length != 3 || partsBase[0] != 'hex') return null;
    final hqQ = int.tryParse(partsBase[1]);
    final hqR = int.tryParse(partsBase[2]);
    if (hqQ == null || hqR == null) return null;

    // BFS 큐: 각 원소는 경로의 타일 ID 리스트
    final queue = Queue<List<String>>()..add([mainBaseId]);
    final visited = <String>{mainBaseId};

    while (queue.isNotEmpty) {
      final path = queue.removeFirst();
      final currentId = path.last;

      if (currentId == targetTileId) {
        return path;
      }

      final partsCurr = currentId.split('_');
      if (partsCurr.length != 3 || partsCurr[0] != 'hex') continue;
      final cq = int.tryParse(partsCurr[1]);
      final cr = int.tryParse(partsCurr[2]);
      if (cq == null || cr == null) continue;

      for (final dir in HexService.hexDirections) {
        final nq = cq + dir[0];
        final nr = cr + dir[1];
        final neighborId = HexService.tileId(nq, nr);

        if (visited.contains(neighborId)) continue;

        // 대상 타일에 도달하면 즉시 경로 추가
        if (neighborId == targetTileId) {
          queue.add(List<String>.from(path)..add(neighborId));
          visited.add(neighborId);
          continue;
        }

        // 내 영토인지 여부
        final tile = capturedTiles[neighborId];
        final isMine = tile != null && tile.userId == myId;

        if (isMine) {
          queue.add(List<String>.from(path)..add(neighborId));
          visited.add(neighborId);
        }
      }
    }

    return null;
  }

  /// 대상 타일과 유저의 본진에서 출발하는 영토망을 따르는 최단 경로(점선 홉 수)를 계산하여 반환합니다.
  int getTileDistance(String targetTileId) {
    final path = _findShortestPathToHQ(targetTileId);
    if (path != null && path.length >= 2) {
      return path.length - 1;
    }

    // 폴백: 최단 경로가 없거나 예외 발생 시, 본진과의 물리 직선 거리를 반환
    final mainBaseId = getMainBaseTileId();
    if (mainBaseId == null || mainBaseId.isEmpty) return 0;

    final partsBase = mainBaseId.split('_');
    final bq = int.tryParse(partsBase[1]) ?? 0;
    final br = int.tryParse(partsBase[2]) ?? 0;

    final partsTarget = targetTileId.split('_');
    final tq = int.tryParse(partsTarget[1]) ?? 0;
    final tr = int.tryParse(partsTarget[2]) ?? 0;

    return HexService.hexDistance(bq, br, tq, tr);
  }

  /// 본진 기지를 시발점으로 하여 요원이 지배 중인 타일 그리드를 거쳐 대상 영토까지
  /// 끊어짐 없이 헥사 결합되어 연결되는지 BFS로 무결성을 검증합니다.
  bool checkConnectivity(String targetTileId) {
    final mainBaseId = getMainBaseTileId();
    final myId = getUserId();
    final capturedTiles = getCapturedTiles();
    if (mainBaseId == null || mainBaseId.isEmpty || myId == null) {
      return false;
    }

    // 대상 타일이 이미 내 소유이면 위성 점령이 불필요하므로 false
    final existingTile = capturedTiles[targetTileId];
    if (existingTile != null && existingTile.userId == myId) {
      return false;
    }

    // 내 점령지 타일 ID 셋 구성
    final myTiles = capturedTiles.values
        .where((t) => t.userId == myId)
        .map((t) => t.id)
        .toSet();

    // 본진 타일은 소유 여부와 관계없이 BFS 탐색을 위한 연결 통로로 강제 포함
    final effectiveMyTiles = {...myTiles, mainBaseId};

    // BFS 탐색을 통한 연결성 검증
    final queue = Queue<String>()..add(mainBaseId);
    final visited = <String>{mainBaseId};

    while (queue.isNotEmpty) {
      final currentId = queue.removeFirst();

      final parts = currentId.split('_');
      if (parts.length != 3 || parts[0] != 'hex') continue;
      final q = int.tryParse(parts[1]);
      final r = int.tryParse(parts[2]);
      if (q == null || r == null) continue;

      for (final dir in HexService.hexDirections) {
        final nq = q + dir[0];
        final nr = r + dir[1];
        final neighborId = HexService.tileId(nq, nr);

        if (neighborId == targetTileId) {
          return true;
        }

        if (effectiveMyTiles.contains(neighborId) &&
            !visited.contains(neighborId)) {
          visited.add(neighborId);
          queue.add(neighborId);
        }
      }
    }

    return false;
  }

  /// 내 영토와 대상 타일 간의 헥사곤 거리를 산출하여 위성 점령 완료에 소요될 지연 시간(초)을 계산합니다.
  int getCaptureDurationSeconds(String tileId) {
    final dist = getTileDistance(tileId);
    return dist + 1; // 점령 고유 소요시간 1초
  }

  /// 내 영토와 대상 타일 간의 거리를 기준으로 하여, 위성 점령의 총 시간 중 '이동(비행) 시간'이 차지하는 비율을 산출합니다.
  double getTravelRatio(String tileId) {
    final dist = getTileDistance(tileId).toDouble();
    final total = dist + 1.0; // 점령 고유 소요시간 1초
    return total > 0.0 ? (dist / total) : 0.8;
  }

  /// 지정한 타일이 본진 기지이거나 본진을 직간접으로 둘러싼 인접 1링(Ring) 범위에 포함되는지 확인합니다.
  bool isHQOr1Ring(String tileId) {
    final mainBaseId = getMainBaseTileId();
    if (mainBaseId == null || mainBaseId.isEmpty) return false;

    final partsTarget = tileId.split('_');
    if (partsTarget.length != 3 || partsTarget[0] != 'hex') return false;
    final tq = int.tryParse(partsTarget[1]);
    final tr = int.tryParse(partsTarget[2]);

    final partsBase = mainBaseId.split('_');
    if (partsBase.length != 3 || partsBase[0] != 'hex') return false;
    final bq = int.tryParse(partsBase[1]);
    final br = int.tryParse(partsBase[2]);

    if (tq == null || tr == null || bq == null || br == null) return false;

    final dist = HexService.hexDistance(tq, tr, bq, br);
    return dist <= 1;
  }
}
