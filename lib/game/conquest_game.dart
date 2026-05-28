import 'dart:ui';
import 'package:flame/game.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'components/player_component.dart';
import 'components/hex_tile_component.dart';
import 'components/hq_base_marker.dart';
import 'components/scan_target_marker.dart';
import '../services/hex_service.dart';
import '../models/tile_model.dart';
import '../providers/game_provider.dart';
import '../core/constants/colors.dart';

/// Flame 게임 엔진을 상속받아 인게임 전술 지도상에 헥사곤 타일 영역, 요원의 물리 위치 마커, 본부 기지(HQ), 위성 조준 마커 등을 렌더링하고 업데이트를 감시하는 커스텀 게임 엔진 클래스
class ConquestGame extends FlameGame {
  /// 요원 본인을 지도 상에 나타내는 2D 방향 컴포넌트
  late PlayerComponent player;

  /// 화면 좌표와 지도 좌표 간 변환(투영)을 수행하는 FlutterMap 지도 컨트롤러 캐시 객체
  MapController? _mapController;

  /// 마지막으로 전달받은 서버 기준 점령 타일 목록 캐시
  Map<String, HexTile> _lastCapturedTiles = {};

  /// 렌더링에 사용 중인 Flame 컴포넌트 맵 (Key: 타일 ID, Value: 헥사곤 컴포넌트)
  final Map<String, HexTileComponent> _tileMap = {};

  /// 본부 기지(HQ) 아이콘 및 링 반경 연출을 시각화하는 마커 컴포넌트
  HQBaseMarker? _hqMarker;

  /// 위성 궤도 스캔 시 락온(Lock-on) 연출 및 게이지를 그리는 조준마커 컴포넌트
  ScanTargetMarker? _scanTargetMarker;

  /// 현재 설정된 요원의 본부 기지(HQ) 타일 ID
  String? _currentHQTileId;

  /// 최근에 점령 시도에 사용된 전술 식별 색상 코드
  String? _lastCapturingColorHex;

  /// 현재 위성 궤도 스캔 조준 장치 활성화 여부 상태 캐시
  bool _isScanMode = false;

  /// 현재 로그인된 요원의 ID 정보 캐시
  String? _currentUserId;

  /// 현재 위성 원격 타일 점령이 진행 중인지 여부 상태 캐시
  /// 현재 위성 원격 타일 점령이 진행 중인지 여부 상태 캐시
  bool _isSatelliteCapturing = false;

  /// 현재 위성 점령의 상태 단계
  SatelliteCapturePhase _satelliteCapturePhase = SatelliteCapturePhase.none;

  /// 현재 위성 빔 비행 진행률 (0.0 ~ 1.0)
  double _satelliteTravelProgress = 0.0;

  /// 현재 위성 점령의 게이지 진행률 (0.0 ~ 1.0)
  double _satelliteCaptureProgress = 0.0;

  /// 위성 점령을 개시한 대상 타일 ID 캐시
  String? _satelliteCapturingTileId;

  /// 투영을 담당하는 내부 맵 컨트롤러 반환
  MapController? get mapController => _mapController;

  /// 본부 기지가 설치된 타일 ID 반환
  String? get currentHQTileId => _currentHQTileId;

  /// 현재 사용자 ID 반환
  String? get currentUserId => _currentUserId;

  /// 최근 서버 데이터 기준 캐싱된 전체 점령지 맵 반환
  Map<String, HexTile> get lastCapturedTiles => _lastCapturedTiles;

  /// 현재 위성 점령이 활성화되어 시도 중인지 여부
  bool get isSatelliteCapturing => _isSatelliteCapturing;

  /// 현재 위성 점령의 상태 단계 반환
  SatelliteCapturePhase get satelliteCapturePhase => _satelliteCapturePhase;

  /// 위성 빔 비행 진행률 반환
  double get satelliteTravelProgress => _satelliteTravelProgress;

  /// 위성 점령의 퍼센트 수치 반환
  double get satelliteCaptureProgress => _satelliteCaptureProgress;

  /// 위성 점령 중인 목적지 타일 ID 반환
  String? get satelliteCapturingTileId => _satelliteCapturingTileId;

  /// 위성 궤도 조준경 모드 사용 여부
  bool get isScanMode => _isScanMode;

  /// 최근에 점령 시도에 사용된 전술 식별 색상 코드
  String? get lastCapturingColorHex => _lastCapturingColorHex;

  @override
  Color backgroundColor() => GameColors.transparent;

  @override
  Future<void> onLoad() async {
    player = PlayerComponent()..priority = 20;
    player.isVisible = !_isScanMode;
    add(player);

    if (_mapController != null) _updateAllPositions();
  }

  /// 프레임 갱신 주기를 제어하기 위해 누적 보관하는 델타 타임 합산 값
  double _dtSum = 0.0;

  /// 프레임 오차를 방지하고 연산을 규격화하기 위해 60 FPS 주기로 강제하는 고정 타임 기준값 (1/60초)
  static const double _fixedDeltaTime = 1 / 60; // 60 FPS 강제 제한

  /// Flame 엔진의 생명주기 갱신 콜백으로, 고정 델타 타임을 기반으로 하여 컴포넌트 트리를 규칙적으로 갱신합니다.
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
    if (_tileMap.isEmpty && _lastCapturedTiles.isNotEmpty) {
      updateCapturedTiles(
        capturedTiles: _lastCapturedTiles,
        mainBaseTileId: _currentHQTileId,
        selectedScanTileId: _scanTargetMarker != null
            ? 'hex_${_scanTargetMarker!.q}_${_scanTargetMarker!.r}'
            : null,
        isScanMode: _scanTargetMarker != null,
        capturingColorHex: _lastCapturingColorHex,
        currentUserId: _currentUserId,
        isSatelliteCapturing: _isSatelliteCapturing,
        satelliteCapturePhase: _satelliteCapturePhase,
        satelliteTravelProgress: _satelliteTravelProgress,
        satelliteCaptureProgress: _satelliteCaptureProgress,
      );
    } else {
      _updateAllPositions();
    }
  }

  /// 점령 타일 렌더링 업데이트 (복구)
  void updateCapturedTiles({
    required Map<String, HexTile> capturedTiles,
    String? capturingTileId,
    double captureProgress = 0.0,
    String? capturingColorHex,
    LatLng? currentLocation,
    String? mainBaseTileId,
    String? selectedScanTileId,
    bool isScanMode = false,
    String? currentUserId,
    bool isSatelliteCapturing = false,
    SatelliteCapturePhase satelliteCapturePhase = SatelliteCapturePhase.none,
    double satelliteTravelProgress = 0.0,
    double satelliteCaptureProgress = 0.0,
    String? satelliteCapturingTileId,
  }) {
    _lastCapturedTiles = capturedTiles;
    _lastCapturingColorHex = capturingColorHex;
    _isScanMode = isScanMode;
    _currentUserId = currentUserId;
    _isSatelliteCapturing = isSatelliteCapturing;
    _satelliteCapturePhase = satelliteCapturePhase;
    _satelliteTravelProgress = satelliteTravelProgress;
    _satelliteCaptureProgress = satelliteCaptureProgress;
    _satelliteCapturingTileId = satelliteCapturingTileId;
    if (isLoaded) {
      player.isVisible = !isScanMode;
    }
    _updateHQMarker(mainBaseTileId, capturingColorHex);
    _updateScanTargetMarker(selectedScanTileId, isScanMode);
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
      // 내 타일은 자신이 선택한 고유 색상(data.colorHex), 상대 타일은 전역 고정 회색으로 처리
      final targetTileColorHex = (data.userId == _currentUserId)
          ? (data.colorHex ?? '#00E5FF')
          : GameColors.enemyTileColorHex;

      if (_tileMap.containsKey(id)) {
        _tileMap[id]!.updateData(
          colorHex: targetTileColorHex,
          corners: screenCorners,
        );
      } else {
        final tile = HexTileComponent(
          colorHex: targetTileColorHex,
          corners: screenCorners,
        )..priority = 0;
        _tileMap[id] = tile;
        add(tile);
      }
    });

    // 점령 중인 타일 특수 상태 처리 (일반 점령)
    if (capturingTileId != null) {
      _updateActiveCaptureTile(
        tileId: capturingTileId,
        progress: captureProgress,
        colorHex: capturingColorHex,
        isCapturing: true,
        fallbackLocation: currentLocation,
      );
    }

    // 점령 중인 타일 특수 상태 처리 (위성 점령)
    if (isSatelliteCapturing && satelliteCapturingTileId != null) {
      final bool shouldAnimateTile =
          _satelliteCapturePhase == SatelliteCapturePhase.capturing;
      _updateActiveCaptureTile(
        tileId: satelliteCapturingTileId,
        progress: shouldAnimateTile ? _satelliteCaptureProgress : 0.0,
        colorHex: capturingColorHex,
        isCapturing: shouldAnimateTile,
      );
    }

    // 점령 중이 아닌 타일 상태 초기화
    _tileMap.forEach((id, tile) {
      final isStillCapturing =
          id == capturingTileId ||
          (isSatelliteCapturing && id == satelliteCapturingTileId);
      if (!isStillCapturing && tile.isCapturing) {
        tile.updateData(isCapturing: false, progress: 0.0);
      }
    });
  }

  /// 점령이 진행 중인 특정 타일(일반 물리 점령 및 위성 원격 점령 공용)의
  /// 실시간 점령 게이지 데이터 및 펄싱 여부를 동적으로 렌더링하고 동기화합니다.
  /// 맵에 존재하지 않는 중립 구역인 경우, ID 정보를 역산하여 임시 꼭짓점 좌표를 즉각 투영 렌더링합니다.
  void _updateActiveCaptureTile({
    required String tileId,
    required double progress,
    required String? colorHex,
    required bool isCapturing,
    LatLng? fallbackLocation,
  }) {
    if (_tileMap.containsKey(tileId)) {
      _tileMap[tileId]!.updateData(
        isCapturing: isCapturing,
        progress: progress,
        capturingColorHex: colorHex,
      );
    } else {
      // 맵에 존재하지 않는 중립 구역인 경우
      int? q;
      int? r;
      final parts = tileId.split('_');
      if (parts.length == 3 && parts[0] == 'hex') {
        q = int.tryParse(parts[1]);
        r = int.tryParse(parts[2]);
      } else if (fallbackLocation != null) {
        final hex = HexService.latLngToHex(fallbackLocation);
        q = hex['q'];
        r = hex['r'];
      }

      if (q != null && r != null) {
        final screenCorners = _calcScreenCorners(q, r);
        final tempTile = HexTileComponent(
          colorHex: null,
          corners: screenCorners,
          isCapturing: isCapturing,
          progress: progress,
          capturingColorHex: colorHex,
        )..priority = 0;
        _tileMap[tileId] = tempTile;
        add(tempTile);
      }
    }
  }

  /// 지도의 특정 헥사곤 좌표(q, r)의 외각 6개 꼭짓점을 디바이스 스크린 픽셀 좌표(Offset) 목록으로 맵핑하여 계산합니다.
  List<Offset> _calcScreenCorners(int q, int r) {
    final corners = HexService.getHexCorners(q, r);
    return corners.map((latlng) {
      final offset = _mapController!.camera.latLngToScreenOffset(latlng);
      return Offset(offset.dx, offset.dy);
    }).toList();
  }

  /// 화면 스크린 변화 감지 시 렌더링 중인 플레이어 및 타일 컴포넌트들의 스크린 좌표를 일괄 재계산하여 이동시킵니다.
  void _updateAllPositions() {
    if (_mapController == null) return;

    // 타일 위치 갱신
    _tileMap.forEach((id, tile) {
      final data = _lastCapturedTiles[id];
      if (data != null) {
        tile.updateData(corners: _calcScreenCorners(data.q, data.r));
      } else {
        // 임시 점령 중인 중립 타일인 경우 ID에서 q, r을 직접 파싱하여 맵 프로젝션 좌표 실시간 동기화
        final parts = id.split('_');
        if (parts.length == 3 && parts[0] == 'hex') {
          final q = int.tryParse(parts[1]);
          final r = int.tryParse(parts[2]);
          if (q != null && r != null) {
            tile.updateData(corners: _calcScreenCorners(q, r));
          }
        }
      }
    });

    // 플레이어 위치 갱신
    if (isLoaded) {
      player.isVisible = !_isScanMode;
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
    if (isLoaded) player.updateHeading(heading);
  }

  /// 요원의 현재 지도 GPS 위치(LatLng)를 기반으로 하여 디바이스 화면 상의 픽셀 좌표값으로 최종 정렬시킵니다.
  void _updatePlayerScreenPosition() {
    if (_mapController != null) {
      final offset = _mapController!.camera.latLngToScreenOffset(
        player.location,
      );
      player.updateScreenPosition(Offset(offset.dx, offset.dy));
    }
  }

  /// 본부 기지(HQ) 설정 변화를 탐지하여 이전에 설치된 마커를 파기하거나 신규 생성 및 색상 갱신을 진행합니다.
  void _updateHQMarker(String? newHQTileId, String? colorHex) {
    if (_currentHQTileId == newHQTileId) {
      _hqMarker?.updateColor(colorHex);
      return;
    }

    _currentHQTileId = newHQTileId;
    if (_hqMarker != null) {
      remove(_hqMarker!);
      _hqMarker = null;
    }

    if (newHQTileId != null && newHQTileId.isNotEmpty) {
      final parts = newHQTileId.split('_');
      if (parts.length == 3 && parts[0] == 'hex') {
        final q = int.tryParse(parts[1]);
        final r = int.tryParse(parts[2]);
        if (q != null && r != null) {
          _hqMarker = HQBaseMarker(q: q, r: r, colorHex: colorHex);
          add(_hqMarker!);
        }
      }
    }
  }

  /// 위성 궤도 스캔 조준 상태 혹은 진행 중인 위성 점령 타일에 타겟 링 마커를 바인딩하고 좌표를 갱신합니다.
  void _updateScanTargetMarker(String? selectedScanTileId, bool isScanMode) {
    int? targetQ;
    int? targetR;

    // 위성 점령이 진행 중일 때는 위성 모드가 꺼져 있어도 마커를 계속 유지함
    final activeTileId = _isSatelliteCapturing
        ? _satelliteCapturingTileId
        : (isScanMode ? selectedScanTileId : null);

    if (activeTileId != null && activeTileId.isNotEmpty) {
      final parts = activeTileId.split('_');
      if (parts.length == 3 && parts[0] == 'hex') {
        targetQ = int.tryParse(parts[1]);
        targetR = int.tryParse(parts[2]);
      }
    }

    if (_scanTargetMarker != null) {
      // 이미 같은 타일의 마커가 조준되어 있다면 새로 삭제/생성하지 않고 재사용함
      if (targetQ != null &&
          targetR != null &&
          _scanTargetMarker!.q == targetQ &&
          _scanTargetMarker!.r == targetR) {
        return;
      }
      remove(_scanTargetMarker!);
      _scanTargetMarker = null;
    }

    if (targetQ != null && targetR != null) {
      _scanTargetMarker = ScanTargetMarker(q: targetQ, r: targetR);
      add(_scanTargetMarker!);
    }
  }
}
