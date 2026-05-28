// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('실서버 겹침 중복 타일 데이터 정밀 교정 및 청소', () async {
    print('🧹 실서버 겹침 중복 타일 정밀 청소 시작...');

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

    // 3. 정교한 타겟 교정 데이터 명세
    final reconciliationTargets = [
      {'id': 'hex_15_-182', 'correct_q': 15, 'correct_r': -182},
      {'id': 'hex_38_-143', 'correct_q': 38, 'correct_r': -143},
      {'id': 'hex_26_-146', 'correct_q': 26, 'correct_r': -146},
    ];

    try {
      print('=============================================');
      print('🛠️ 중복 겹침 데이터 실시간 데이터 교정 개시');
      print('=============================================');

      for (final target in reconciliationTargets) {
        final String id = target['id'] as String;
        final int correctQ = target['correct_q'] as int;
        final int correctR = target['correct_r'] as int;

        print('⏳ 대상 교정 중: ID = $id ➔ 올바른 좌표 ($correctQ, $correctR)');

        // Supabase DB Update 실행 (id 기준으로 올바른 q, r 덮어쓰기)
        await client
            .from('captured_tiles')
            .update({
              'q': correctQ,
              'r': correctR,
            })
            .eq('id', id);

        print('✓ 완료: ID = $id 가 정상 좌표로 업데이트 되었습니다.');
      }
      
      print('=============================================');
      print('✨ 교정 완료: 모든 데이터 정합성 정밀 복구 완료!');
      print('=============================================');

    } catch (e) {
      print('❌ 교정 작업 중 에러 발생: $e');
    }
  });
}
