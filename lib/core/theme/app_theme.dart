import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0D0E14);
  static const surface = Color(0xFF1A1B25);
  static const surfaceElevated = Color(0xFF242535);
  static const gold = Color(0xFFE8B84B);
  static const goldLight = Color(0xFFF5CC6E);
  static const white = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8A8D9F);
  static const textMuted = Color(0xFF4A4D5E);
  static const divider = Color(0xFF2A2B38);
  static const success = Color(0xFF4CAF82);
  static const warning = Color(0xFFFF9F43);
  static const error = Color(0xFFFF6B6B);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          secondary: AppColors.goldLight,
          surface: AppColors.surface,
          onPrimary: AppColors.background,
          onSecondary: AppColors.background,
          onSurface: AppColors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.gold,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 11),
        ),
        cardTheme: CardTheme(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: AppColors.textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.background,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          headlineMedium: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: AppColors.white, fontSize: 16),
          bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          bodySmall: TextStyle(color: AppColors.textMuted, fontSize: 12),
          labelLarge: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );
}
