import 'package:flutter/material.dart';

/// 게임 전반에서 사용되는 공용 전술 컬러 클래스 (외부 제어 및 동적 갱신 가능)
class GameColors {
  /// 내 영토(타일)용 캐주얼 파스텔 파란색 (동적 변경 가능한 변수로 전환)
  static Color myTileColor = const Color.fromARGB(255, 204, 0, 255);
  static String get myTileColorHex =>
      '#${myTileColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  /// 상대 영토(타일)용 캐주얼 파스텔 회색 (동적 변경 가능한 변수로 전환)
  static Color enemyTileColor = const Color.fromARGB(255, 144, 164, 174);
  static String get enemyTileColorHex =>
      '#${enemyTileColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  /// 앱 전반의 아기자기한 다크 테마용 배경 그라데이션
  static const Gradient cozyDarkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF121824), // tacticalBlack
      Color(0xFF1C2434), // 약간 더 깊고 풍부한 다크 딥인디고
    ],
  );

  /// 핵심 솜사탕 블루 액센트 컬러 -> 비비드 솜사탕 네온 시안
  static Color accentNeon = const Color(0xFF00E5FF);

  /// 부가 액센트 컬러 -> 비비드 솜사탕 네온 시안
  static Color colorAccent = const Color(0xFF00E5FF);

  /// 부드러운 스카이 실버 민트 컬러 -> 포근한 다크 차콜 블루그레이
  static Color tacticalGray = const Color(0xFF263238);

  /// 화사한 베이비 스카이 블루 배경 컬러 -> 포근하고 부드러운 미드나잇 블루
  static Color tacticalBlack = const Color(0xFF121824);

  /// 완전 투명 색상
  static Color transparent = const Color(0x00000000);

  /// 전술 화이트 컬러
  static Color tacticalWhite = const Color(0xFFFFFFFF);

  /// 화사하고 부드러운 우유빛 반투명 크림 배경 컬러 -> 92% 불투명 다크 딥 인디고 젤리
  static Color backgroundMedium = const Color(0xF21A2232);

  /// 반투명 우유빛 오버레이 배경 컬러 -> 80% 반투명 다크 딥 인디고 젤리
  static Color backgroundTranslucent = const Color(0xCC1A2232);

  /// 가독성을 대폭 높인 메인 텍스트용 차콜 네이비 컬러 -> 맑고 뽀얀 파스텔 민트 화이트
  static Color textPrimary = const Color(0xFFECEFF1);

  /// 서브 텍스트용 소프트 실버 네이비 컬러 -> 온화한 소프트 실버 그레이
  static Color textSecondary = const Color(0xFFB0BEC5);

  /// 설명용 은은한 파스텔 블루 그레이 컬러 -> 소프트 그레이쉬 블루
  static Color textMuted = const Color(0xFF90A4AE);

  /// 파스텔 톤에 어울리는 연한 차콜 구분선 컬러 -> 화이트 반투명 구분선
  static Color dividerColor = const Color(0x15FFFFFF);

  /// 매우 연한 아기자기 테두리 컬러 -> 미세 화이트 반투명 테두리
  static Color borderLight = const Color(0x0FFFFFFF);

  /// 파스텔 블루 글로우 테두리 컬러 -> 네온 사이버 시안 반투명 테두리
  static Color borderNeon = const Color(0x3300E5FF);

  /// 정밀 미세 격자선 컬러 -> 화이트 초미세 격자선
  static Color techGrid = const Color(0x05FFFFFF);

  /// 상큼하고 부드러운 파스텔 그린 컬러 (성공/안전 상태)
  static Color success = const Color(0xFF81C784);

  /// 달콤한 파스텔 옐로우 오렌지 컬러 (주의/경고 상태)
  static Color warning = const Color(0xFFFFB74D);

  /// 부드러운 파스텔 솜사탕 핑크 레드 컬러 (위험/에러 상태)
  static Color error = const Color(0xFFE57373);

  /// 화사한 파스텔 라이트 블루 컬러 (일반 정보 상태)
  static Color info = const Color(0xFF64B5F6);

  /// 외부(API, DB, 파일 등)에서 넘어온 헥사 코드로 공용 컬러들을 동적 제어하는 메서드
  static void updateCommonColors({
    String? myColor,
    String? enemyColor,
    String? accent,
    String? gray,
    String? black,
    String? txtPrimary,
    String? txtSecondary,
    String? txtMuted,
    String? divColor,
    String? brdLight,
    String? stateSuccess,
    String? stateWarning,
    String? stateError,
    String? stateInfo,
    String? trans,
    String? tacWhite,
    String? bgMedium,
    String? bgTranslucent,
  }) {
    if (myColor != null) {
      final parsed = _parseHexColor(myColor);
      if (parsed != null) {
        myTileColor = parsed;
      }
    }
    if (enemyColor != null) {
      final parsed = _parseHexColor(enemyColor);
      if (parsed != null) {
        enemyTileColor = parsed;
      }
    }
    if (accent != null) {
      final parsed = _parseHexColor(accent);
      if (parsed != null) {
        accentNeon = parsed;
        colorAccent = parsed;
      }
    }
    if (gray != null) {
      final parsed = _parseHexColor(gray);
      if (parsed != null) tacticalGray = parsed;
    }
    if (black != null) {
      final parsed = _parseHexColor(black);
      if (parsed != null) tacticalBlack = parsed;
    }
    if (txtPrimary != null) {
      final parsed = _parseHexColor(txtPrimary);
      if (parsed != null) textPrimary = parsed;
    }
    if (txtSecondary != null) {
      final parsed = _parseHexColor(txtSecondary);
      if (parsed != null) textSecondary = parsed;
    }
    if (txtMuted != null) {
      final parsed = _parseHexColor(txtMuted);
      if (parsed != null) textMuted = parsed;
    }
    if (divColor != null) {
      final parsed = _parseHexColor(divColor);
      if (parsed != null) dividerColor = parsed;
    }
    if (brdLight != null) {
      final parsed = _parseHexColor(brdLight);
      if (parsed != null) borderLight = parsed;
    }
    if (stateSuccess != null) {
      final parsed = _parseHexColor(stateSuccess);
      if (parsed != null) success = parsed;
    }
    if (stateWarning != null) {
      final parsed = _parseHexColor(stateWarning);
      if (parsed != null) warning = parsed;
    }
    if (stateError != null) {
      final parsed = _parseHexColor(stateError);
      if (parsed != null) error = parsed;
    }
    if (stateInfo != null) {
      final parsed = _parseHexColor(stateInfo);
      if (parsed != null) info = parsed;
    }
    if (trans != null) {
      final parsed = _parseHexColor(trans);
      if (parsed != null) transparent = parsed;
    }
    if (tacWhite != null) {
      final parsed = _parseHexColor(tacWhite);
      if (parsed != null) tacticalWhite = parsed;
    }
    if (bgMedium != null) {
      final parsed = _parseHexColor(bgMedium);
      if (parsed != null) backgroundMedium = parsed;
    }
    if (bgTranslucent != null) {
      final parsed = _parseHexColor(bgTranslucent);
      if (parsed != null) backgroundTranslucent = parsed;
    }
  }

  /// 헥사 코드 문자열(#RRGGBB 또는 #AARRGGBB)을 Color 객체로 파싱하는 헬퍼 메서드
  static Color? _parseHexColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return null;
    }
  }
}
