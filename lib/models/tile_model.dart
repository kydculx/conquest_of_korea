/// 점령된 헥사곤 타일 데이터 모델
class HexTile {
  final String id;
  final int q;
  final int r;
  final String? userId;
  final String? colorHex; // 점령 당시의 색상 혹은 실시간 동기화된 색상
  final List<List<double>> bounds;
  final DateTime capturedAt;

  const HexTile({
    required this.id,
    required this.q,
    required this.r,
    this.userId,
    this.colorHex,
    required this.bounds,
    required this.capturedAt,
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
          ? DateTime.parse(json['captured_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'q': q,
        'r': r,
        'user_id': userId,
        'color_hex': colorHex,
        'bounds': bounds,
        'captured_at': capturedAt.toIso8601String(),
        'capture_status': 'captured',
      };

  HexTile copyWith({String? userId, String? colorHex, List<List<double>>? bounds}) {
    return HexTile(
      id: id,
      q: q,
      r: r,
      userId: userId ?? this.userId,
      colorHex: colorHex ?? this.colorHex,
      bounds: bounds ?? this.bounds,
      capturedAt: capturedAt,
    );
  }
}
