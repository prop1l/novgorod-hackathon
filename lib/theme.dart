import 'package:flutter/material.dart';

/// Цвета из Figma («Новгород · цвета» в макете «Здесь было…»).
abstract final class AppColors {
  static const bgLight = Color(0xFFF6F6F6);
  static const bgDark = Color(0xFF031229);
  static const surfaceDark = Color(0xFF19283F);
  static const card = Color(0xFFFFFFFF);
  static const accent = Color(0xFF1B6EF1);
  static const accentSoft = Color(0xFFE3EDFD);
  static const text = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const onDark = Color(0xFFF6F6F6);
  static const border = Color(0xFFE2E8F0);
  static const visited = Color(0xFF22A06B);
}

/// Текстовые стили из Figma: Manrope, те же размеры и межстрочные интервалы.
abstract final class AppText {
  static const h1 = TextStyle(fontSize: 40, fontWeight: FontWeight.w400, height: 1.2, color: AppColors.text);
  static const screenTitle = TextStyle(fontSize: 30, fontWeight: FontWeight.w400, height: 1.2, color: AppColors.text);
  static const h2 = TextStyle(fontSize: 26, fontWeight: FontWeight.w600, height: 1.2, color: AppColors.text);
  static const h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3, color: AppColors.text);
  static const body = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.45, color: AppColors.text);
  static const small = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4, color: AppColors.textSecondary);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.3, color: AppColors.textSecondary);
  static const button = TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 1.2);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    primary: AppColors.accent,
    onPrimary: Colors.white,
    secondary: AppColors.accent,
    surface: AppColors.bgLight,
    onSurface: AppColors.text,
  );
  return ThemeData(
    colorScheme: scheme,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: AppColors.bgLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgLight,
      foregroundColor: AppColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      headlineLarge: AppText.h1,
      headlineMedium: AppText.screenTitle,
      headlineSmall: AppText.h2,
      titleLarge: AppText.h2,
      titleMedium: AppText.h3,
      bodyLarge: AppText.body,
      bodyMedium: AppText.body,
      bodySmall: AppText.small,
      labelSmall: AppText.caption,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 62),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        textStyle: AppText.button.copyWith(fontFamily: 'Manrope'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        textStyle: AppText.body.copyWith(fontFamily: 'Manrope', fontWeight: FontWeight.w500),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.accent : AppColors.border,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.accent,
      inactiveTrackColor: AppColors.accentSoft,
      thumbColor: AppColors.accent,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, space: 1, thickness: 1),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.bgDark,
      contentTextStyle: TextStyle(fontFamily: 'Manrope', color: AppColors.onDark),
      behavior: SnackBarBehavior.floating,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: AppColors.border,
    ),
  );
}
