// ⚠️ 실서버 검증용 임시 테스트: Zepoli 타일 저장 이력 + 오늘 저장분 + 전체 정확한 수
// 실행: flutter test test/db_zepoli_diagnose_test.dart
// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Zepoli 타일 이력 및 최근 저장 현황 정밀 진단', () async {
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

    // 1. 전체 정확한 타일 수 (count exact)
    final countRes = await client
        .from('captured_tiles')
        .select('id')
        .count(CountOption.exact);
    print('📦 전체 captured_tiles 정확한 수: ${countRes.count}');

    // 2. Zepoli의 모든 타일
    final zepoliTiles = await client
        .from('captured_tiles')
        .select('id, q, r, captured_at, capture_count')
        .eq('user_id', '797ff494-3a4e-4b82-a75e-ff2e18d2bd6e');
    print('👤 Zepoli 실제 타일 (${zepoliTiles.length}개):');
    for (final t in zepoliTiles) {
      print('   - ${t['id']} | q=${t['q']} r=${t['r']} | ${t['captured_at']} | count=${t['capture_count']}');
    }

    // 3. 오늘(8/8~8/9) 저장된 타일 — 사용자별
    final todayStart = DateTime.now().toUtc().subtract(const Duration(days: 2)).toIso8601String();
    final today = await client
        .from('captured_tiles')
        .select('id, user_id, captured_at')
        .gte('captured_at', todayStart);
    print('🕐 최근 2일 저장 타일: ${today.length}개');
    final Map<String, int> byUser = {};
    for (final t in today) {
      final uid = t['user_id']?.toString() ?? 'NULL';
      byUser[uid] = (byUser[uid] ?? 0) + 1;
    }
    byUser.forEach((uid, c) => print('   - $uid: $c개'));

    // 4. Zepoli 프로필 카운터 + 최근 활동
    final zepoli = await client
        .from('profiles')
        .select('id, nickname, captured_tiles_count, total_distance, daily_moved_tiles_count, last_moved_at, last_session_id')
        .eq('id', '797ff494-3a4e-4b82-a75e-ff2e18d2bd6e')
        .single();
    print('👤 Zepoli 프로필: $zepoli');
  });
}
