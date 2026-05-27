/// 사용자 에이전트의 프로필 및 전술 상태 정보를 담는 데이터 모델 클래스
class UserProfile {
  /// 요원의 고유 UUID 식별자
  final String id;

  /// 요원의 고유 닉네임
  final String nickname;

  /// 요원의 고유 전술 컬러 코드 (HEX 형태)
  final String colorHex;

  /// 요원의 소속 팀 식별자
  final String teamId;

  /// 계정 생성 일시
  final DateTime createdAt;

  /// 요원의 본진(작전 본부)으로 지정된 H3 헥사곤 타일 인덱스
  final String? mainBaseTileId;

  /// 요원의 누적 이동 거리 (단위: 미터)
  final double totalDistance;

  /// 요원의 일일 이동 거리 (단위: 미터)
  final double dailyDistance;

  /// 요원의 현재 보유 골드 재화
  final double gold;

  /// 요원이 현재 점령 중인 타일의 총 개수
  final int capturedTilesCount;

  /// 골드가 마지막으로 계산 및 갱신된 일시
  final DateTime? lastGoldUpdatedAt;

  /// 서비스 이용약관 동의 시각
  final DateTime? termsAgreedAt;

  /// 개인정보 처리방침 동의 시각
  final DateTime? privacyAgreedAt;

  /// 위치 정보 이용약관 동의 시각
  final DateTime? locationAgreedAt;

  /// 마케팅 수신 정책 동의 시각
  final DateTime? marketingAgreedAt;

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
    this.gold = 0.0,
    this.capturedTilesCount = 0,
    this.lastGoldUpdatedAt,
  });

  /// Map 구조의 JSON 데이터로부터 UserProfile 인스턴스를 생성하는 팩토리 메서드
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      colorHex: json['color_hex'] as String,
      teamId: json['team_id'] as String? ?? 'none',
      createdAt: DateTime.parse(json['created_at'] as String),
      mainBaseTileId: json['main_base_tile_id'] as String?,
      totalDistance: (json['total_distance'] as num?)?.toDouble() ?? 0.0,
      dailyDistance: (json['daily_distance'] as num?)?.toDouble() ?? 0.0,
      gold: (json['gold'] as num?)?.toDouble() ?? 0.0,
      capturedTilesCount: (json['captured_tiles_count'] as num?)?.toInt() ?? 0,
      lastGoldUpdatedAt: json['last_gold_updated_at'] != null
          ? DateTime.parse(json['last_gold_updated_at'] as String)
          : null,
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
      'last_gold_updated_at': lastGoldUpdatedAt?.toIso8601String(),
      'terms_agreed_at': termsAgreedAt?.toIso8601String(),
      'privacy_agreed_at': privacyAgreedAt?.toIso8601String(),
      'location_agreed_at': locationAgreedAt?.toIso8601String(),
      'marketing_agreed_at': marketingAgreedAt?.toIso8601String(),
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
    double? gold,
    int? capturedTilesCount,
    DateTime? lastGoldUpdatedAt,
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
      gold: gold ?? this.gold,
      capturedTilesCount: capturedTilesCount ?? this.capturedTilesCount,
      lastGoldUpdatedAt: lastGoldUpdatedAt ?? this.lastGoldUpdatedAt,
    );
  }
}
