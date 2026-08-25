import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/game_config.dart';
import '../models/alert_model.dart';
import '../models/user_coin.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../services/audio_service.dart';
import '../services/hex_service.dart';
import '../services/preferences_service.dart';
import '../services/supabase_service.dart';

/// 동전 아이템의 생성, 수집, 서버 동기화를 전담 관리하는 매니저 클래스.
/// GameProvider로부터 동전 시스템 책임을 분리합니다.
class CoinManager {
  final SupabaseService _supabase;
  final AuthProvider? Function() _getAuthProvider;
  final LocationProvider? Function() _getLocationProvider;
  final VoidCallback _notifyListeners;

  /// 동전 획득 알림 표시용 콜백
  final void Function(String message, AlertType type) _onAlert;

  /// 동전 획득 성공 후 후속 처리(골드 재동기화 등)용 콜백
  final Future<void> Function()? _onCoinCollected;

  List<UserCoin> _coins = [];

  /// 동전 재생성이 비동기적으로 중복 실행되는 것을 방지하는 뮤텍스 락 플래그
  bool _isRegeneratingCoins = false;

  /// 오늘 생성된 동전 목록 (수집 여부 포함)
  List<UserCoin> get coins => List.unmodifiable(_coins);

  CoinManager({
    required SupabaseService supabase,
    required AuthProvider? Function() getAuthProvider,
    required LocationProvider? Function() getLocationProvider,
    required VoidCallback notifyListeners,
    required void Function(String message, AlertType type) onAlert,
    Future<void> Function()? onCoinCollected,
  })  : _supabase = supabase,
        _getAuthProvider = getAuthProvider,
        _getLocationProvider = getLocationProvider,
        _notifyListeners = notifyListeners,
        _onAlert = onAlert,
        _onCoinCollected = onCoinCollected;

  AuthProvider? get _auth => _getAuthProvider();

  /// 현재 로그인된 플레이어의 ID
  String? get _userId => _auth?.user?.id;

  /// 하루 1회 동전 상태를 확인하고, 자정 경과 또는 동전 부족 시 재생성합니다.
  Future<void> checkAndSyncCoins() async {
    final myId = _userId;
    if (myId == null) return;
    if (_isRegeneratingCoins) {
      debugPrint('🪙 [동전 가드] 이미 동전 재생성이 진행 중이므로 중복 동기화 패치를 취소합니다.');
      return;
    }

    try {
      final nowUtc = DateTime.now().toUtc();
      final todayStr =
          "${nowUtc.year}-${nowUtc.month.toString().padLeft(2, '0')}-${nowUtc.day.toString().padLeft(2, '0')}";

      final lastDate = await PreferencesService.getLastCoinGeneratedDate();

      if (_coins.isNotEmpty && lastDate == todayStr) {
        return;
      }

      final existingCoins = await _supabase.fetchUserCoins(myId);

      if (lastDate != todayStr || existingCoins.isEmpty) {
        debugPrint(
            '🪙 자정 경과 또는 동전 없음 감지 ➔ 동전 재생성 시작 (UTC: $todayStr)');
        await _regenerateCoins(myId, todayStr);
      } else {
        _coins = existingCoins;
        _notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ 동전 상태 체크 및 동기화 실패: $e');
    }
  }

  /// 플레이어가 현재 위치한 타일에 동전이 있으면 획득 처리합니다 (낙관적 업데이트 + 실패 시 롤백).
  Future<void> checkCoinCollection(String tileId) async {
    final myId = _userId;
    if (myId == null) return;

    final coinIndex =
        _coins.indexWhere((c) => c.tileId == tileId && !c.isCollected);
    if (coinIndex == -1) return;

    final targetCoin = _coins[coinIndex];
    debugPrint('🪙 동전 발견! 타일 ID: ${targetCoin.tileId}. 획득 시도 중...');

    final originalCoins = List<UserCoin>.from(_coins);
    final updatedCoins = List<UserCoin>.from(_coins);
    updatedCoins[coinIndex] = UserCoin(
      userId: targetCoin.userId,
      tileId: targetCoin.tileId,
      q: targetCoin.q,
      r: targetCoin.r,
      isCollected: true,
      createdAt: targetCoin.createdAt,
      collectedAt: DateTime.now(),
    );
    _coins = updatedCoins;
    _notifyListeners();

    try {
      final success =
          await _supabase.collectCoin(myId, tileId, GameConfig.coinGoldReward);
      if (success) {
        AudioService().playNotification();
        _onAlert(
          '동전을 발견하여 ${GameConfig.coinGoldReward.toInt()}골드를 획득했습니다!',
          AlertType.info,
        );
        await _onCoinCollected?.call();
      } else {
        debugPrint('⚠️ 동전 획득 DB 처리 실패 ➔ 롤백 수행');
        _coins = originalCoins;
        _notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ 동전 획득 처리 중 예외 발생 ➔ 롤백 수행: $e');
      _coins = originalCoins;
      _notifyListeners();
    }
  }

  /// 본진(또는 현재 위치) 중심 반경 내 타일 후보군에서 10개의 동전을 선정해 재생성합니다.
  Future<void> _regenerateCoins(String userId, String todayStr) async {
    if (_isRegeneratingCoins) return;
    _isRegeneratingCoins = true;

    final hqTileId = _auth?.profile?.mainBaseTileId;
    final bool hasHQ =
        hqTileId != null && hqTileId.isNotEmpty && hqTileId != 'none';

    LatLng? targetCenterLatLng;

    if (hasHQ) {
      final parsed = HexService.parseTileId(hqTileId);
      if (parsed != null) {
        targetCenterLatLng = HexService.hexToLatLng(parsed['q']!, parsed['r']!);
      }
    }

    // 본진이 없거나 파싱 실패 시 기존 폴백인 내 위치(currentLocation) 사용
    if (targetCenterLatLng == null) {
      final currLoc = _getLocationProvider()?.currentLocation;
      if (currLoc == null) {
        debugPrint('⚠️ 본진 위치 또는 GPS 위치 정보가 없어 동전을 재생성할 수 없습니다. 다음 업데이트 대기.');
        _isRegeneratingCoins = false;
        return;
      }
      targetCenterLatLng = currLoc;
    }

    try {
      final centerHex = HexService.latLngToHex(targetCenterLatLng);
      final int centerQ = centerHex['q']!;
      final int centerR = centerHex['r']!;
      const int radius = GameConfig.coinSpawnMaxDistance;

      final List<Map<String, dynamic>> candidates = [];
      final List<Map<String, dynamic>> backupCandidates = [];
      final centerLatLng = HexService.hexToLatLng(centerQ, centerR);

      for (int q = -radius; q <= radius; q++) {
        final int rMin = math.max(-radius, -q - radius);
        final int rMax = math.min(radius, -q + radius);
        for (int r = rMin; r <= rMax; r++) {
          if (q == 0 && r == 0) continue;
          final targetQ = centerQ + q;
          final targetR = centerR + r;
          final targetLatLng = HexService.hexToLatLng(targetQ, targetR);

          final double dLat =
              targetLatLng.latitude - centerLatLng.latitude;
          final double dLng =
              targetLatLng.longitude - centerLatLng.longitude;
          final double angle = math.atan2(dLat, dLng);

          final int distance =
              ((q.abs() + r.abs() + (q + r).abs()) / 2).round();

          final item = {
            'q': targetQ,
            'r': targetR,
            'angle': angle,
          };

          if (distance >= GameConfig.coinSpawnMinDistance &&
              distance <= GameConfig.coinSpawnMaxDistance) {
            candidates.add(item);
          } else {
            backupCandidates.add(item);
          }
        }
      }

      if (candidates.isEmpty && backupCandidates.isEmpty) return;

      final List<Map<String, int>> selected = [];
      const int numSlices = 10;
      const double sliceWidth = (2 * math.pi) / numSlices;

      for (int i = 0; i < numSlices; i++) {
        final double sliceMin = -math.pi + (i * sliceWidth);
        final double sliceMax = sliceMin + sliceWidth;

        final sliceCandidates = candidates.where((c) {
          final double angle = c['angle'] as double;
          return angle >= sliceMin && angle < sliceMax;
        }).toList();

        if (sliceCandidates.isNotEmpty) {
          sliceCandidates.shuffle();
          final chosen = sliceCandidates.first;
          selected.add({
            'q': chosen['q'] as int,
            'r': chosen['r'] as int,
          });
        }
      }

      if (selected.length < 10) {
        candidates.shuffle();
        for (final c in candidates) {
          if (selected.length >= 10) break;
          final targetQ = c['q'] as int;
          final targetR = c['r'] as int;
          final isDuplicate =
              selected.any((s) => s['q'] == targetQ && s['r'] == targetR);
          if (!isDuplicate) {
            selected.add({'q': targetQ, 'r': targetR});
          }
        }
      }

      if (selected.length < 10) {
        backupCandidates.shuffle();
        for (final c in backupCandidates) {
          if (selected.length >= 10) break;
          final targetQ = c['q'] as int;
          final targetR = c['r'] as int;
          final isDuplicate =
              selected.any((s) => s['q'] == targetQ && s['r'] == targetR);
          if (!isDuplicate) {
            selected.add({'q': targetQ, 'r': targetR});
          }
        }
      }

      final List<UserCoin> newCoins = selected.map((c) {
        final q = c['q']!;
        final r = c['r']!;
        final tileId = HexService.tileId(q, r);
        return UserCoin(
          userId: userId,
          tileId: tileId,
          q: q,
          r: r,
          isCollected: false,
          createdAt: DateTime.now().toUtc(),
        );
      }).toList();

      await _supabase.clearUserCoins(userId);
      final insertSuccess = await _supabase.insertUserCoins(newCoins);

      if (insertSuccess) {
        _coins = newCoins;
        await PreferencesService.setLastCoinGeneratedDate(todayStr);
        debugPrint('🪙 동전 10개 재생성 및 원격 DB 등록 완료.');
        _notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ 동전 생성 중 오류 발생: $e');
    } finally {
      _isRegeneratingCoins = false;
    }
  }
}
