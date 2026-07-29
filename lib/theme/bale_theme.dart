import 'package:flutter/material.dart';

class BaleColors {
  static const ink = Color(0xFF172033);
  static const surface = Color(0xFFFFFFFF);
  static const soft = Color(0xFFF8FAFC);
  static const line = Color(0xFFDDE5F0);
  static const success = Color(0xFF22C55E);
  static const info = Color(0xFF2563EB);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFE11D48);
  static const dayaBale = Color(0xFFF9C74F);
  static const numeria = Color(0xFF2563EB);
  static const kodex = Color(0xFF059669);
  static const detectivia = Color(0xFF7C3AED);
}

ThemeData buildBaleTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: BaleColors.success,
    brightness: Brightness.light,
    surface: BaleColors.surface,
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
        backgroundColor: BaleColors.success,
        foregroundColor: Colors.white,
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
