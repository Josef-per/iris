import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF28174E);
  static const deepPurple = Color(0xFF462A7E);
  static const purple = Color(0xFF7D6AC6);
  static const lavender = Color(0xFFDBCFFF);
  static const porcelain = Color(0xFFFAF9F6);
  static const white = Color(0xFFFFFFFF);
  static const text = Color(0xFF241B35);
  static const muted = Color(0xFF756D82);
  static const outline = Color(0xFFE5DFEB);
  static const success = Color(0xFF3D7A55);
  static const danger = Color(0xFFB94352);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, deepPurple, ink],
  );
}

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.purple,
      brightness: Brightness.light,
      primary: AppColors.deepPurple,
      secondary: AppColors.purple,
      surface: AppColors.white,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.porcelain,
      fontFamily: 'Nunito',
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: AppColors.ink,
          fontSize: 38,
          height: 1.12,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: TextStyle(
          color: AppColors.ink,
          fontSize: 28,
          height: 1.2,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppColors.text,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: AppColors.text, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(
          color: AppColors.muted,
          fontSize: 14,
          height: 1.45,
        ),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: AppColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.purple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: AppColors.deepPurple,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          foregroundColor: AppColors.deepPurple,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          side: const BorderSide(color: AppColors.purple),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
