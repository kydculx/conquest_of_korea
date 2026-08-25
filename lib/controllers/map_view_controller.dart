import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/map_config.dart';
import '../models/map_mode.dart';
import '../services/preferences_service.dart';

/// 지도 카메라 추적, 스타일, 회전 모드, 뷰 모드(일반/발자국/패턴) 상태를
/// 전담 관리하는 컨트롤러. GameProvider로부터 지도 뷰 상태 책임을 분리합니다.
class MapViewController {
  final VoidCallback _notifyListeners;

  /// 현재 적용 중인 지도 스타일 인덱스
  int _currentMapStyleIndex = 0;

  /// 지도 회전 모드(나침반 정렬) 사용 여부
  bool _isMapRotationMode = false;

  /// 지도 카메라가 플레이어의 GPS 실시간 위치를 추적하고 있는지 여부
  bool _isFollowingUser = true;

  /// 맵 뷰 모드 통합 관리 상태
  MapMode _mapMode = MapMode.normal;

  /// 지도 카메라 이동 요청을 중계하기 위한 브로드캐스트 스트림 컨트롤러
  final StreamController<LatLng> _mapMoveRequestController =
      StreamController<LatLng>.broadcast();

  int get currentMapStyleIndex => _currentMapStyleIndex;
  bool get isMapRotationMode => _isMapRotationMode;
  bool get isFollowingUser => _isFollowingUser;
  MapMode get mapMode => _mapMode;
  bool get isFootprintMode => _mapMode == MapMode.footprint;
  bool get showCompletedPatterns => _mapMode == MapMode.pattern;
  MapStyle get currentMapStyle => MapConfig.mapStyles[_currentMapStyleIndex];
  Stream<LatLng> get mapMoveRequests => _mapMoveRequestController.stream;

  MapViewController({required VoidCallback notifyListeners})
      : _notifyListeners = notifyListeners;

  /// 저장된 지도 설정(회전 모드)을 불러옵니다.
  Future<void> loadFromPrefs() async {
    _isMapRotationMode = await PreferencesService.isMapRotationMode();
  }

  /// 지도 카메라 이동을 요청합니다. 수동 이동 시 나침반 회전 모드를 해제합니다.
  void requestMapMove(LatLng destination) {
    // 🧭 수동 맵 카메라 이동(본진 이동, 패턴 조회 등) 시 나침반 회전 모드를 꺼서 불필요한 강제 회전 방지
    if (_isMapRotationMode) {
      _isMapRotationMode = false;
      PreferencesService.setMapRotationMode(false).catchError((e) {
        debugPrint('❌ MapRotationMode 저장 실패: $e');
      });
      _notifyListeners();
    }
    _mapMoveRequestController.add(destination);
  }

  void setFollowingUser(bool value) {
    if (_isFollowingUser != value) {
      _isFollowingUser = value;
      _notifyListeners();
    }
  }

  void toggleFollowingUser() {
    _isFollowingUser = !_isFollowingUser;
    _notifyListeners();
  }

  /// 다음 뷰 모드로 순환 전환합니다. 변경 알림은 발생하지 않으며,
  /// 이전 모드를 반환하므로 호출자가 후속 처리(선택 해제, 알림 표시)를 수행합니다.
  MapMode cycleModeQuiet() {
    final oldMode = _mapMode;
    switch (_mapMode) {
      case MapMode.normal:
        _mapMode = MapMode.footprint;
        break;
      case MapMode.footprint:
        _mapMode = MapMode.pattern;
        break;
      case MapMode.pattern:
        _mapMode = MapMode.normal;
        break;
    }
    return oldMode;
  }

  /// 완료 패턴 보기를 토글합니다. 변경 알림 없이 이전 모드를 반환합니다.
  MapMode toggleCompletedPatternsViewQuiet() {
    final oldMode = _mapMode;
    _mapMode =
        (_mapMode == MapMode.pattern) ? MapMode.normal : MapMode.pattern;
    return oldMode;
  }

  /// 발자국 보기를 토글합니다. 변경 알림 없이 이전 모드를 반환합니다.
  MapMode toggleFootprintModeQuiet() {
    final oldMode = _mapMode;
    _mapMode =
        (_mapMode == MapMode.footprint) ? MapMode.normal : MapMode.footprint;
    return oldMode;
  }

  void cycleMapStyle() {
    _currentMapStyleIndex =
        (_currentMapStyleIndex + 1) % MapConfig.mapStyles.length;
    _notifyListeners();
  }

  Future<void> toggleMapRotationMode() async {
    _isMapRotationMode = !_isMapRotationMode;
    _notifyListeners();
    PreferencesService.setMapRotationMode(_isMapRotationMode).catchError((e) {
      debugPrint('⚠️ 회전 모드 설정 저장 실패: $e');
    });
  }

  /// 리소스 해제
  void dispose() {
    _mapMoveRequestController.close();
  }
}
