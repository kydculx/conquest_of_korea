/// 플레이어가 맵 상에서 획득할 수 있는 동전 아이템의 정보를 담는 데이터 모델 클래스입니다.
class UserCoin {
  /// 동전의 소유 플레이어 ID
  final String userId;

  /// 동전이 위치한 헥사곤 타일 ID
  final String tileId;

  /// 헥사곤 격자 좌표 q
  final int q;

  /// 헥사곤 격자 좌표 r
  final int r;

  /// 동전 획득 완료 여부
  final bool isCollected;

  /// 동전 생성 일시
  final DateTime createdAt;

  /// 동전 획득 일시 (획득 전일 시 null)
  final DateTime? collectedAt;

  UserCoin({
    required this.userId,
    required this.tileId,
    required this.q,
    required this.r,
    this.isCollected = false,
    required this.createdAt,
    this.collectedAt,
  });

  /// Supabase에서 가져온 JSON Map 객체를 UserCoin 인스턴스로 변환합니다.
  factory UserCoin.fromJson(Map<String, dynamic> json) {
    return UserCoin(
      userId: json['user_id'] as String,
      tileId: json['tile_id'] as String,
      q: json['q'] as int,
      r: json['r'] as int,
      isCollected: json['is_collected'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      collectedAt: json['collected_at'] != null
          ? DateTime.parse(json['collected_at'] as String).toLocal()
          : null,
    );
  }

  /// UserCoin 인스턴스를 Supabase 전송용 JSON Map 객체로 변환합니다.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'tile_id': tileId,
      'q': q,
      'r': r,
      'is_collected': isCollected,
      'created_at': createdAt.toUtc().toIso8601String(),
      'collected_at': collectedAt?.toUtc().toIso8601String(),
    };
  }
}
