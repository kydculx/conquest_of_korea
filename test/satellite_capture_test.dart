import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;

import 'package:conquest_mobile/providers/game_provider.dart';
import 'package:conquest_mobile/services/supabase_service.dart';
import 'package:conquest_mobile/providers/auth_provider.dart';
import 'package:conquest_mobile/providers/location_provider.dart';
import 'package:conquest_mobile/models/tile_model.dart';
import 'package:conquest_mobile/models/user_profile.dart';
import 'package:conquest_mobile/core/constants/game_config.dart';

// Fake Supabase Service 구현
class FakeSupabaseService implements SupabaseService {
  final List<HexTile> mockTiles = [];
  bool captureSuccess = true;

  @override
  Future<List<HexTile>> fetchAllCapturedTiles() async => mockTiles;

  @override
  Stream<List<HexTile>> get capturedTilesStream => Stream.value(mockTiles);

  @override
  Future<bool> captureTile(HexTile tile) async {
    if (captureSuccess) {
      mockTiles.removeWhere((t) => t.id == tile.id);
      mockTiles.add(tile);
    }
    return captureSuccess;
  }

  @override
  Future<TileStatus> checkTileStatusFromServer(String tileId, String currentUserId) async {
    final tile = mockTiles.firstWhere(
      (t) => t.id == tileId,
      orElse: () => HexTile(
        id: tileId,
        q: 0,
        r: 0,
        userId: 'none',
        colorHex: '#FFFFFF',
        capturedAt: DateTime.now(),
        captureCount: 0,
      ),
    );
    if (tile.userId == 'none') return TileStatus.empty;
    if (tile.userId == currentUserId) return TileStatus.mine;
    return TileStatus.enemy;
  }

  @override
  Future<HexTile?> fetchTile(String tileId) async {
    try {
      return mockTiles.firstWhere((t) => t.id == tileId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<double?> fetchGoldRate() async => 1.0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Mock User 클래스 (supabase_flutter의 User를 흉내냄)
class MockUser extends supabase_flutter.User {
  MockUser({required super.id})
      : super(
          appMetadata: {},
          userMetadata: {},
          aud: '',
          createdAt: '',
        );
}

// Fake AuthProvider 구현
class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  supabase_flutter.User? user;
  
  @override
  UserProfile? profile;

  @override
  bool get isAuthenticated => user != null;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> refreshProfile() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Fake LocationProvider 구현
class FakeLocationProvider extends ChangeNotifier implements LocationProvider {
  @override
  bool isGpsActive = true;
  
  @override
  LatLng? currentLocation;
  
  @override
  double currentAccuracy = 10.0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // SharedPreferences 모킹 설정
  SharedPreferences.setMockInitialValues({});

  late FakeSupabaseService fakeSupabase;
  late FakeAuthProvider fakeAuth;
  late FakeLocationProvider fakeLocation;

  final testUserId = 'test-user-123';
  final enemyUserId = 'enemy-user-456';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    fakeSupabase = FakeSupabaseService();
    fakeAuth = FakeAuthProvider();
    fakeLocation = FakeLocationProvider();

    // 기본 로그인 상태 및 프로필 설정
    fakeAuth.user = MockUser(id: testUserId);
    fakeAuth.profile = UserProfile(
      id: testUserId,
      nickname: '테스트유저',
      colorHex: '#FF0000',
      teamId: 'none',
      mainBaseTileId: 'hex_0_0',
      createdAt: DateTime.now(),
      gold: 100.0,
    );
  });

  // GameProvider를 생성 및 초기화하고 반환하는 헬퍼 함수
  Future<GameProvider> createInitializedGameProvider() async {
    final provider = GameProvider(supabase: fakeSupabase);
    provider.setAuthProvider(fakeAuth);
    provider.setLocationProvider(fakeLocation);
    await provider.initializationFuture;
    return provider;
  }

  group('위성 점령 연결성 (checkSatelliteCaptureConnectivity) 테스트', () {
    test('메인 기지가 설정되지 않았을 때는 연결성 검사에 실패해야 함', () async {
      fakeAuth.profile = UserProfile(
        id: testUserId,
        nickname: '테스트유저',
        colorHex: '#FF0000',
        teamId: 'none',
        mainBaseTileId: '',
        createdAt: DateTime.now(),
      );
      final gameProvider = await createInitializedGameProvider();

      final result = gameProvider.checkSatelliteCaptureConnectivity('hex_1_0');
      expect(result, isFalse);
    });

    test('메인 기지와 인접한 빈 타일은 연결성 검사를 통과해야 함', () async {
      // 메인 기지(hex_0_0)가 내 소유로 설정됨
      final hqTile = HexTile(
        id: 'hex_0_0',
        q: 0,
        r: 0,
        userId: testUserId,
        colorHex: '#FF0000',
        capturedAt: DateTime.now(),
        captureCount: 1,
      );
      fakeSupabase.mockTiles.add(hqTile);
      final gameProvider = await createInitializedGameProvider();

      // hex_1_0은 메인기지 [0,0]에 인접한 빈 타일
      final result = gameProvider.checkSatelliteCaptureConnectivity('hex_1_0');
      expect(result, isTrue);
    });

    test('메인 기지와 떨어져 있는 빈 타일은 연결성 검사에 실패해야 함', () async {
      final hqTile = HexTile(
        id: 'hex_0_0',
        q: 0,
        r: 0,
        userId: testUserId,
        colorHex: '#FF0000',
        capturedAt: DateTime.now(),
        captureCount: 1,
      );
      fakeSupabase.mockTiles.add(hqTile);
      final gameProvider = await createInitializedGameProvider();

      // hex_2_0은 [0,0]에서 2칸 떨어진 타일이므로 직접 연결되지 않음
      final result = gameProvider.checkSatelliteCaptureConnectivity('hex_2_0');
      expect(result, isFalse);
    });

    test('내 소유 영토를 통해 다리로 연결되어 있다면 연결성 검사를 통과해야 함', () async {
      // hex_0_0 (본부) 및 hex_1_0 (내 영토)
      final tile0 = HexTile(
        id: 'hex_0_0',
        q: 0,
        r: 0,
        userId: testUserId,
        colorHex: '#FF0000',
        capturedAt: DateTime.now(),
        captureCount: 1,
      );
      final tile1 = HexTile(
        id: 'hex_1_0',
        q: 1,
        r: 0,
        userId: testUserId,
        colorHex: '#FF0000',
        capturedAt: DateTime.now(),
        captureCount: 1,
      );
      fakeSupabase.mockTiles.addAll([tile0, tile1]);
      final gameProvider = await createInitializedGameProvider();

      // [0,0] -> [1,0] -> [2,0] (빈 타일)로 경로가 연결됨
      final result = gameProvider.checkSatelliteCaptureConnectivity('hex_2_0');
      expect(result, isTrue);
    });

    test('적 영토가 경로를 가로막고 있다면 연결성 검사에 실패해야 함', () async {
      final tile0 = HexTile(
        id: 'hex_0_0',
        q: 0,
        r: 0,
        userId: testUserId,
        colorHex: '#FF0000',
        capturedAt: DateTime.now(),
        captureCount: 1,
      );
      // hex_1_0은 적의 영토
      final tile1Enemy = HexTile(
        id: 'hex_1_0',
        q: 1,
        r: 0,
        userId: enemyUserId,
        colorHex: '#0000FF',
        capturedAt: DateTime.now(),
        captureCount: 1,
      );
      fakeSupabase.mockTiles.addAll([tile0, tile1Enemy]);
      final gameProvider = await createInitializedGameProvider();

      // hex_2_0은 빈 타일이지만, 다리 역할인 hex_1_0이 적 영토이므로 연결 불가
      final result = gameProvider.checkSatelliteCaptureConnectivity('hex_2_0');
      expect(result, isFalse);
    });
  });

  group('거리 비례 소요 시간 (getSatelliteCaptureDurationSeconds) 테스트', () {
    test('메인 기지와 거리에 따라 올바른 점령 시간을 초 단위로 계산해야 함', () async {
      final gameProvider = await createInitializedGameProvider();
      
      // 1타일당 소요 시간: satelliteCaptureSecondsPerTile (1.0)
      // hexDistance([0,0], [0,0]) = 0 -> 최소 1초
      expect(gameProvider.getSatelliteCaptureDurationSeconds('hex_0_0'), equals(1));

      // hexDistance([0,0], [1,0]) = 1 -> 2초
      expect(gameProvider.getSatelliteCaptureDurationSeconds('hex_1_0'), equals(2));

      // hexDistance([0,0], [2,0]) = 2 -> 3초
      expect(gameProvider.getSatelliteCaptureDurationSeconds('hex_2_0'), equals(3));

      // hexDistance([0,0], [5,0]) = 5 -> 6초
      expect(gameProvider.getSatelliteCaptureDurationSeconds('hex_5_0'), equals(6));
    });
  });

  group('위성 점령 쿨타임 및 프로세스 실행 테스트', () {
    test('쿨타임이 없을 때 위성 점령이 정상적으로 시작되고 진행되어야 함', () async {
      // 1. 메인 기지 본인 영토 등록
      final hqTile = HexTile(
        id: 'hex_0_0',
        q: 0,
        r: 0,
        userId: testUserId,
        colorHex: '#FF0000',
        capturedAt: DateTime.now(),
        captureCount: 1,
      );
      fakeSupabase.mockTiles.add(hqTile);
      final gameProvider = await createInitializedGameProvider();

      // 2. 인접 빈 타일 hex_1_0에 위성 점령 시도
      expect(gameProvider.isSatelliteCapturing, isFalse);
      gameProvider.executeSatelliteCapture('hex_1_0');

      expect(gameProvider.isSatelliteCapturing, isTrue);
      expect(gameProvider.satelliteCapturingTileId, equals('hex_1_0'));
      expect(gameProvider.satelliteCaptureProgress, equals(0.0));

      // 3. 점령 취소 테스트
      gameProvider.cancelSatelliteCapture();
      expect(gameProvider.isSatelliteCapturing, isFalse);
      expect(gameProvider.satelliteCapturingTileId, isNull);
    });

    test('마지막 점령 완료 후 쿨타임이 경과하지 않았다면 위성 점령 개시가 제한되어야 함', () async {
      // 1. 메인 기지 본인 영토 등록
      final hqTile = HexTile(
        id: 'hex_0_0',
        q: 0,
        r: 0,
        userId: testUserId,
        colorHex: '#FF0000',
        capturedAt: DateTime.now(),
        captureCount: 1,
      );
      fakeSupabase.mockTiles.add(hqTile);

      // 2. 강제로 쿨타임의 절반 전에 위성점령을 했다고 주입
      final cooltimeHalf = GameConfig.satelliteCaptureCooltime ~/ 2;
      final lastCaptureTime = DateTime.now().subtract(cooltimeHalf);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hq_last_satellite_capture_time', lastCaptureTime.toIso8601String());

      // Provider를 새로 초기화하여 마지막 캡처 시각을 쿨타임 중으로 로드하도록 함
      final newGameProvider = await createInitializedGameProvider();

      expect(newGameProvider.remainingSatelliteCaptureCoolSeconds, greaterThan(0));
      expect(newGameProvider.remainingSatelliteCaptureCoolSeconds, lessThanOrEqualTo(GameConfig.satelliteCaptureCooltime.inSeconds));

      // 3. 쿨타임 대기 상태에서 점령 시도 -> 차단되어야 함
      newGameProvider.executeSatelliteCapture('hex_1_0');
      expect(newGameProvider.isSatelliteCapturing, isFalse);
    });
  });
}
