// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('실서버 타일 중복 겹침 데이터 전수 정밀 점검', () async {
    print('📡 실서버 데이터 중복 겹침 정밀 추적 시작...');

    // 1. .env 파일에서 설정 로드
    final envFile = File('.env');
    expect(envFile.existsSync(), isTrue);

    final envLines = await envFile.readAsLines();
    String? url;
    String? anonKey;
    for (var line in envLines) {
      if (line.startsWith('SUPABASE_URL=')) {
        url = line.substring('SUPABASE_URL='.length).trim();
      } else if (line.startsWith('SUPABASE_ANON_KEY=')) {
        anonKey = line.substring('SUPABASE_ANON_KEY='.length).trim();
      }
    }

    expect(url, isNotNull);
    expect(anonKey, isNotNull);

    // 2. 클라이언트 초기화
    final client = SupabaseClient(url!, anonKey!);

    try {
      // 3. 모든 captured_tiles 정보 획득
      print('📥 서버 captured_tiles 테이블 전체 조회 중...');
      final response = await client.from('captured_tiles').select('id, q, r, user_id, captured_at');
      final List tiles = response as List;
      print('📦 총 ${tiles.length}개 타일 수신 완료. 중복 검사 분석 개시...');

      // 4. (q, r) 좌표쌍 기준으로 그룹핑
      final Map<String, List<Map<String, dynamic>>> coordGroups = {};
      for (final tile in tiles) {
        final q = tile['q'];
        final r = tile['r'];
        final key = '($q, $r)';
        
        if (!coordGroups.containsKey(key)) {
          coordGroups[key] = [];
        }
        coordGroups[key]!.add(Map<String, dynamic>.from(tile));
      }

      // 5. 중복 검출 및 보고
      int duplicateCount = 0;
      print('=============================================');
      print('🔍 중복 겹침 타일 검증 리포트');
      print('=============================================');
      
      coordGroups.forEach((coord, list) {
        if (list.length > 1) {
          duplicateCount++;
          print('⚠️ 중복 좌표 검출: $coord');
          for (var i = 0; i < list.length; i++) {
            final t = list[i];
            print('   [$i] ID: ${t['id']}, 플레이어(User): ${t['user_id']}, 점령시점: ${t['captured_at']}');
          }
          print('---------------------------------------------');
        }
      });

      if (duplicateCount == 0) {
        print('✓ 검사 결과: 실서버 데이터베이스 상에 동일 좌표 (q, r)가 중복 겹침 저장된 레코드는 존재하지 않습니다!');
        print('✓ 모든 타일이 고유한 1대1 정수 격자 좌표에 독립적으로 안착해 있습니다.');
      } else {
        print('🚨 검사 결과: 실서버 상에 좌표가 완전히 중복되어 겹쳐진 타일이 총 $duplicateCount개 발견되었습니다!');
      }
      print('=============================================');

    } catch (e) {
      print('❌ 분석 중 에러 발생: $e');
    }
  });
}
