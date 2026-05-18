import '../core/constants.dart';

/// 현재 위치 타일의 점령 상태 (서버 기준)
enum TileStatus {
  mine,   // 내가 점령한 타일
  empty,  // 아무도 점령하지 않은 빈 타일
  enemy,  // 상대방이 점령한 타일
}

/// 점령된 헥사곤 타일 데이터 모델
class HexTile {
  final String id;
  final int q;
  final int r;
  final String? userId;
  final String? colorHex; // 점령 당시의 색상 혹은 실시간 동기화된 색상
  final List<List<double>> bounds;
  final DateTime capturedAt;
  final int captureCount; // 각 타일마다 점령된 총 횟수

  const HexTile({
    required this.id,
    required this.q,
    required this.r,
    this.userId,
    this.colorHex,
    required this.bounds,
    required this.capturedAt,
    this.captureCount = 1, // 최초 점령 시 기본값은 1
  });

  factory HexTile.fromJson(Map<String, dynamic> json) {
    final rawBounds = json['bounds'];
    final bounds = rawBounds is List
        ? rawBounds
            .map((b) => (b as List).map((e) => (e as num).toDouble()).toList())
            .toList()
        : <List<double>>[];

    return HexTile(
      id: json['id'] as String,
      q: json['q'] as int,
      r: json['r'] as int,
      userId: json['user_id'] as String?,
      colorHex: json['color_hex'] as String?,
      bounds: bounds,
      capturedAt: json['captured_at'] != null
          ? DateTime.parse(json['captured_at'] as String).toUtc()
          : DateTime.now().toUtc(),
      captureCount: json['capture_count'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'q': q,
        'r': r,
        'user_id': userId,
        'color_hex': colorHex,
        'bounds': bounds,
        'captured_at': capturedAt.toUtc().toIso8601String(),
        'capture_status': 'captured',
        'capture_count': captureCount,
      };

  HexTile copyWith({
    String? userId,
    String? colorHex,
    List<List<double>>? bounds,
    int? captureCount,
  }) {
    return HexTile(
      id: id,
      q: q,
      r: r,
      userId: userId ?? this.userId,
      colorHex: colorHex ?? this.colorHex,
      bounds: bounds ?? this.bounds,
      capturedAt: capturedAt,
      captureCount: captureCount ?? this.captureCount,
    );
  }

  /// 쉴드 만료 시각 (captured_at + tileShieldDurationSeconds)
  DateTime get shieldExpiration => capturedAt.add(
        const Duration(seconds: GameConstants.tileShieldDurationSeconds),
      );

  /// 현재 시각 기준 쉴드가 활성 상태인지 여부
  bool get isShieldActive => DateTime.now().toUtc().isBefore(shieldExpiration);
}
