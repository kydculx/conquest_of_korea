/// 사용자가 앱에서 보낸 문의 한 건과 그 답변 상태를 담는 데이터 모델 클래스
class UserInquiry {
  /// 문의 고유 식별자
  final String id;

  /// 문의 유형 (bug, feature, account, etc)
  final String category;

  /// 문의 제목
  final String title;

  /// 문의 내용
  final String content;

  /// 처리 상태 (open, answered, closed)
  final String status;

  /// 관리자 답변 내용
  final String? answer;

  /// 문의 접수 일시
  final DateTime createdAt;

  /// 답변 등록 일시
  final DateTime? answeredAt;

  const UserInquiry({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.status,
    this.answer,
    required this.createdAt,
    this.answeredAt,
  });

  /// 답변 내용이 등록되어 있는지 여부
  bool get hasAnswer => (answer?.trim().isNotEmpty ?? false);

  /// JSON 응답을 모델로 변환합니다.
  factory UserInquiry.fromJson(Map<String, dynamic> json) {
    return UserInquiry(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? 'etc',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      answer: json['answer']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      answeredAt: DateTime.tryParse(
        json['answered_at']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}

/// 문의 접수 요청의 성공 여부와 서버 오류 코드를 담는 결과 값 객체
class InquirySubmitResult {
  /// 접수 성공 여부
  final bool success;

  /// 실패 시 서버가 반환한 오류 코드
  final String? errorCode;

  /// 접수 성공 시 생성된 문의 식별자
  final String? id;

  const InquirySubmitResult({required this.success, this.errorCode, this.id});

  /// 접수 성공 결과를 생성합니다.
  const InquirySubmitResult.success(this.id) : success = true, errorCode = null;

  /// 접수 실패 결과를 생성합니다.
  const InquirySubmitResult.failure(this.errorCode)
    : success = false,
      id = null;
}
