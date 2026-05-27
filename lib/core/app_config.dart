import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 앱 환경 설정 중앙 관리 클래스
class AppConfig {
  /// 인스턴스화 방지를 위한 private 생성자
  AppConfig._();

  /// Supabase 연결 URL (환경 변수 로드)
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  /// Supabase 익명 API 키 (환경 변수 로드)
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// 구글 웹 클라이언트 ID (환경 변수 로드)
  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

  /// 구글 iOS 클라이언트 ID (환경 변수 로드)
  static String get googleIosClientId =>
      dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '';
}
