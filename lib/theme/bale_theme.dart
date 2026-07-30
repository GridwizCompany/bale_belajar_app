import 'package:flutter/material.dart';

class BaleColors {
  static const ink = Color(0xFF0E3A5F);
  static const surface = Color(0xFFFFFFFF);
  static const soft = Color(0xFFFFF3E0);
  static const line = Color(0xFFF1D8B4);
  static const success = Color(0xFF4CAF50);
  static const info = Color(0xFF0E3A5F);
  static const warning = Color(0xFFF4B400);
  static const danger = Color(0xFFFF6B6B);
  static const dayaBale = Color(0xFFF4B400);
  static const numeria = Color(0xFF0E3A5F);
  static const kodex = Color(0xFF4CAF50);
  static const detectivia = Color(0xFF8D5E34);
  static const earth = Color(0xFF8D5E34);
}

ThemeData buildBaleTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: BaleColors.warning,
    brightness: Brightness.light,
    surface: BaleColors.surface,
    primary: BaleColors.warning,
    secondary: BaleColors.success,
    tertiary: BaleColors.earth,
    error: BaleColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: BaleColors.soft,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: BaleColors.ink,
        height: 1.12,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: BaleColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: BaleColors.ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF475569),
        height: 1.45,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BaleColors.warning,
        foregroundColor: BaleColors.ink,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: BaleColors.ink,
        side: const BorderSide(color: BaleColors.line, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
  );
}
