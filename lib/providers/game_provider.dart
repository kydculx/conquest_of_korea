import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../controllers/capture_controller.dart';
import '../models/alert_model.dart';
import '../models/tile_model.dart';
import '../providers/location_provider.dart';
import '../services/hex_service.dart';
import '../services/supabase_service.dart';
import '../core/constants.dart';

/// 게임 핵심 상태 관리 Provider
/// 위치/나침반은 LocationProvider에 위임, 점령 로직은 CaptureController에 위임
class GameProvider extends ChangeNotifier {
  static const String _teamKey = 'conquest_selected_team';

  final SupabaseService _supabase;
  late final CaptureController _captureController;
  StreamSubscription<List<HexTile>>? _tilesStreamSub;

  // --- 상태 ---
  TileOwner? _selectedTeam;
  final Map<String, HexTile> _capturedTiles = {};
  final List<GameAlert> _alerts = [];
  bool _isInitialized = false;
  bool _isAutoCapture = false;
  int _currentMapStyleIndex = 0;

  // LocationProvider 참조 (위치 읽기 전용)
  LocationProvider? _locationProvider;

  // --- Getters ---
  TileOwner? get selectedTeam => _selectedTeam;
  Map<String, HexTile> get capturedTiles => Map.unmodifiable(_capturedTiles);
  List<GameAlert> get alerts => List.unmodifiable(_alerts);
  bool get isInitialized => _isInitialized;
  bool get isAutoCapture => _isAutoCapture;
  int get currentMapStyleIndex => _currentMapStyleIndex;
  MapStyle get currentMapStyle => GameConstants.mapStyles[_currentMapStyleIndex];
  bool get showMap => currentMapStyle.url.isNotEmpty;

  // CaptureController 위임 Getters
  String? get capturingTileId => _captureController.capturingTileId;
  double get captureProgress => _captureController.captureProgress;
  bool get isCapturing => _captureController.isCapturing;

  /// 실시간 점수 (팀별 점령 타일 수)
  Map<String, int> get score {
    int blue = 0, red = 0;
    for (final tile in _capturedTiles.values) {
      if (tile.owner == TileOwner.blue) blue++;
      if (tile.owner == TileOwner.red) red++;
    }
    return {'blue': blue, 'red': red};
  }

  /// 현재 위치에서 점령 가능 여부
  bool get canCapture {
    final loc = _locationProvider;
    if (loc == null || !loc.isGpsActive || loc.currentLocation == null) {
      return false;
    }
    if (_selectedTeam == null) return false;
    final hex = HexService.latLngToHex(loc.currentLocation!);
    final tileId = 'hex_${hex['q']}_${hex['r']}';
    return _capturedTiles[tileId]?.owner != _selectedTeam;
  }

  GameProvider({required SupabaseService supabase}) : _supabase = supabase {
    _captureController = CaptureController(
      supabase: supabase,
      onAlert: addAlert,
      onTileCaptured: (id, tile) {
        _capturedTiles[id] = tile;
        notifyListeners();
      },
      onStateChanged: notifyListeners,
    );
    _init();
  }

  /// LocationProvider 연결 (ProxyProvider에서 호출)
  void setLocationProvider(LocationProvider loc) {
    _locationProvider = loc;
  }

  Future<void> _init() async {
    try {
      final tiles = await _supabase.fetchAllCapturedTiles();
      for (final tile in tiles) {
        _capturedTiles[tile.id] = tile;
      }
    } catch (e) {
      debugPrint('초기 데이터 로드 실패: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }

    // 실시간 업데이트 구독
    _tilesStreamSub = _supabase.capturedTilesStream.listen(_onTilesUpdated);
  }

  void _onTilesUpdated(List<HexTile> tiles) {
    bool changed = false;
    for (final tile in tiles) {
      final oldOwner = _capturedTiles[tile.id]?.owner;
      if (_isInitialized && _selectedTeam != null && oldOwner != tile.owner) {
        if (oldOwner == _selectedTeam) {
          addAlert('경보! 아군 구역이 적에게 점령당했습니다!', AlertType.error);
          Vibration.vibrate(pattern: [0, 200, 100, 200]);
        } else if (tile.owner != _selectedTeam) {
          addAlert('적군이 새로운 구역을 확보했습니다.', AlertType.warn);
        }
      }
      _capturedTiles[tile.id] = tile;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// 위치 업데이트 시 자동 점령 처리 (GameScreen에서 LocationProvider 변경 시 호출)
  void onLocationUpdated() {
    if (!_isInitialized || _selectedTeam == null) return;
    final loc = _locationProvider;
    if (loc == null || !loc.isGpsActive || loc.currentLocation == null) return;

    final hex = HexService.latLngToHex(loc.currentLocation!);
    final tileId = 'hex_${hex['q']}_${hex['r']}';

    // 이미 내 팀 타일이면 점령 취소
    if (_capturedTiles[tileId]?.owner == _selectedTeam) {
      _captureController.cancelCapture();
      return;
    }

    // 자동 점령 모드이고, 다른 타일 점령 중이 아닐 때
    if (_isAutoCapture && _captureController.capturingTileId != tileId) {
      _captureController.startCapture(
        tileId: tileId,
        location: loc.currentLocation!,
        team: _selectedTeam!,
        isEnemyTile: _capturedTiles.containsKey(tileId),
      );
    }
  }

  /// 수동 점령 시작
  void startManualCapture() {
    final loc = _locationProvider;
    if (!canCapture || loc?.currentLocation == null) {
      if (loc == null || !loc.isGpsActive) {
        addAlert('GPS 신호가 없습니다.', AlertType.error);
      }
      return;
    }
    final hex = HexService.latLngToHex(loc!.currentLocation!);
    final tileId = 'hex_${hex['q']}_${hex['r']}';
    _captureController.startCapture(
      tileId: tileId,
      location: loc.currentLocation!,
      team: _selectedTeam!,
      isEnemyTile: _capturedTiles.containsKey(tileId),
    );
  }

  /// 자동/수동 모드 전환
  void toggleAutoCapture() {
    _isAutoCapture = !_isAutoCapture;
    addAlert(
      _isAutoCapture ? '자동 점령 모드 활성화' : '수동 점령 모드 활성화',
      AlertType.info,
    );
    notifyListeners();
  }

  /// 지도 스타일 순환
  void cycleMapStyle() {
    _currentMapStyleIndex =
        (_currentMapStyleIndex + 1) % GameConstants.mapStyles.length;
    addAlert('지도 변경: ${currentMapStyle.name}', AlertType.info);
    notifyListeners();
  }

  /// 팀 선택
  Future<void> setSelectedTeam(TileOwner team) async {
    _selectedTeam = team;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_teamKey, team.id);
    notifyListeners();
  }

  /// 서버 데이터 강제 갱신
  Future<void> refreshServerData() async {
    try {
      final tiles = await _supabase.fetchAllCapturedTiles();
      for (final tile in tiles) {
        _capturedTiles[tile.id] = tile;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('데이터 갱신 실패: $e');
    }
  }

  /// 전술 알림 추가 (5개 초과 시 가장 오래된 것 제거, 3초 후 자동 삭제)
  void addAlert(String message, AlertType type) {
    final alert = GameAlert.create(message: message, type: type);
    _alerts.insert(0, alert);
    if (_alerts.length > 5) _alerts.removeLast();
    notifyListeners();
    Timer(const Duration(seconds: 3), () => _removeAlert(alert.id));
  }

  void _removeAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    _tilesStreamSub?.cancel();
    _captureController.dispose();
    super.dispose();
  }
}
