/// 인게임 비즈니스 로직 및 전술 시스템의 수치 상수를 관리하는 설정 클래스
class GameConfig {
  /// 애플리케이션 시스템 공식 명칭
  static const String appName = '한국정복 (Conquest)';

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
  static const Duration satelliteCaptureCooltime = Duration(
    seconds: 10,
  );

  /// 서버 부하 방지를 위해 점령 요청 후 대기하는 딜레이 시간
  static const Duration serverCheckDelay = Duration(seconds: 3);

  /// 백그라운드 상태에서 위치 및 상태를 확인하는 체크 주기
  static const Duration backgroundCheckInterval = Duration(
    seconds: 30,
  );
  
  /// 지도에 그려질 점령 타일의 불투명도 레벨 (0.0 ~ 1.0)
  static const double tileOpacity = 0.5;

  /// 인게임 HUD 오버레이의 투명도 레벨 (0.0 ~ 1.0)
  static const double hudOpacity = 0.8;

  /// 점령 완료 후 해당 타일이 적의 침공으로부터 보호(쉴드)를 유지하는 지속 시간 (초)
  static const int tileShieldDurationSeconds = 5;

  /// 작전 개시 시 최초 점령에 소요되는 기준 시간 (초 단위)
  static const int initialCaptureDurationSeconds = 1;
}
