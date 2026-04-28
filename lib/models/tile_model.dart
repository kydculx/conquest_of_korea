/// 헥사곤 타일 소유 팀 열거형
enum TileOwner {
  blue('blue'),
  red('red'),
  none('none');

  final String id;
  const TileOwner(this.id);

  static TileOwner fromString(String? value) {
    return TileOwner.values.firstWhere(
      (e) => e.id == value,
      orElse: () => TileOwner.none,
    );
  }
}

/// 점령된 헥사곤 타일 데이터 모델
class HexTile {
  final String id;
  final int q;
  final int r;
  final TileOwner owner;
  final List<List<double>> bounds;
  final DateTime capturedAt;

  const HexTile({
    required this.id,
    required this.q,
    required this.r,
    required this.owner,
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
      owner: TileOwner.fromString(json['owner'] as String?),
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
        'owner': owner.id,
        'bounds': bounds,
        'captured_at': capturedAt.toIso8601String(),
        'capture_status': 'captured',
      };

  HexTile copyWith({TileOwner? owner, List<List<double>>? bounds}) {
    return HexTile(
      id: id,
      q: q,
      r: r,
      owner: owner ?? this.owner,
      bounds: bounds ?? this.bounds,
      capturedAt: capturedAt,
    );
  }
}
