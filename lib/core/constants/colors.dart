import 'package:flutter/material.dart';

/// 게임 전반에서 사용되는 공용 전술 컬러 클래스 (외부 제어 및 동적 갱신 가능)
class GameColors {
  /// 핵심 네온 액센트 컬러
  static Color accentNeon = const Color(0xFF00FFD1);

  /// 부가 액센트 컬러 (accentNeon과 동일값 유지)
  static Color colorAccent = const Color(0xFF00FFD1);

  /// 세련된 다크 그레이-네이비 컬러 (Slate 800 수준)
  static Color tacticalGray = const Color(0xFF1E293B);

  /// 옵시디언 딥 미드나잇 블랙 컬러 (눈 피로 저감 및 입체감 제공)
  static Color tacticalBlack = const Color(0xFF0B0F19);

  /// 완전 투명 색상
  static Color transparent = const Color(0x00000000);

  /// 전술 화이트 컬러
  static Color tacticalWhite = const Color(0xFFFFFFFF);

  /// 은은한 불투명 딥 다크 배경 컬러
  static Color backgroundMedium = const Color(0xF20B0F19);

  /// 반투명 전술 오버레이 배경 컬러
  static Color backgroundTranslucent = const Color(0xCC0B0F19);

  /// 카카오 브랜드 옐로우 컬러
  static Color kakaoYellow = const Color(0xFFFEE500);

  /// 카카오 브랜드 텍스트 컬러
  static Color kakaoText = const Color(0xFF191919);

  /// 가독성을 높인 메인 텍스트용 아이스 화이트 컬러 (Slate 50 수준)
  static Color textPrimary = const Color(0xFFF8FAFC);

  /// 서브 텍스트용 소프트 아이스 실버 컬러 (Slate 300 수준)
  static Color textSecondary = const Color(0xFFCBD5E1);

  /// 비활성/설명용 은은한 뮤티드 그레이 컬러 (Slate 500 수준)
  static Color textMuted = const Color(0xFF64748B);

  /// 은은한 미세 분리선 컬러
  static Color dividerColor = const Color(0x22FFFFFF);

  /// 매우 연한 미세 테두리 컬러
  static Color borderLight = const Color(0x11FFFFFF);

  /// 전술 네온 테두리 컬러
  static Color borderNeon = const Color(0x6600FFD1);

  /// 정밀 미세 격자선 컬러
  static Color techGrid = const Color(0x0CFFFFFF);

  /// 에메랄드 형광 네온 그린 컬러 (성공/안전 상태)
  static Color success = const Color(0xFF10B981);

  /// 하이테크 경고 오렌지 옐로우 컬러 (주의/경고 상태)
  static Color warning = const Color(0xFFF59E0B);

  /// 날카로운 크림슨 레이저 레드 컬러 (위험/에러 상태)
  static Color error = const Color(0xFFEF4444);

  /// 일렉트릭 사이언 테크니컬 블루 컬러 (일반 정보 상태)
  static Color info = const Color(0xFF3B82F6);

  /// 외부(API, DB, 파일 등)에서 넘어온 헥사 코드로 공용 컬러들을 동적 제어하는 메서드
  static void updateCommonColors({
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
    String? kakaoBg,
    String? kakaoTxt,
  }) {
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
    if (kakaoBg != null) {
      final parsed = _parseHexColor(kakaoBg);
      if (parsed != null) kakaoYellow = parsed;
    }
    if (kakaoTxt != null) {
      final parsed = _parseHexColor(kakaoTxt);
      if (parsed != null) kakaoText = parsed;
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
