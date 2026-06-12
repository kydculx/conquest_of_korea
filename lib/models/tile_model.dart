import '../core/constants/game_config.dart';
import '../services/hex_service.dart';

/// 특정 플레이어 관점에서의 H3 헥사곤 타일 점령 소유 상태를 구분하는 열거형
enum TileStatus {
  /// 로그인된 본인 플레이어가 점령한 상태
  mine,

  /// 아무도 점령하지 않아 공백인 상태 (중립 영토)
  empty,

  /// 타 플레이어(적군)가 점령한 상태
  enemy,
}

/// 지도상의 개별 헥사곤 영토 타일의 데이터를 표현하는 모델 클래스
class HexTile {
  /// H3 인덱스 기반의 타일 고유 식별자 ID
  final String id;

  /// 헥사곤 타일 좌표계 축 1 (Q축)
  final int q;

  /// 헥사곤 타일 좌표계 축 2 (R축)
  final int r;

  /// 타일을 점령한 플레이어(사용자)의 UUID 식별자 (중립 시 null)
  final String? userId;

  /// 타일을 지배하는 플레이어의 고유 헥사 네온 컬러 코드 (중립 시 null)
  final String? colorHex;

  /// 타일이 최종 점령(소유권 이전)된 일시 (UTC 기준)
  final DateTime capturedAt;

  /// 이 타일이 전체 게임 생애 주기 동안 총 몇 번 점령되었는지의 빈도수
  final int captureCount;

  /// 헥사곤 타일의 테두리를 그리는 6개의 꼭짓점 위경도 좌표 쌍 목록 (q, r에 근거하여 온디맨드 역산)
  List<List<double>> get bounds => HexService.getHexCorners(
    q,
    r,
  ).map((latLng) => [latLng.latitude, latLng.longitude]).toList();

  /// HexTile 생성자
  const HexTile({
    required this.id,
    required this.q,
    required this.r,
    this.userId,
    this.colorHex,
    required this.capturedAt,
    this.captureCount = 1,
  });

  /// Map 구조의 JSON 데이터로부터 HexTile 인스턴스를 생성하는 팩토리 메서드
  factory HexTile.fromJson(Map<String, dynamic> json) {
    final String id = json['id'] as String;
    int q = json['q'] as int;
    int r = json['r'] as int;

    // ID 기반 좌표 무결성 강제 검증 및 자동 교정 (Self-Healing)
    final parts = id.split('_');
    if (parts.length == 3 && parts[0] == 'hex') {
      final parsedQ = int.tryParse(parts[1]);
      final parsedR = int.tryParse(parts[2]);
      if (parsedQ != null && parsedR != null) {
        if (parsedQ != q || parsedR != r) {
          q = parsedQ;
          r = parsedR;
        }
      }
    }

    return HexTile(
      id: id,
      q: q,
      r: r,
      userId: json['user_id'] as String?,
      colorHex: json['color_hex'] as String?,
      capturedAt: json['captured_at'] != null
          ? DateTime.parse(json['captured_at'] as String).toUtc()
          : DateTime.now().toUtc(),
      captureCount: json['capture_count'] as int? ?? 1,
    );
  }

  /// HexTile 인스턴스를 Map 구조의 JSON 데이터로 변환하여 반환합니다.
  Map<String, dynamic> toJson() => {
    'id': id,
    'q': q,
    'r': r,
    'user_id': userId,
    'color_hex': colorHex,
    'captured_at': capturedAt.toUtc().toIso8601String(),
    'capture_status': 'captured',
    'capture_count': captureCount,
  };

  /// 특정 필드를 변경하여 새로운 HexTile 객체를 복사 생성합니다.
  HexTile copyWith({String? userId, String? colorHex, int? captureCount}) {
    return HexTile(
      id: id,
      q: q,
      r: r,
      userId: userId ?? this.userId,
      colorHex: colorHex ?? this.colorHex,
      capturedAt: capturedAt,
      captureCount: captureCount ?? this.captureCount,
    );
  }

  /// 타일 점령 후 타 침공으로부터 보호(쉴드)를 받는 만료 시각을 게터로 반환합니다.
  DateTime get shieldExpiration => capturedAt.add(
    const Duration(seconds: GameConfig.tileShieldDurationSeconds),
  );

  /// 현재 시간 기준으로 해당 타일의 보호 쉴드 효과가 지속되는지 여부를 판단합니다.
  bool get isShieldActive => DateTime.now().toUtc().isBefore(shieldExpiration);
}
