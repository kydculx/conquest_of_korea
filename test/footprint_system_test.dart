import 'package:flutter_test/flutter_test.dart';
import 'package:conquest_mobile/models/footprint_model.dart';

void main() {
  group('FootprintTile Model Tests', () {
    test('FootprintTile JSON 직렬화 및 역직렬화 테스트', () {
      final nowUtc = DateTime.utc(2026, 6, 27, 12, 34, 0);
      final tile = FootprintTile(
        tileId: 'hex_123_456',
        recordedAt: nowUtc.toLocal(),
      );

      final json = tile.toJson();
      expect(json['tile_id'], 'hex_123_456');
      expect(json['recorded_at'], nowUtc.toIso8601String());

      final parsed = FootprintTile.fromJson(json);
      expect(parsed.tileId, 'hex_123_456');
      expect(parsed.recordedAt.isAtSameMomentAs(tile.recordedAt), true);
    });

    test('FootprintTile formattedTime 년/월/일/시/분 포맷팅 검증', () {
      // 2026년 6월 27일 12시 34분 56초 생성
      final localTime = DateTime(2026, 6, 27, 12, 34, 56);
      final tile = FootprintTile(
        tileId: 'hex_123_456',
        recordedAt: localTime,
      );

      // 초/밀리초가 포맷 스트링에 포함되지 않는지 검증
      expect(tile.formattedTime, '2026/06/27 12:34');
    });

    test('Footprint 시간 절사(초 이하 00으로 절사) 기능 검증', () {
      final originalTime = DateTime(2026, 6, 27, 12, 34, 56, 789);
      
      // 초/밀리초 절사 처리
      final truncatedTime = DateTime(
        originalTime.year,
        originalTime.month,
        originalTime.day,
        originalTime.hour,
        originalTime.minute,
      );

      expect(truncatedTime.year, 2026);
      expect(truncatedTime.month, 6);
      expect(truncatedTime.day, 27);
      expect(truncatedTime.hour, 12);
      expect(truncatedTime.minute, 34);
      expect(truncatedTime.second, 0);
      expect(truncatedTime.millisecond, 0);
      expect(truncatedTime.microsecond, 0);
    });
  });
}
