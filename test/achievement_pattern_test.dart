import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conquest_mobile/providers/achievement_provider.dart';
import 'package:conquest_mobile/models/tile_model.dart';
import 'package:conquest_mobile/models/user_profile.dart';
import 'package:conquest_mobile/services/supabase_service.dart';
import 'package:conquest_mobile/providers/auth_provider.dart';
import 'package:conquest_mobile/services/hex_service.dart';
import 'package:conquest_mobile/models/footprint_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;

// Fake Supabase Service 구현
class FakeSupabaseService implements SupabaseService {
  final List<HexTile> mockTiles = [];
  final List<String> unlockedAchievements = [];
  final List<String> consumedTileIds = []; // 소비된 타일 추적용

  @override
  Future<List<HexTile>> fetchAllCapturedTiles() async => mockTiles;

  @override
  Stream<List<HexTile>> get capturedTilesStream => Stream.value(mockTiles);

  @override
  Future<List<String>> fetchUserAchievements(String userId) async {
    return unlockedAchievements;
  }

  @override
  Future<bool> unlockAchievement(
    String userId,
    String achievementId, {
    List<String>? consumedTileIds,
  }) async {
    if (!unlockedAchievements.contains(achievementId)) {
      unlockedAchievements.add(achievementId);
    }
    if (consumedTileIds != null) {
      this.consumedTileIds.addAll(consumedTileIds);
    }
    return true;
  }

  @override
  Future<List<String>> fetchConsumedTileIds(String userId) async {
    return consumedTileIds;
  }

  @override
  Future<List<FootprintTile>> fetchUserFootprints(String userId) async => [];

  @override
  Future<bool> recordFootprint(String userId, String tileId, DateTime time) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Mock User 구현
class MockUser extends supabase_flutter.User {
  MockUser({required super.id})
      : super(appMetadata: {}, userMetadata: {}, aud: '', createdAt: '');
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseService fakeSupabase;
  late FakeAuthProvider fakeAuth;
  late AchievementProvider achievementProvider;

  const testUserId = 'test-user-123';
  late String realAJsonContent;
  late List<dynamic> realATiles;

  setUp(() async {
    fakeSupabase = FakeSupabaseService();
    fakeAuth = FakeAuthProvider();
    achievementProvider = AchievementProvider(supabase: fakeSupabase);

    fakeAuth.user = MockUser(id: testUserId);
    fakeAuth.profile = UserProfile(
      id: testUserId,
      nickname: '테스트유저',
      colorHex: '#FF0000',
      teamId: 'none',
      mainBaseTileId: 'hex_0_0',
      createdAt: DateTime.now(),
      gold: 100.0,
      capturedTilesCount: 0,
    );

    achievementProvider.setAuthProvider(fakeAuth);

    // setUp 단계에서 실행된 초기 비동기 동기화 작업을 명시적으로 대기 완료하여 병렬 경합을 원천 방지
    while (achievementProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 5));
    }

    // assets/data/A.json 파일의 실제 내용 파일 시스템에서 동적 로드
    final file = File('assets/data/A.json');
    realAJsonContent = file.readAsStringSync();
    final Map<String, dynamic> parsedJson = json.decode(realAJsonContent);
    realATiles = parsedJson['tiles'] as List<dynamic>;

    // rootBundle Mocking 등록해 실제 로드 시 파일 시스템의 데이터를 반환하게 함
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        final String key = utf8.decode(message!.buffer.asUint8List());
        if (key.startsWith('assets/data/') && key.endsWith('.json')) {
          final file = File(key);
          if (file.existsSync()) {
            final content = file.readAsStringSync();
            return ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
          }
        }
        return null;
      },
    );
  });

  group('실제 A.json 데이터 기반 패턴 매칭 정밀 검증 테스트', () {
    test('실제 A 패턴 파일 좌표들을 평행이동(q+100, r+200)하여 점령 완료했을 때 성공 판정되어야 함', () async {
      const int offsetQ = 100;
      const int offsetR = 200;

      fakeAuth.profile = fakeAuth.profile!.copyWith(capturedTilesCount: realATiles.length);

      final Map<String, HexTile> captured = {};
      for (final tile in realATiles) {
        final int q = (tile['q'] as int) + offsetQ;
        final int r = (tile['r'] as int) + offsetR;
        final String tid = HexService.tileId(q, r);

        captured[tid] = HexTile(
          id: tid,
          q: q,
          r: r,
          userId: testUserId,
          colorHex: '#FF0000',
          capturedAt: DateTime.now(),
          captureCount: 1,
        );
      }

      final firstTile = realATiles.first;
      final int firstQ = (firstTile['q'] as int) + offsetQ;
      final int firstR = (firstTile['r'] as int) + offsetR;
      final String newlyCapturedId = HexService.tileId(firstQ, firstR);

      await achievementProvider.checkAndUnlock(
        capturedTiles: captured,
        newlyCapturedTileId: newlyCapturedId,
      );

      expect(achievementProvider.unlockedAchievementIds, contains('ACH_PATTERN_A'));
    });

    test('실제 A 패턴의 구성 타일 중 딱 1개 좌표(맨 첫 번째 타일)가 점령되지 않았을 때 실패해야 함', () async {
      const int offsetQ = -50;
      const int offsetR = 70;

      fakeAuth.profile = fakeAuth.profile!.copyWith(capturedTilesCount: realATiles.length - 1);

      final Map<String, HexTile> captured = {};
      for (int i = 1; i < realATiles.length; i++) {
        final tile = realATiles[i];
        final int q = (tile['q'] as int) + offsetQ;
        final int r = (tile['r'] as int) + offsetR;
        final String tid = HexService.tileId(q, r);

        captured[tid] = HexTile(
          id: tid,
          q: q,
          r: r,
          userId: testUserId,
          colorHex: '#FF0000',
          capturedAt: DateTime.now(),
          captureCount: 1,
        );
      }

      final secondTile = realATiles[1];
      final int secondQ = (secondTile['q'] as int) + offsetQ;
      final int secondR = (secondTile['r'] as int) + offsetR;
      final String newlyCapturedId = HexService.tileId(secondQ, secondR);

      await achievementProvider.checkAndUnlock(
        capturedTiles: captured,
        newlyCapturedTileId: newlyCapturedId,
      );

      expect(achievementProvider.unlockedAchievementIds, isNot(contains('ACH_PATTERN_A')));
    });

    test('실제 A 패턴을 만족하였더라도, 최근 점령지가 패턴 클러스터 외곽에 동떨어진 노이즈 타일인 경우 즉시 스킵(실패)해야 함', () async {
      fakeAuth.profile = fakeAuth.profile!.copyWith(capturedTilesCount: realATiles.length + 1);

      final Map<String, HexTile> captured = {};
      
      for (final tile in realATiles) {
        final int q = tile['q'] as int;
        final int r = tile['r'] as int;
        final String tid = HexService.tileId(q, r);

        captured[tid] = HexTile(
          id: tid,
          q: q,
          r: r,
          userId: testUserId,
          colorHex: '#FF0000',
          capturedAt: DateTime.now(),
          captureCount: 1,
        );
      }

      final String noiseTileId = HexService.tileId(99, 99);
      captured[noiseTileId] = HexTile(
        id: noiseTileId,
        q: 99,
        r: 99,
        userId: testUserId,
        colorHex: '#FF0000',
        capturedAt: DateTime.now(),
        captureCount: 1,
      );

      await achievementProvider.checkAndUnlock(
        capturedTiles: captured,
        newlyCapturedTileId: noiseTileId,
      );

      expect(achievementProvider.unlockedAchievementIds, isNot(contains('ACH_PATTERN_A')));
    });

    test('실제 패턴 1개 분량만 점령된 상태에서 성공 해금 후, 사용된 타일이 소비 완료(Lock)되면 재해금이 차단되어야 함', () async {
      // 1. 실제 A 패턴의 타일들만 정확히 1개 분량(73개) 주입하여 점령
      fakeAuth.profile = fakeAuth.profile!.copyWith(capturedTilesCount: realATiles.length);
      
      final Map<String, HexTile> captured = {};
      for (final tile in realATiles) {
        final int q = tile['q'] as int;
        final int r = tile['r'] as int;
        final String tid = HexService.tileId(q, r);
        captured[tid] = HexTile(
          id: tid,
          q: q,
          r: r,
          userId: testUserId,
          colorHex: '#FF0000',
          capturedAt: DateTime.now(),
          captureCount: 1,
        );
      }

      // 2. 첫 번째 업적 달성 검증 (실제 A 패턴의 첫 번째 타일 기준 BFS 기동 -> 매칭 성공)
      final firstTile = realATiles.first;
      final int firstQ = firstTile['q'] as int;
      final int firstR = firstTile['r'] as int;
      final String newlyCapturedId = HexService.tileId(firstQ, firstR);

      await achievementProvider.checkAndUnlock(
        capturedTiles: captured,
        newlyCapturedTileId: newlyCapturedId,
      );

      // 첫 매칭 해금 성공 확인
      expect(achievementProvider.unlockedAchievementIds, contains('ACH_PATTERN_A'));
      expect(fakeSupabase.consumedTileIds, hasLength(realATiles.length));

      // 3. 동일한 구역 내에서 재해금을 강제 테스트하기 위해 해금 리스트에서 강제 전량 삭제
      fakeSupabase.unlockedAchievements.removeWhere((x) => x == 'ACH_PATTERN_A');
      
      achievementProvider = AchievementProvider(supabase: fakeSupabase);
      achievementProvider.setAuthProvider(fakeAuth);

      while (achievementProvider.isLoading) {
        await Future.delayed(const Duration(milliseconds: 5));
      }

      // 이미 소비된 타일 73개가 Lock 상태이므로, 전체 폴백 검사를 돌려도
      // 점령 타일 73개 중 미사용 타일은 0개 상태가 됨.
      // 따라서 0 < 73 조건에 걸리거나 매칭 앵커 탐색 대상이 아예 없어서 실패해야 함.
      await achievementProvider.checkAndUnlock(
        capturedTiles: captured,
      );
      
      expect(achievementProvider.unlockedAchievementIds, isNot(contains('ACH_PATTERN_A')));
    });

    test('실제 B 패턴 파일 좌표들을 평행이동(q-10, r+30)하여 점령 완료했을 때 성공 판정되어야 함', () async {
      final file = File('assets/data/B.json');
      final String bJsonContent = file.readAsStringSync();
      final Map<String, dynamic> parsedJson = json.decode(bJsonContent);
      final List<dynamic> bTiles = parsedJson['tiles'] as List<dynamic>;

      const int offsetQ = -10;
      const int offsetR = 30;

      fakeAuth.profile = fakeAuth.profile!.copyWith(capturedTilesCount: bTiles.length);

      final Map<String, HexTile> captured = {};
      for (final tile in bTiles) {
        final int q = (tile['q'] as int) + offsetQ;
        final int r = (tile['r'] as int) + offsetR;
        final String tid = HexService.tileId(q, r);

        captured[tid] = HexTile(
          id: tid,
          q: q,
          r: r,
          userId: testUserId,
          colorHex: '#FF0000',
          capturedAt: DateTime.now(),
          captureCount: 1,
        );
      }

      final firstTile = bTiles.first;
      final int firstQ = (firstTile['q'] as int) + offsetQ;
      final int firstR = (firstTile['r'] as int) + offsetR;
      final String newlyCapturedId = HexService.tileId(firstQ, firstR);

      await achievementProvider.checkAndUnlock(
        capturedTiles: captured,
        newlyCapturedTileId: newlyCapturedId,
      );

      expect(achievementProvider.unlockedAchievementIds, contains('ACH_PATTERN_B'));
    });
  });
}
