/// 플레이어가 지나간(진입한) 개별 H3 헥사곤 타일의 발자취 데이터를 표현하는 모델 클래스
class FootprintTile {
  /// H3 인덱스 기반의 타일 고유 식별자 ID
  final String tileId;

  /// 플레이어가 해당 타일에 최초로 진입한 일시 (초/밀리초 절사)
  final DateTime recordedAt;

  /// FootprintTile 생성자
  FootprintTile({
    required this.tileId,
    required this.recordedAt,
  });

  /// Map 구조의 JSON 데이터로부터 FootprintTile 인스턴스를 생성하는 팩토리 메서드
  factory FootprintTile.fromJson(Map<String, dynamic> json) {
    return FootprintTile(
      tileId: json['tile_id'] as String,
      recordedAt: DateTime.parse(json['recorded_at'] as String).toLocal(),
    );
  }

  /// FootprintTile 인스턴스를 Map 구조의 JSON 데이터로 변환하여 반환합니다.
  Map<String, dynamic> toJson() => {
    'tile_id': tileId,
    'recorded_at': recordedAt.toUtc().toIso8601String(),
  };

  /// 년/월/일/시/분 형식으로 로컬 시간대 포맷팅하여 반환합니다. (예: "2026/06/27 12:34")
  String get formattedTime {
    final y = recordedAt.year;
    final m = recordedAt.month.toString().padLeft(2, '0');
    final d = recordedAt.day.toString().padLeft(2, '0');
    final h = recordedAt.hour.toString().padLeft(2, '0');
    final min = recordedAt.minute.toString().padLeft(2, '0');
    return '$y/$m/$d $h:$min';
  }
}
