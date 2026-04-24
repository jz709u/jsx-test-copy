import 'package:flutter/material.dart';

// ── Colors ────────────────────────────────────────────────────────────────────

class AppColors {
  // Backgrounds
  static const background     = Color(0xFF0D0E14);
  static const surface        = Color(0xFF1A1B25);
  static const surfaceElevated= Color(0xFF242535);

  // Brand
  static const gold           = Color(0xFFE8B84B);
  static const goldLight      = Color(0xFFF5CC6E);

  // Text
  static const white          = Color(0xFFFFFFFF);
  static const textSecondary  = Color(0xFF8A8D9F);
  static const textMuted      = Color(0xFF4A4D5E);

  // Structural
  static const divider        = Color(0xFF2A2B38);

  // Semantic
  static const success        = Color(0xFF4CAF82);
  static const warning        = Color(0xFFFF9F43);
  static const error          = Color(0xFFFF6B6B);
}

// ── Spacing ───────────────────────────────────────────────────────────────────

class AppSpacing {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 24;
  static const double x3l = 32;
  static const double x4l = 40;

  // Semantic aliases
  static const double cardPadding    = lg;     // 16
  static const double screenPadding  = xl;     // 20
  static const double sectionGap     = x3l;    // 32
  static const double itemGap        = md;     // 12
}

// ── Border Radii ─────────────────────────────────────────────────────────────

class AppRadius {
  static const double xs  = 6;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double full= 999;

  // Semantic aliases
  static const double card   = lg;   // 16
  static const double sheet  = xl;   // 20
  static const double badge  = xs;   // 6
  static const double chip   = sm;   // 8
  static const double button = md;   // 12
  static const double input  = md;   // 12
}

// ── Text Styles ───────────────────────────────────────────────────────────────

class AppTextStyles {
  // Display
  static const displayLarge  = TextStyle(color: AppColors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.0);
  static const displayMedium = TextStyle(color: AppColors.white, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5);

  // Headlines
  static const headlineLarge  = TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3);
  static const headlineMedium = TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w600);
  static const headlineSmall  = TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w600);

  // Titles
  static const titleLarge  = TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600);
  static const titleMedium = TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600);
  static const titleSmall  = TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600);

  // Body
  static const bodyLarge  = TextStyle(color: AppColors.white,         fontSize: 16);
  static const bodyMedium = TextStyle(color: AppColors.textSecondary,  fontSize: 14);
  static const bodySmall  = TextStyle(color: AppColors.textMuted,      fontSize: 12);

  // Labels
  static const labelLarge  = TextStyle(color: AppColors.white,        fontSize: 14, fontWeight: FontWeight.w600);
  static const labelMedium = TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500);
  static const labelSmall  = TextStyle(color: AppColors.textMuted,     fontSize: 11, fontWeight: FontWeight.w500);

  // Caption (smallest supporting text)
  static const caption = TextStyle(color: AppColors.textMuted, fontSize: 10);

  // Mono (confirmation codes, IDs)
  static const mono = TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace');
}

// ── Theme ─────────────────────────────────────────────────────────────────────

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
          titleTextStyle: AppTextStyles.headlineLarge,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: BorderSide.none,
          ),
          hintStyle: AppTextStyles.bodySmall,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.background,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            textStyle: AppTextStyles.labelLarge,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),
        textTheme: const TextTheme(
          displayLarge:   AppTextStyles.displayLarge,
          displayMedium:  AppTextStyles.displayMedium,
          headlineLarge:  AppTextStyles.headlineLarge,
          headlineMedium: AppTextStyles.headlineMedium,
          headlineSmall:  AppTextStyles.headlineSmall,
          titleLarge:     AppTextStyles.titleLarge,
          titleMedium:    AppTextStyles.titleMedium,
          titleSmall:     AppTextStyles.titleSmall,
          bodyLarge:      AppTextStyles.bodyLarge,
          bodyMedium:     AppTextStyles.bodyMedium,
          bodySmall:      AppTextStyles.bodySmall,
          labelLarge:     AppTextStyles.labelLarge,
          labelMedium:    AppTextStyles.labelMedium,
          labelSmall:     AppTextStyles.labelSmall,
        ),
      );
}
