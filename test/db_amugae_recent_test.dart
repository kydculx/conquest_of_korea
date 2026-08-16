// ⚠️ 실서버 검증용 임시 테스트: 아무개 계정 최신 저장 시각 진단
// 실행: flutter test test/db_amugae_recent_test.dart
// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('아무개 계정 최신 타일 저장 시각 + 오늘 저장분 확인', () async {
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
    const amugaeId = '61ae25cb-98cc-44f0-bb6a-140d22ae9fbf';

    // 1. 아무개 타일 정확한 수
    final countRes = await client
        .from('captured_tiles')
        .select('id')
        .eq('user_id', amugaeId)
        .count(CountOption.exact);
    print('📦 아무개 타일 정확한 수: ${countRes.count}');

    // 2. 아무개 최신 타일 15개 (내림차순)
    final latest = await client
        .from('captured_tiles')
        .select('id, q, r, captured_at')
        .eq('user_id', amugaeId)
        .order('captured_at', ascending: false)
        .limit(15);
    print('🕐 아무개 최신 타일 15개:');
    for (final t in latest) {
      print('   - ${t['id']} | ${t['captured_at']}');
    }

    // 3. 오늘(8/8 00:00 UTC 이후) 저장된 모든 타일
    final todayStart = '2026-08-08T00:00:00.000Z';
    final todayTiles = await client
        .from('captured_tiles')
        .select('id, user_id, captured_at')
        .gte('captured_at', todayStart);
    print('🕐 8/8 00:00 UTC 이후 저장 타일: ${todayTiles.length}개');
    for (final t in todayTiles.take(30)) {
      final uid = t['user_id']?.toString() ?? 'NULL';
      final nick = uid == amugaeId ? '아무개' : (uid == '797ff494-3a4e-4b82-a75e-ff2e18d2bd6e' ? 'Zepoli' : uid.substring(0, 8));
      print('   - ${t['id']} | $nick | ${t['captured_at']}');
    }
  });
}
