/// 인게임 비즈니스 로직 및 시스템의 수치 상수를 관리하는 설정 클래스
class GameConfig {
  /// 애플리케이션 시스템 공식 명칭
  static const String appName = '찜! 대모험 (Dibs Adventure)';

  /// 초당 1개 타일당 획득 가능한 기본 골드 배율
  static const double defaultGoldRate = 1.0;

  /// 지도 상에 렌더링될 헥사곤 타일의 기준 크기 (미터 단위)
  static const double tileSize = 100.0;

  /// 점령이 가능한 물리적 GPS 허용 정확도 임계치 (15.0m 이내)
  static const double captureAccuracyThreshold = 15.0;

  /// 높은 GPS 정확도를 판단하는 기준 임계치 (10.0m 이내)
  static const double highAccuracyThreshold = 10.0;

  /// 중립(빈) 타일 점령 소요 시간
  static const Duration emptyTileDuration = Duration(seconds: 3);

  /// 적군 소유 타일 침공(점령) 소요 시간
  static const Duration enemyTileDuration = Duration(seconds: 10);

  /// 점령 상태 게이지 업데이트 주기 (밀리초 단위)
  static const int updateIntervalMs = 100;

  /// 물리 GPS 좌표 기준 점령이 가능한 최대 반경 거리 임계치 (미터 단위)
  static const double captureDistanceThreshold = 40.0;

  /// 위성 점령 시 1개 타일당 소요되는 시간 (초)
  static const double satelliteCaptureSecondsPerTile = 1.0;

  /// 위성 점령 완료 후 재사용 대기 시간 (쿨타임)
  static const Duration satelliteCaptureCooltime = Duration(seconds: 10);

  /// 골드 재화 자동 누적 타이머 주기 (초)
  static const int goldTimerIntervalSeconds = 1;

  /// GPS 하드웨어 폴링 간격 (초) — 안드로이드 네이티브 LocationRequest.interval
  static const int gpsUpdateIntervalSeconds = 1;

  /// GPS 예열(warm-up) 최대 대기 시간 (초)
  static const int gpsWarmupTimeoutSeconds = 5;

  /// 위치 업데이트 최소 이동 거리 필터 (미터)
  static const int gpsDistanceFilterMeters = 3;

  /// 마지막 위치 업데이트로부터 신호 유실로 간주하는 타임아웃 (초)
  static const int gpsSignalLostTimeoutSeconds = 10;

  /// GPS 재시작 전 하드웨어 안정화 대기 시간 (밀리초)
  static const int gpsRestartDelayMs = 500;

  /// Supabase Auth 토큰 동기화 대기 시간 (밀리초)
  static const int authTokenSyncDelayMs = 300;

  /// 화면 상단 알림(alert) 자동 제거 시간 (초)
  static const int alertDismissDurationSeconds = 3;

  /// 서버 부하 방지를 위해 점령 요청 후 대기하는 딜레이 시간
  static const Duration serverCheckDelay = Duration(seconds: 3);

  /// 백그라운드 상태에서 위치 및 상태를 확인하는 체크 주기
  static const Duration backgroundCheckInterval = Duration(seconds: 30);

  /// 지도에 그려질 점령 타일의 불투명도 레벨 (0.0 ~ 1.0)
  static const double tileOpacity = 0.5;

  /// 인게임 HUD 오버레이의 투명도 레벨 (0.0 ~ 1.0)
  static const double hudOpacity = 0.8;

  /// 점령 완료 후 해당 타일이 적의 침공으로부터 보호(쉴드)를 유지하는 지속 시간 (초)
  static const int tileShieldDurationSeconds = 5;

  /// 점령 시작 시 최초 점령에 소요되는 기준 시간 (초 단위)
  static const int initialCaptureDurationSeconds = 1;

  /// 상대 타일 정보 보안 해제(Reveal) 유효 지속 시간 (초 단위 - 10분)
  static const int tileRevealDurationSeconds = 600;

  /// 스플래시 화면 최소 유지 시간
  static const Duration splashDuration = Duration(seconds: 3);

  /// LOD 0 단계 타일 규격 크기 (100m)
  static const double lodSize0 = 100.0;

  /// LOD 1 단계 타일 규격 크기 (200m)
  static const double lodSize1 = 200.0;

  /// LOD 2 단계 타일 규격 크기 (400m)
  static const double lodSize2 = 400.0;

  /// LOD 3 단계 타일 규격 크기 (800m - 적군 은폐 가드 작동)
  static const double lodSize3 = 800.0;

  /// LOD 4 단계 타일 규격 크기 (1600m - 적군 은폐 가드 작동)
  static const double lodSize4 = 1600.0;

  /// LOD 0 단계(100m 정밀 타일)가 활성화되는 최소 줌 레벨 임계치 (화면 가로 400m 거리 축척 대응)
  static const double lodZoomThreshold0 = 13.5;

  /// LOD 1 단계(200m 타일)가 활성화되는 최소 줌 레벨 임계치
  static const double lodZoomThreshold1 = 12.0;

  /// LOD 2 단계(400m 타일)가 활성화되는 최소 줌 레벨 임계치
  static const double lodZoomThreshold2 = 10.5;

  /// LOD 3 단계(800m 타일)가 활성화되는 최소 줌 레벨 임계치
  static const double lodZoomThreshold3 = 8.5;
}
