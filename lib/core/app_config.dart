/// 앱 환경 설정 중앙 관리
/// TODO: 추후 flutter_dotenv 패키지로 .env 파일에서 로드하도록 전환 가능
class AppConfig {
  AppConfig._();

  // Supabase 연결 정보
  static const String supabaseUrl = 'https://aojbgfdwqlcveffsushg.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_L3mPqH_ppkHkPf93dennYQ_EuALXjnG';
}
