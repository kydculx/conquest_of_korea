import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:conquest_mobile/services/hex_service.dart';

void main() {
  group('HexService Web Mercator grid', () {
    test('origin maps to (0, 0) and back', () {
      const origin = LatLng(37.5665, 126.9780);
      final hex = HexService.latLngToHex(origin);
      expect(hex['q'], 0);
      expect(hex['r'], 0);

      final center = HexService.hexToLatLng(0, 0);
      expect(center.latitude, closeTo(origin.latitude, 1e-9));
      expect(center.longitude, closeTo(origin.longitude, 1e-9));
    });

    test('round-trips global coordinates', () {
      const samples = [
        LatLng(37.5665, 126.9780), // Seoul
        LatLng(35.1796, 129.0756), // Busan
        LatLng(52.5200, 13.4050), // Berlin
        LatLng(40.7128, -74.0060), // New York
        LatLng(-33.8688, 151.2093), // Sydney
      ];

      for (final sample in samples) {
        final hex = HexService.latLngToHex(sample);
        final restored = HexService.hexToLatLng(hex['q']!, hex['r']!);
        final distance = HexService.calculateDistance(sample, restored);
        // 임의의 좌표는 가장 가까운 타일 중심으로 스냅되므로
        // 중심까지의 거리는 타일 반지름(100m) 이내여야 합니다.
        expect(
          distance,
          lessThanOrEqualTo(150.0),
          reason:
              'round-trip mismatch at ${sample.latitude},${sample.longitude}',
        );
      }
    });

    test('hexes are regular at all latitudes', () {
      const samples = [
        LatLng(37.5665, 126.9780), // Seoul
        LatLng(35.1796, 129.0756), // Busan
        LatLng(52.5200, 13.4050), // Berlin
        LatLng(64.1466, -21.9426), // Reykjavik
      ];

      for (final sample in samples) {
        final hex = HexService.latLngToHex(sample);
        final corners = HexService.getHexCorners(hex['q']!, hex['r']!);
        final width = HexService.calculateDistance(corners[1], corners[3]);
        final height = HexService.calculateDistance(corners[2], corners[5]);
        final ratio = height / width;

        // 정육각형(외접원 반지름 100m)의 높이/폭 비율은 약 1.1547입니다.
        expect(
          ratio,
          closeTo(1.1547, 0.01),
          reason: 'non-regular hex at ${sample.latitude},${sample.longitude}',
        );
      }
    });

    test('grid coordinates round-trip exactly', () {
      const samples = [
        [0, 0],
        [48, -127],
        [10, -10],
        [-64137, 12557], // Berlin
        [100, -200],
      ];

      for (final sample in samples) {
        final center = HexService.hexToLatLng(sample[0], sample[1]);
        final hex = HexService.latLngToHex(center);
        expect(hex['q'], sample[0]);
        expect(hex['r'], sample[1]);
      }
    });

    test('tile ids keep the expected format', () {
      final hex = HexService.latLngToHex(const LatLng(52.5200, 13.4050));
      final id = HexService.tileId(hex['q']!, hex['r']!);
      final parsed = HexService.parseTileId(id);

      expect(parsed, isNotNull);
      expect(parsed!['q'], hex['q']);
      expect(parsed['r'], hex['r']);
    });
  });
}
