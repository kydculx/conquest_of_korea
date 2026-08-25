import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../services/hex_service.dart';

/// 위성 조회(스캔) 대상 타일과 발자국 조회 타일의 선택 상태를 전담 관리하는 컨트롤러.
/// GameProvider로부터 타일 선택 상태 책임을 분리합니다.
class TileSelectionController {
  final VoidCallback _notifyListeners;
  final bool Function() _isAuthenticated;

  /// 스캔 타일 선택 직후 서버 최신 정보 패치가 필요할 때 호출되는 콜백
  final void Function(String tileId)? onScanTileSelected;

  // --- 위성 스캔 상태 ---
  bool _isScanMode = false;
  String? _selectedScanTileId;
  LatLng? _selectedScanTileLatLng;

  // --- 발자취 선택 상태 ---
  String? _selectedFootprintTileId;
  LatLng? _selectedFootprintTileLatLng;

  bool get isScanModeActive => _isScanMode;
  String? get selectedScanTileId => _selectedScanTileId;
  LatLng? get selectedScanTileLatLng => _selectedScanTileLatLng;
  String? get selectedFootprintTileId => _selectedFootprintTileId;
  LatLng? get selectedFootprintTileLatLng => _selectedFootprintTileLatLng;

  TileSelectionController({
    required VoidCallback notifyListeners,
    required bool Function() isAuthenticated,
    this.onScanTileSelected,
  })  : _notifyListeners = notifyListeners,
        _isAuthenticated = isAuthenticated;

  /// 스캔 모드 토글 (모드 전환 시 선택 중인 타일 해제)
  void toggleScanMode() {
    _isScanMode = !_isScanMode;
    _selectedScanTileId = null;
    _notifyListeners();
  }

  /// 스캔 대상 타일 선택/해제. 선택 즉시 서버 최신 정보 패치를 요청합니다.
  void selectScanTile(String tileId) {
    if (!_isAuthenticated()) return;

    if (_selectedScanTileId == tileId) {
      clearScanSelectionQuietly();
      _notifyListeners();
    } else {
      _selectedScanTileId = tileId;
      _selectedScanTileLatLng = parseTileCenter(tileId);
      _notifyListeners();

      onScanTileSelected?.call(tileId);
    }
  }

  /// 발자국 조회 대상 타일 선택/해제
  void selectFootprintTile(String tileId) {
    if (_selectedFootprintTileId == tileId) {
      _selectedFootprintTileId = null;
      _selectedFootprintTileLatLng = null;
    } else {
      _selectedFootprintTileId = tileId;
      _selectedFootprintTileLatLng = parseTileCenter(tileId);
    }
    _notifyListeners();
  }

  /// 발자국 선택 해제 (변경 알림 포함)
  void clearSelectedFootprint() {
    _selectedFootprintTileId = null;
    _selectedFootprintTileLatLng = null;
    _notifyListeners();
  }

  /// 발자국 선택 해제 (변경 알림 없음 — 모드 전환 시 묶음 알림 처리용)
  void clearSelectedFootprintQuietly() {
    _selectedFootprintTileId = null;
    _selectedFootprintTileLatLng = null;
  }

  /// 스캔 선택 해제 (변경 알림 없음)
  void clearScanSelectionQuietly() {
    _selectedScanTileId = null;
    _selectedScanTileLatLng = null;
  }

  /// 로그아웃 시 스캔 관련 상태 초기화
  void resetScanState() {
    _isScanMode = false;
    _selectedScanTileId = null;
    _selectedScanTileLatLng = null;
  }

  /// 'hex_{q}_{r}' 형식 타일 ID의 중심 좌표를 반환합니다. 파싱 실패 시 null.
  static LatLng? parseTileCenter(String tileId) {
    final parts = tileId.split('_');
    if (parts.length == 3) {
      final q = int.tryParse(parts[1]);
      final r = int.tryParse(parts[2]);
      if (q != null && r != null) {
        return HexService.hexToLatLng(q, r);
      }
    }
    return null;
  }
}
