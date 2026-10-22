import 'package:flutter/material.dart';

/// Цвета новгородской старины: охра стен, киноварь фресок, тёмное дерево.
abstract final class AppColors {
  static const cinnabar = Color(0xFF9E2B25);
  static const ochre = Color(0xFFC8963E);
  static const parchment = Color(0xFFF7F0E3);
  static const ink = Color(0xFF2B2420);
  static const visited = Color(0xFF4E7D4A);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.cinnabar,
    primary: AppColors.cinnabar,
    secondary: AppColors.ochre,
    surface: AppColors.parchment,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.parchment,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.parchment,
      foregroundColor: AppColors.ink,
      centerTitle: false,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
      titleLarge: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
      titleMedium: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
      bodyMedium: TextStyle(height: 1.45, color: AppColors.ink),
      bodyLarge: TextStyle(height: 1.45, color: AppColors.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
