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
        secondary: GameConstants.teamBlue,
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
}
