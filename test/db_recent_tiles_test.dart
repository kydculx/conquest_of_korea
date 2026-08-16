// ⚠️ 실서버 검증용 임시 테스트: 최근 타일 저장 이력 진단
// 실행: flutter test test/db_recent_tiles_test.dart
// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('captured_tiles 최근 저장 이력 및 사용자별 저장 상태 진단', () async {
    final envFile = File('.env');
    expect(envFile.existsSync(), isTrue);
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

    // 1. 전체 타일 수 + 날짜 분포
    final all = await client.from('captured_tiles').select('id, user_id, captured_at');
    print('📦 전체 captured_tiles 수: ${all.length}');

    // 2. 최근 30일 저장분
    final thirtyDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 30)).toIso8601String();
    final recent = await client
        .from('captured_tiles')
        .select('id, user_id, captured_at')
        .gte('captured_at', thirtyDaysAgo);
    print('🕐 최근 30일 저장된 타일: ${recent.length}개');
    for (var t in recent.take(10)) {
      print('   - ${t['id']} | user=${t['user_id']} | ${t['captured_at']}');
    }

    // 3. 최근 7일 저장분
    final sevenDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 7)).toIso8601String();
    final week = await client
        .from('captured_tiles')
        .select('id, user_id, captured_at')
        .gte('captured_at', sevenDaysAgo);
    print('🕐 최근 7일 저장된 타일: ${week.length}개');

    // 4. 각 사용자별 타일 수 집계 (captured_tiles_count와 대조)
    final Map<String, int> perUser = {};
    for (final t in all) {
      final uid = t['user_id']?.toString() ?? 'NULL';
      perUser[uid] = (perUser[uid] ?? 0) + 1;
    }
    print('👥 사용자별 실제 타일 수:');
    perUser.forEach((uid, count) => print('   - $uid: $count개'));

    // 5. Zepoli(797ff494) 프로필 카운터와 실제 타일 수 대조
    final zepoli = await client
        .from('profiles')
        .select('id, nickname, captured_tiles_count')
        .eq('id', '797ff494-3a4e-4b82-a75e-ff2e18d2bd6e')
        .maybeSingle();
    print('👤 Zepoli 프로필 카운터: ${zepoli?['captured_tiles_count']} / 실제 타일: ${perUser['797ff494-3a4e-4b82-a75e-ff2e18d2bd6e'] ?? 0}');
  });
}
