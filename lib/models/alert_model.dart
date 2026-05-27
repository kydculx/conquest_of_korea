/// 게임 내 전술 알림의 위험/상태 단계를 분류하는 열거형
enum AlertType {
  /// 성공 상태 알림
  success,

  /// 주의 상태 알림
  warn,

  /// 오류/위험 상태 알림
  error,

  /// 일반 전술 정보 알림
  info;

  /// 문자열 값으로부터 [AlertType] 값을 파싱하여 반환합니다. 파싱 불가 시 기본값인 [AlertType.info]를 반환합니다.
  static AlertType fromString(String value) {
    return AlertType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AlertType.info,
    );
  }
}

/// 인게임 화면에 표시되는 전술 팝업/스낵바 알림 데이터 모델 클래스
class GameAlert {
  /// 알림의 고유 식별 ID
  final String id;

  /// 사용자에게 노출할 알림 메시지 텍스트
  final String message;

  /// 알림의 상세 타입 분류
  final AlertType type;

  /// 알림이 발생 및 등록된 시각
  final DateTime createdAt;

  /// GameAlert 생성자
  GameAlert({
    required this.id,
    required this.message,
    required this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 현재 시간을 기반으로 고유 ID를 부여하여 새 [GameAlert] 객체를 생성하는 팩토리 메서드
  factory GameAlert.create({required String message, required AlertType type}) {
    return GameAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      type: type,
    );
  }
}
