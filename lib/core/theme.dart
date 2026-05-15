import 'package:flutter/material.dart';
import 'constants.dart';

class TacticalTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GameConstants.tacticalBlack,
      primaryColor: GameConstants.accentNeon,
      colorScheme: const ColorScheme.dark(
        primary: GameConstants.accentNeon,
        secondary: GameConstants.accentNeon,
        surface: GameConstants.tacticalGray,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        bodyLarge: TextStyle(color: Colors.white70),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: GameConstants.tacticalGray,
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
      return Colors.white;
    }
  }
}
