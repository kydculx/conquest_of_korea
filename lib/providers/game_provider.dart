import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/capture_controller.dart';
import '../models/alert_model.dart';
import '../models/tile_model.dart';
import '../providers/location_provider.dart';
import '../services/hex_service.dart';
import '../services/supabase_service.dart';
import '../core/constants.dart';

/// 게임 핵심 상태 관리 Provider
class GameProvider extends ChangeNotifier {
  static const String _teamKey = 'conquest_selected_team';

  final SupabaseService _supabase;
  late final CaptureController _captureController;
  StreamSubscription<List<HexTile>>? _tilesStreamSub;

  // --- 상태 ---
  TileOwner? _selectedTeam;
  final Map<String, HexTile> _capturedTiles = {};
  final Map<String, int> _score = {'blue': 0, 'red': 0};
  final List<GameAlert> _alerts = [];
  bool _isInitialized = false;
  bool _isAutoCapture = false;
  int _currentMapStyleIndex = 0;

  // LocationProvider 참조
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

  String? get capturingTileId => _captureController.capturingTileId;
  double get captureProgress => _captureController.captureProgress;
  bool get isCapturing => _captureController.isCapturing;
  Map<String, int> get score => Map.unmodifiable(_score);

  bool get canCapture {
    final loc = _locationProvider;
    if (loc == null || !loc.isGpsActive || loc.currentLocation == null) return false;
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

  void setLocationProvider(LocationProvider loc) {
    _locationProvider = loc;
  }

  Future<void> _init() async {
    try {
      final tiles = await _supabase.fetchAllCapturedTiles();
      for (final tile in tiles) {
        _capturedTiles[tile.id] = tile;
      }
      _recalculateScore();
    } catch (e) {
      debugPrint('초기 데이터 로드 실패: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
    _tilesStreamSub = _supabase.capturedTilesStream.listen(_onTilesUpdated);
  }

  void _onTilesUpdated(List<HexTile> tiles) {
    bool changed = false;
    for (final tile in tiles) {
      _capturedTiles[tile.id] = tile;
      changed = true;
    }
    if (changed) {
      _recalculateScore();
      notifyListeners();
    }
  }

  void _recalculateScore() {
    int blue = 0, red = 0;
    for (final tile in _capturedTiles.values) {
      if (tile.owner == TileOwner.blue) blue++;
      if (tile.owner == TileOwner.red) red++;
    }
    _score['blue'] = blue;
    _score['red'] = red;
  }

  void onLocationUpdated() {
    if (!_isInitialized || _selectedTeam == null) return;
    final loc = _locationProvider;
    if (loc == null || !loc.isGpsActive || loc.currentLocation == null) return;

    final hex = HexService.latLngToHex(loc.currentLocation!);
    final tileId = 'hex_${hex['q']}_${hex['r']}';

    if (_capturedTiles[tileId]?.owner == _selectedTeam) {
      _captureController.cancelCapture();
      return;
    }

    if (_isAutoCapture && _captureController.capturingTileId != tileId) {
      _captureController.startCapture(
        tileId: tileId,
        location: loc.currentLocation!,
        team: _selectedTeam!,
        isEnemyTile: _capturedTiles.containsKey(tileId),
      );
    }
  }

  void startManualCapture() {
    final loc = _locationProvider;
    if (!canCapture || loc?.currentLocation == null) return;
    final hex = HexService.latLngToHex(loc!.currentLocation!);
    final tileId = 'hex_${hex['q']}_${hex['r']}';
    _captureController.startCapture(
      tileId: tileId,
      location: loc.currentLocation!,
      team: _selectedTeam!,
      isEnemyTile: _capturedTiles.containsKey(tileId),
    );
  }

  void toggleAutoCapture() {
    _isAutoCapture = !_isAutoCapture;
    notifyListeners();
  }

  void cycleMapStyle() {
    _currentMapStyleIndex = (_currentMapStyleIndex + 1) % GameConstants.mapStyles.length;
    notifyListeners();
  }

  Future<void> setSelectedTeam(TileOwner team) async {
    _selectedTeam = team;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_teamKey, team.id);
    notifyListeners();
  }

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
