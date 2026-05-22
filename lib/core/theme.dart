import 'package:flutter/material.dart';
import 'constants/colors.dart';

/// 전술 테마 및 공통 UI 스타일 메타데이터를 관리하는 테마 설정 클래스
class TacticalTheme {
  /// 다크 테마 설정 정의 데이터를 반환하는 게터 메서드
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GameColors.tacticalBlack,
      primaryColor: GameColors.accentNeon,
      colorScheme: ColorScheme.dark(
        primary: GameColors.accentNeon,
        secondary: GameColors.accentNeon,
        surface: GameColors.tacticalGray,
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: GameColors.textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        bodyLarge: TextStyle(color: GameColors.textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: GameColors.tacticalGray,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  /// HEX 코드 문자열을 Color 객체로 안전하게 파싱하여 반환합니다. 실패 시 기본 화이트 색상을 반환합니다.
  static Color parseColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return GameColors.tacticalWhite;
    }
  }
}
