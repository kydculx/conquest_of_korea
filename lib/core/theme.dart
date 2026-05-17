import 'package:flutter/material.dart';
import 'constants.dart';

class TacticalTheme {
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

  /// HEX 문자열을 Color 객체로 변환
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
