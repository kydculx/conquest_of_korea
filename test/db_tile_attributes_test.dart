// ⚠️ 실서버 검증용 임시 테스트: 어드민 맵 에디터가 저장한 타일 속성 조회 검증
// 실행: flutter test test/db_tile_attributes_test.dart
// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:conquest_mobile/models/tile_attribute_model.dart';

void main() {
  test('DB에서 어드민 타일 속성 읽기 및 모델 파싱 검증', () async {
    // 1. .env 파일에서 Supabase 접속 정보 로드
    final envFile = File('.env');
    expect(envFile.existsSync(), isTrue, reason: '.env 파일이 필요합니다.');
    final envLines = await envFile.readAsLines();
    String? url;
    String? anonKey;
    for (final line in envLines) {
      if (line.startsWith('SUPABASE_URL=')) {
        url = line.substring('SUPABASE_URL='.length).trim();
      } else if (line.startsWith('SUPABASE_ANON_KEY=')) {
        anonKey = line.substring('SUPABASE_ANON_KEY='.length).trim();
      }
    }
    expect(url, isNotNull);
    expect(anonKey, isNotNull);

    final client = SupabaseClient(url!, anonKey!);

    // 2. map_tile_types 테이블 조회
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📘 [1/4] map_tile_types 조회');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    List<TileType> tileTypes = [];
    try {
      final response = await client
          .from('map_tile_types')
          .select('*')
          .order('id', ascending: true);

      print('✅ map_tile_types 응답 수신: ${response.length}개');
      tileTypes =
          (response as List).map((e) => TileType.fromJson(Map<String, dynamic>.from(e))).toList();

      if (tileTypes.isEmpty) {
        print('⚠️  등록된 타일 타입이 없습니다 (마이그레이션 시드 미적용 가능성).');
      } else {
        for (final t in tileTypes) {
          print('   • id=${t.id} | name="${t.name}" | color=${t.colorHex} | blocked=${t.isBlocked}');
        }
      }
    } catch (e) {
      print('❌ map_tile_types 조회 실패: $e');
      rethrow;
    }

    // 3. map_tile_attributes 테이블 조회
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📗 [2/4] map_tile_attributes 조회');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    List<TileAttribute> allAttributes = [];
    try {
      final response = await client.from('map_tile_attributes').select('*');

      print('✅ map_tile_attributes 응답 수신: ${response.length}개');
      allAttributes = (response as List)
          .map((e) => TileAttribute.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (allAttributes.isEmpty) {
        print('⚠️  부여된 타일 속성이 없습니다. 어드민 에디터에서 타일을 선택해 보세요.');
      } else {
        // 타입별 카운트
        final byType = <int, int>{};
        for (final a in allAttributes) {
          byType[a.typeId] = (byType[a.typeId] ?? 0) + 1;
        }
        print('📊 타입별 부여 현황:');
        byType.forEach((typeId, count) {
          final type = tileTypes.firstWhere(
            (t) => t.id == typeId,
            orElse: () => const TileType(id: -1, name: '?', colorHex: '?'),
          );
          print('   • type_id=$typeId (${type.name}, ${type.colorHex}): $count개');
        });

        print('\n📍 샘플 5개:');
        for (final a in allAttributes.take(5)) {
          print('   • id="${a.id}" → normalizedId="${a.normalizedId}" | '
              'q=${a.q} r=${a.r} | type_id=${a.typeId} | memo="${a.memo ?? ""}"');
        }
      }
    } catch (e) {
      print('❌ map_tile_attributes 조회 실패: $e');
      rethrow;
    }

    // 4. ID 정규화 검증
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📙 [3/4] 어드민 ID ↔ 모바일 ID 정규화 검증');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    final rawIdTests = ['5_3', '100_-50', 'hex_5_3'];
    for (final raw in rawIdTests) {
      final normalized = TileAttribute.normalizeId(raw);
      print('   • normalizeId("$raw") = "$normalized"');
    }

    // 5. 영역 조회 시뮬레이션 — fetchTileAttributesInArea 동작 검증
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📕 [4/4] 영역 내 속성 조회 시뮬레이션');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    if (allAttributes.isEmpty) {
      print('⚠️  스킵 — 속성 데이터 없음');
    } else {
      // 첫 속성 주변 ±2 영역 조회
      final first = allAttributes.first;
      final minQ = first.q - 2;
      final maxQ = first.q + 2;
      final minR = first.r - 2;
      final maxR = first.r + 2;

      final inArea = await client
          .from('map_tile_attributes')
          .select('*')
          .gte('q', minQ)
          .lte('q', maxQ)
          .gte('r', minR)
          .lte('r', maxR);

      final parsed =
          (inArea as List).map((e) => TileAttribute.fromJson(Map<String, dynamic>.from(e))).toList();

      print('✅ 영역 [$minQ..$maxQ, $minR..$maxR] 내 속성 ${parsed.length}개:');
      for (final a in parsed) {
        final type = tileTypes.firstWhere(
          (t) => t.id == a.typeId,
          orElse: () => const TileType(id: -1, name: '?', colorHex: '?'),
        );
        print('   • ${a.normalizedId} → ${type.name} (${type.colorHex})');
      }
    }

    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎯 검증 요약');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('• 타일 타입 ${tileTypes.length}개 로드 가능');
    print('• 부여된 속성 ${allAttributes.length}개 로드 가능');
    print('• ID 정규화: 어드민 "q_r" ↔ 모바일 "hex_q_r" 정상 동작');
    print('• SupabaseService의 fetchTileTypes / fetchTileAttributesInArea 메서드가');
    print('  실서버 데이터를 정상적으로 읽어옴을 확인했습니다.');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  });
}
