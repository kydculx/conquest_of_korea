import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:conquest_mobile/models/user_coin.dart';
import 'package:conquest_mobile/services/hex_service.dart';

void main() {
  group('동전(코인) 시스템 단위 테스트', () {
    test('UserCoin 데이터 모델 JSON 직렬화 및 역직렬화 검증', () {
      final nowUtc = DateTime.now().toUtc();
      final originalCoin = UserCoin(
        userId: 'test-user-id-1234',
        tileId: 'hex_10_20',
        q: 10,
        r: 20,
        isCollected: false,
        createdAt: nowUtc,
      );

      final json = originalCoin.toJson();
      expect(json['user_id'], 'test-user-id-1234');
      expect(json['tile_id'], 'hex_10_20');
      expect(json['q'], 10);
      expect(json['r'], 20);
      expect(json['is_collected'], false);
      expect(json['created_at'], nowUtc.toIso8601String());
      expect(json['collected_at'], isNull);

      final decodedCoin = UserCoin.fromJson(json);
      expect(decodedCoin.userId, originalCoin.userId);
      expect(decodedCoin.tileId, originalCoin.tileId);
      expect(decodedCoin.q, originalCoin.q);
      expect(decodedCoin.r, originalCoin.r);
      expect(decodedCoin.isCollected, originalCoin.isCollected);
      // toLocal() 변환에 따른 오차 보정을 위해 millisecond 오차 내 일치 확인
      expect(decodedCoin.createdAt.toUtc().difference(originalCoin.createdAt).inMilliseconds.abs() < 50, true);
    });

    test('현재 위치 기준 반경 15타일 이내의 후보 타일 수집 검증', () {
      const int centerQ = 5;
      const int centerR = -8;
      const int radius = 15;

      // 반경 15 이내의 모든 axial 타일 후보 수집 (중심 타일 제외)
      final List<Map<String, int>> candidates = [];
      for (int q = -radius; q <= radius; q++) {
        final int rMin = math.max(-radius, -q - radius);
        final int rMax = math.min(radius, -q + radius);
        for (int r = rMin; r <= rMax; r++) {
          if (q == 0 && r == 0) continue;
          candidates.add({
            'q': centerQ + q,
            'r': centerR + r,
          });
        }
      }

      // 반경 15의 헥사곤 격자 수식: 3 * N * (N + 1) = 3 * 15 * 16 = 720개 (본인 제외)
      expect(candidates.length, 720);

      // 모든 후보의 거리가 center 타일로부터 15 이하인지 검사
      for (final c in candidates) {
        final dist = HexService.hexDistance(centerQ, centerR, c['q']!, c['r']!);
        expect(dist <= radius, true);
        expect(dist > 0, true);
      }
    });

    test('중복 없는 무작위 10개 동전 타일 셔플 추출 및 유일성 검증', () {
      const int centerQ = 0;
      const int centerR = 0;
      const int radius = 15;

      final List<Map<String, int>> candidates = [];
      for (int q = -radius; q <= radius; q++) {
        final int rMin = math.max(-radius, -q - radius);
        final int rMax = math.min(radius, -q + radius);
        for (int r = rMin; r <= rMax; r++) {
          if (q == 0 && r == 0) continue;
          candidates.add({
            'q': centerQ + q,
            'r': centerR + r,
          });
        }
      }

      // 무작위 셔플
      candidates.shuffle();
      final selected = candidates.sublist(0, 10);

      expect(selected.length, 10);

      // 타일 ID의 유일성(중복 없음) 검사
      final Set<String> tileIds = {};
      for (final s in selected) {
        final id = HexService.tileId(s['q']!, s['r']!);
        tileIds.add(id);
      }
      expect(tileIds.length, 10);
    });
  });
}
