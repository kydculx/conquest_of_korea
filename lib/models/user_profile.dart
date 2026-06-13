/// 플레이어의 프로필 및 점령 상태 정보를 담는 데이터 모델 클래스
class UserProfile {
  /// 플레이어의 고유 UUID 식별자
  final String id;

  /// 플레이어의 고유 닉네임
  final String nickname;

  /// 플레이어의 고유 테마 컬러 코드 (HEX 형태)
  final String colorHex;

  /// 플레이어의 소속 팀 식별자
  final String teamId;

  /// 계정 생성 일시
  final DateTime createdAt;

  /// 플레이어의 본진(본부)으로 지정된 H3 헥사곤 타일 인덱스
  final String? mainBaseTileId;

  /// 플레이어의 누적 이동 거리 (단위: 미터)
  final double totalDistance;

  /// 플레이어의 일일 이동 거리 (단위: 미터)
  final double dailyDistance;

  /// 플레이어의 현재 보유 골드 재화
  final double gold;

  /// 플레이어가 현재 점령 중인 타일의 총 개수
  final int capturedTilesCount;

  /// 하루 동안 이동한 헥사곤 타일 수
  final int dailyMovedTilesCount;

  /// 누적 전체 이동한 헥사곤 타일 수
  final int totalMovedTilesCount;

  /// 누적 적 영토 탈취 타일 수
  final int enemyCapturedTilesCount;

  /// 누적 위성 원격 점령 성공 횟수
  final int satelliteCaptureCount;

  /// 누적 위성 상세 정보 스캔 횟수
  final int satelliteScanCount;

  /// 본진 이동 횟수
  final int mainBaseMoveCount;

  /// 골드가 마지막으로 계산 및 갱신된 일시
  final DateTime? lastGoldUpdatedAt;

  /// 마지막으로 이동한 일시
  final DateTime? lastMovedAt;

  /// 서비스 이용약관 동의 시각
  final DateTime? termsAgreedAt;

  /// 개인정보 처리방침 동의 시각
  final DateTime? privacyAgreedAt;

  /// 위치 정보 이용약관 동의 시각
  final DateTime? locationAgreedAt;

  /// 마케팅 수신 정책 동의 시각
  final DateTime? marketingAgreedAt;

  /// 알림 동의 활성화 여부
  final bool isNotificationsEnabled;

  /// 영토 변경 알림 동의 여부
  final bool notifTerritoryAttack;

  /// 위성 점령 완료 알림 동의 여부
  final bool notifSatelliteComplete;

  /// 시스템 공지 알림 동의 여부
  final bool notifSystemNotice;

  /// 플레이어의 마지막 로그인 세션 식별자
  final String? lastSessionId;

  /// UserProfile 생성자
  UserProfile({
    required this.id,
    required this.nickname,
    required this.colorHex,
    required this.teamId,
    required this.createdAt,
    this.mainBaseTileId,
    this.totalDistance = 0.0,
    this.dailyDistance = 0.0,
    this.termsAgreedAt,
    this.privacyAgreedAt,
    this.locationAgreedAt,
    this.marketingAgreedAt,
    this.isNotificationsEnabled = true,
    this.notifTerritoryAttack = true,
    this.notifSatelliteComplete = true,
    this.notifSystemNotice = true,
    this.gold = 0.0,
    this.capturedTilesCount = 0,
    this.dailyMovedTilesCount = 0,
    this.totalMovedTilesCount = 0,
    this.enemyCapturedTilesCount = 0,
    this.satelliteCaptureCount = 0,
    this.satelliteScanCount = 0,
    this.mainBaseMoveCount = 0,
    this.lastGoldUpdatedAt,
    this.lastMovedAt,
    this.lastSessionId,
  });

  /// Map 구조의 JSON 데이터로부터 UserProfile 인스턴스를 생성하는 팩토리 메서드
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final lastMovedAtStr = json['last_moved_at'] as String?;
    final lastMovedAt = lastMovedAtStr != null ? DateTime.parse(lastMovedAtStr) : null;

    // UTC 자정 리셋 여부 판정
    bool isNewDay = false;
    if (lastMovedAt != null) {
      final nowUtc = DateTime.now().toUtc();
      final lastMovedUtc = lastMovedAt.toUtc();
      if (lastMovedUtc.year != nowUtc.year ||
          lastMovedUtc.month != nowUtc.month ||
          lastMovedUtc.day != nowUtc.day) {
        isNewDay = true;
      }
    }

    return UserProfile(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      colorHex: json['color_hex'] as String,
      teamId: json['team_id'] as String? ?? 'none',
      createdAt: DateTime.parse(json['created_at'] as String),
      mainBaseTileId: json['main_base_tile_id'] as String?,
      totalDistance: (json['total_distance'] as num?)?.toDouble() ?? 0.0,
      dailyDistance: isNewDay ? 0.0 : ((json['daily_distance'] as num?)?.toDouble() ?? 0.0),
      gold: (json['gold'] as num?)?.toDouble() ?? 0.0,
      capturedTilesCount: (json['captured_tiles_count'] as num?)?.toInt() ?? 0,
      dailyMovedTilesCount: isNewDay ? 0 : ((json['daily_moved_tiles_count'] as num?)?.toInt() ?? 0),
      totalMovedTilesCount: (json['total_moved_tiles_count'] as num?)?.toInt() ?? 0,
      enemyCapturedTilesCount: (json['enemy_captured_tiles_count'] as num?)?.toInt() ?? 0,
      satelliteCaptureCount: (json['satellite_capture_count'] as num?)?.toInt() ?? 0,
      satelliteScanCount: (json['satellite_scan_count'] as num?)?.toInt() ?? 0,
      mainBaseMoveCount: (json['main_base_move_count'] as num?)?.toInt() ?? 0,
      lastGoldUpdatedAt: json['last_gold_updated_at'] != null
          ? DateTime.parse(json['last_gold_updated_at'] as String)
          : null,
      lastMovedAt: lastMovedAt,
      termsAgreedAt: json['terms_agreed_at'] != null
          ? DateTime.parse(json['terms_agreed_at'] as String)
          : null,
      privacyAgreedAt: json['privacy_agreed_at'] != null
          ? DateTime.parse(json['privacy_agreed_at'] as String)
          : null,
      locationAgreedAt: json['location_agreed_at'] != null
          ? DateTime.parse(json['location_agreed_at'] as String)
          : null,
      marketingAgreedAt: json['marketing_agreed_at'] != null
          ? DateTime.parse(json['marketing_agreed_at'] as String)
          : null,
      isNotificationsEnabled: json['is_notifications_enabled'] as bool? ?? true,
      notifTerritoryAttack: json['notif_territory_attack'] as bool? ?? true,
      notifSatelliteComplete: json['notif_satellite_complete'] as bool? ?? true,
      notifSystemNotice: json['notif_system_notice'] as bool? ?? true,
      lastSessionId: json['last_session_id'] as String?,
    );
  }

  /// UserProfile 인스턴스를 Map 구조의 JSON 데이터로 변환하여 반환합니다.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'color_hex': colorHex,
      // 'team_id': teamId, // DB에 컬럼이 추가될 때까지 주석 처리
      'created_at': createdAt.toIso8601String(),
      'main_base_tile_id': mainBaseTileId,
      'gold': gold,
      'captured_tiles_count': capturedTilesCount,
      'daily_moved_tiles_count': dailyMovedTilesCount,
      'total_moved_tiles_count': totalMovedTilesCount,
      'enemy_captured_tiles_count': enemyCapturedTilesCount,
      'satellite_capture_count': satelliteCaptureCount,
      'satellite_scan_count': satelliteScanCount,
      'main_base_move_count': mainBaseMoveCount,
      'last_gold_updated_at': lastGoldUpdatedAt?.toIso8601String(),
      'last_moved_at': lastMovedAt?.toIso8601String(),
      'terms_agreed_at': termsAgreedAt?.toIso8601String(),
      'privacy_agreed_at': privacyAgreedAt?.toIso8601String(),
      'location_agreed_at': locationAgreedAt?.toIso8601String(),
      'marketing_agreed_at': marketingAgreedAt?.toIso8601String(),
      'is_notifications_enabled': isNotificationsEnabled,
      'notif_territory_attack': notifTerritoryAttack,
      'notif_satellite_complete': notifSatelliteComplete,
      'notif_system_notice': notifSystemNotice,
      'last_session_id': lastSessionId,
    };
  }

  /// 데이터베이스 업데이트 시 재화 및 점령 타일 수 등 시스템 관리 필드를 제외한
  /// 프로필 기본 속성 변경을 처리하기 위해 사용하는 JSON 변환 메서드입니다.
  Map<String, dynamic> toUpdateJson() {
    return {
      'id': id,
      'nickname': nickname,
      'color_hex': colorHex,
      'created_at': createdAt.toIso8601String(),
      'main_base_tile_id': mainBaseTileId,
      'terms_agreed_at': termsAgreedAt?.toIso8601String(),
      'privacy_agreed_at': privacyAgreedAt?.toIso8601String(),
      'location_agreed_at': locationAgreedAt?.toIso8601String(),
      'marketing_agreed_at': marketingAgreedAt?.toIso8601String(),
      'is_notifications_enabled': isNotificationsEnabled,
      'notif_territory_attack': notifTerritoryAttack,
      'notif_satellite_complete': notifSatelliteComplete,
      'notif_system_notice': notifSystemNotice,
    };
  }

  /// 지정한 속성값들로 새 프로필 객체를 생성하여 반환합니다.
  UserProfile copyWith({
    String? id,
    String? nickname,
    String? colorHex,
    String? teamId,
    DateTime? createdAt,
    String? mainBaseTileId,
    double? totalDistance,
    double? dailyDistance,
    DateTime? termsAgreedAt,
    DateTime? privacyAgreedAt,
    DateTime? locationAgreedAt,
    DateTime? marketingAgreedAt,
    bool? isNotificationsEnabled,
    bool? notifTerritoryAttack,
    bool? notifSatelliteComplete,
    bool? notifSystemNotice,
    double? gold,
    int? capturedTilesCount,
    int? dailyMovedTilesCount,
    int? totalMovedTilesCount,
    int? enemyCapturedTilesCount,
    int? satelliteCaptureCount,
    int? satelliteScanCount,
    int? mainBaseMoveCount,
    DateTime? lastGoldUpdatedAt,
    DateTime? lastMovedAt,
    String? lastSessionId,
  }) {
    return UserProfile(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      colorHex: colorHex ?? this.colorHex,
      teamId: teamId ?? this.teamId,
      createdAt: createdAt ?? this.createdAt,
      mainBaseTileId: mainBaseTileId ?? this.mainBaseTileId,
      totalDistance: totalDistance ?? this.totalDistance,
      dailyDistance: dailyDistance ?? this.dailyDistance,
      termsAgreedAt: termsAgreedAt ?? this.termsAgreedAt,
      privacyAgreedAt: privacyAgreedAt ?? this.privacyAgreedAt,
      locationAgreedAt: locationAgreedAt ?? this.locationAgreedAt,
      marketingAgreedAt: marketingAgreedAt ?? this.marketingAgreedAt,
      isNotificationsEnabled:
          isNotificationsEnabled ?? this.isNotificationsEnabled,
      notifTerritoryAttack: notifTerritoryAttack ?? this.notifTerritoryAttack,
      notifSatelliteComplete:
          notifSatelliteComplete ?? this.notifSatelliteComplete,
      notifSystemNotice: notifSystemNotice ?? this.notifSystemNotice,
      gold: gold ?? this.gold,
      capturedTilesCount: capturedTilesCount ?? this.capturedTilesCount,
      dailyMovedTilesCount: dailyMovedTilesCount ?? this.dailyMovedTilesCount,
      totalMovedTilesCount: totalMovedTilesCount ?? this.totalMovedTilesCount,
      enemyCapturedTilesCount: enemyCapturedTilesCount ?? this.enemyCapturedTilesCount,
      satelliteCaptureCount: satelliteCaptureCount ?? this.satelliteCaptureCount,
      satelliteScanCount: satelliteScanCount ?? this.satelliteScanCount,
      mainBaseMoveCount: mainBaseMoveCount ?? this.mainBaseMoveCount,
      lastGoldUpdatedAt: lastGoldUpdatedAt ?? this.lastGoldUpdatedAt,
      lastMovedAt: lastMovedAt ?? this.lastMovedAt,
      lastSessionId: lastSessionId ?? this.lastSessionId,
    );
  }
}
