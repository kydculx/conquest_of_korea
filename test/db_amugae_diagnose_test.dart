// ⚠️ 실서버 검증용 임시 테스트: 아무개 계정 진단
// 실행: flutter test test/db_amugae_diagnose_test.dart
// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('아무개 계정 점령 저장 이력 진단', () async {
    final envFile = File('.env');
    final envContent = await envFile.readAsLines();
    String? url;
    String? anonKey;
    for (var line in envContent) {
      if (line.startsWith('SUPABASE_URL=')) {
        url = line.substring('SUPABASE_URL='.length).trim();
      } else if (line.startsWith('SUPABASE_ANON_KEY=')) {
        anonKey = line.substring('SUPABASE_ANON_KEY='.length).trim();
      }
    }
    final client = SupabaseClient(url!, anonKey!);

    // 1. '아무개' 닉네임 검색
    final amugae = await client
        .from('profiles')
        .select('id, nickname, created_at, captured_tiles_count, main_base_tile_id, last_session_id, last_moved_at')
        .ilike('nickname', '%아무개%');
    print('👤 아무개 검색 결과 (${amugae.length}건):');
    for (final p in amugae) {
      print('   - ID: ${p['id']} | 닉네임: ${p['nickname']} | 생성: ${p['created_at']} | 카운터: ${p['captured_tiles_count']}');
    }

    // 2. 모든 프로필 목록 (닉네임 확인용)
    final allProfiles = await client
        .from('profiles')
        .select('id, nickname, created_at, captured_tiles_count')
        .limit(100);
    print('📋 전체 프로필 (최대 100):');
    for (final p in allProfiles) {
      print('   - ${p['nickname']} | ${p['id']} | 생성: ${p['created_at']} | 카운터: ${p['captured_tiles_count']}');
    }

    // 3. 아무개 계정의 타일 존재 여부
    if (amugae.isNotEmpty) {
      final uid = amugae.first['id'] as String;
      final tiles = await client
          .from('captured_tiles')
          .select('id, q, r, captured_at')
          .eq('user_id', uid);
      print('🗺️ 아무개 타일: ${tiles.length}개');
      for (final t in tiles.take(20)) {
        print('   - ${t['id']} | ${t['captured_at']}');
      }
    }
  });
}
