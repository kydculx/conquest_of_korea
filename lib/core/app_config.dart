import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 앱 환경 설정 중앙 관리
class AppConfig {
  AppConfig._();

  // Supabase 연결 정보 (환경 변수에서 로드)
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}
