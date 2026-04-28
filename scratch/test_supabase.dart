import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  const url = 'https://aojbgfdwqlcveffsushg.supabase.co';
  const anonKey = 'sb_publishable_L3mPqH_ppkHkPf93dennYQ_EuALXjnG';

  print('Supabase 연결 시도 중...');
  try {
    await Supabase.initialize(url: url, anonKey: anonKey);
    final client = Supabase.instance.client;
    
    print('데이터 가져오는 중...');
    final response = await client.from('captured_tiles').select('*').limit(5);
    print('성공! 데이터: $response');
  } catch (e) {
    print('연결 실패: $e');
  }
}
