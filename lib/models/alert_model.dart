/// 게임 내 전술 알림 타입
enum AlertType {
  success,
  warn,
  error,
  info;

  static AlertType fromString(String value) {
    return AlertType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AlertType.info,
    );
  }
}

/// 게임 내 전술 알림 모델
class GameAlert {
  final String id;
  final String message;
  final AlertType type;
  final DateTime createdAt;

  GameAlert({
    required this.id,
    required this.message,
    required this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 현재 시각 기준 알림 생성
  factory GameAlert.create({
    required String message,
    required AlertType type,
  }) {
    return GameAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      type: type,
    );
  }
}
