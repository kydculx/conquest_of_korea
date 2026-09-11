/// 어드민 맵 에디터에서 정의한 타일 속성(랜드마크 / 차단 구역 등) 관련 데이터 모델.
///
/// - [TileType]: `map_tile_types` 테이블의 한 행 (이름, 색상, 차단 여부 등)
/// - [TileAttribute]: `map_tile_attributes` 테이블의 한 행 (특정 헥사 타일에 부여된 속성)
library;

/// 어드민이 정의한 타일 타입 (예: 기본=0, 랜드마크=1).
///
/// DB 스키마: `public.map_tile_types`
///   id          int          PK
///   name        text         표시 이름
///   color_hex   text         #RRGGBB 형식의 헥사 색상 코드
///   description text?        설명
///   is_blocked  bool?        차단(진입 불가) 여부
class TileType {
  /// 타입 고유 번호 (0=기본, 1=랜드마크, ...)
  final int id;

  /// 표시 이름
  final String name;

  /// 색상 코드 (`#RRGGBB` 또는 `#AARRGGBB`)
  final String colorHex;

  /// 부가 설명
  final String? description;

  /// 차단 구역 여부
  final bool isBlocked;

  const TileType({
    required this.id,
    required this.name,
    required this.colorHex,
    this.description,
    this.isBlocked = false,
  });

  /// Supabase 응답(Map)으로부터 [TileType] 인스턴스를 생성합니다.
  factory TileType.fromJson(Map<String, dynamic> json) {
    return TileType(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
      colorHex: (json['color_hex'] as String?) ?? '',
      description: json['description'] as String?,
      isBlocked: (json['is_blocked'] as bool?) ?? false,
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color_hex': colorHex,
        'description': description,
        'is_blocked': isBlocked,
      };
}

/// 어드민이 특정 헥사 타일에 부여한 속성.
///
/// DB 스키마: `public.map_tile_attributes`
///   id         text        PK  ("q_r" 형식, 예: "5_3")
///   q          int         헥사 q축
///   r          int         헥사 r축
///   type_id    int         map_tile_types.id 참조 (default 0)
///   memo       text?       어드민이 남긴 메모
///   updated_at timestamptz 마지막 수정 시각
class TileAttribute {
  /// 어드민이 사용하는 원본 ID (예: "5_3").
  ///
  /// 모바일 앱의 [HexTile.id]는 `hex_5_3` 형식이므로,
  /// 조회 시 [_normalizeId]로 동일 포맷으로 변환하여 매칭합니다.
  final String id;

  final int q;
  final int r;

  /// [TileType.id] 참조
  final int typeId;

  /// 어드민 메모
  final String? memo;

  /// 마지막 수정 시각
  final DateTime? updatedAt;

  const TileAttribute({
    required this.id,
    required this.q,
    required this.r,
    required this.typeId,
    this.memo,
    this.updatedAt,
  });

  /// 어드민 ID(`"5_3"`)를 모바일 타일 ID 포맷(`"hex_5_3"`)으로 변환합니다.
  ///
  /// 이미 `hex_` 접두사가 붙어있으면 그대로 반환합니다.
  static String normalizeId(String rawId) {
    if (rawId.startsWith('hex_')) return rawId;
    return 'hex_$rawId';
  }

  /// 인스턴스의 정규화된 모바일 타일 ID (`"hex_q_r"`).
  String get normalizedId => normalizeId(id);

  /// Supabase 응답(Map)으로부터 [TileAttribute] 인스턴스를 생성합니다.
  factory TileAttribute.fromJson(Map<String, dynamic> json) {
    return TileAttribute(
      id: json['id'] as String,
      q: (json['q'] as num).toInt(),
      r: (json['r'] as num).toInt(),
      typeId: (json['type_id'] as num?)?.toInt() ?? 0,
      memo: json['memo'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)?.toUtc()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'q': q,
        'r': r,
        'type_id': typeId,
        'memo': memo,
        'updated_at': updatedAt?.toUtc().toIso8601String(),
      };
}
