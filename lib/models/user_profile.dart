class UserProfile {
  final String id;
  final String nickname;
  final String colorHex;
  final String teamId;
  final DateTime createdAt;
  final String? mainBaseTileId;
  final double totalDistance;
  final double dailyDistance;

  UserProfile({
    required this.id,
    required this.nickname,
    required this.colorHex,
    required this.teamId,
    required this.createdAt,
    this.mainBaseTileId,
    this.totalDistance = 0.0,
    this.dailyDistance = 0.0,
  });

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'color_hex': colorHex,
      // 'team_id': teamId, // DB에 컬럼이 추가될 때까지 주석 처리
      'created_at': createdAt.toIso8601String(),
      'main_base_tile_id': mainBaseTileId,
      'total_distance': totalDistance,
      'daily_distance': dailyDistance,
    };
  }

  UserProfile copyWith({
    String? id,
    String? nickname,
    String? colorHex,
    String? teamId,
    DateTime? createdAt,
    String? mainBaseTileId,
    double? totalDistance,
    double? dailyDistance,
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
    );
  }
}
