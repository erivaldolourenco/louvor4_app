import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainerLight,
      onTertiaryContainer: AppColors.onTertiaryContainerLight,
      error: AppColors.danger,
      onError: Colors.white,
      surfaceContainerLowest: AppColors.surfaceContainerLowestLight,
      surfaceContainerLow: AppColors.surfaceContainerLowLight,
      surfaceContainer: AppColors.surfaceContainerLight,
      surfaceContainerHigh: AppColors.surfaceContainerHighLight,
      surfaceContainerHighest: AppColors.surfaceContainerHighestLight,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'FamiljenGrotesk',
      brightness: Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surfaceContainerLowest,

      textTheme: _textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        color: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheet),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.error, width: 2.0),
        ),
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
      ),

      dividerTheme: DividerThemeData(
        color: cs.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surfaceContainerLowest,
        indicatorColor: cs.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary);
          }
          return IconThemeData(color: cs.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              fontFamily: 'FamiljenGrotesk',
            );
          }
          return TextStyle(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontSize: 12,
            fontFamily: 'FamiljenGrotesk',
          );
        }),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        year2023: false,
      ),

      iconTheme: IconThemeData(color: cs.onSurfaceVariant),

      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerLow,
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.badge),
        ),
        labelStyle: TextStyle(
          fontFamily: 'FamiljenGrotesk',
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainerDark,
      onTertiaryContainer: AppColors.onTertiaryContainerDark,
      error: AppColors.danger,
      onError: Colors.white,
      surfaceContainerLowest: AppColors.surfaceContainerLowestDark,
      surfaceContainerLow: AppColors.surfaceContainerLowDark,
      surfaceContainer: AppColors.surfaceContainerDark,
      surfaceContainerHigh: AppColors.surfaceContainerHighDark,
      surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'FamiljenGrotesk',
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surfaceContainerLowest,

      textTheme: _textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        color: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheet),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.error, width: 2.0),
        ),
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
      ),

      dividerTheme: DividerThemeData(
        color: cs.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surfaceContainerLowest,
        indicatorColor: cs.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary);
          }
          return IconThemeData(color: cs.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              fontFamily: 'FamiljenGrotesk',
            );
          }
          return TextStyle(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontSize: 12,
            fontFamily: 'FamiljenGrotesk',
          );
        }),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        year2023: false,
      ),

      iconTheme: IconThemeData(color: cs.onSurfaceVariant),

      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerLow,
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.badge),
        ),
        labelStyle: TextStyle(
          fontFamily: 'FamiljenGrotesk',
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        ),
      ),
    );
  }
}

const _textTheme = TextTheme(
  // Display — para títulos de destaque muito grandes
  displayLarge: TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    fontFamily: 'FamiljenGrotesk',
  ),
  displayMedium: TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    fontFamily: 'FamiljenGrotesk',
  ),
  displaySmall: TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    fontFamily: 'FamiljenGrotesk',
  ),
  // Headline — seções e cabeçalhos
  headlineLarge: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    fontFamily: 'FamiljenGrotesk',
  ),
  headlineMedium: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    fontFamily: 'FamiljenGrotesk',
  ),
  headlineSmall: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    fontFamily: 'FamiljenGrotesk',
  ),
  // Title — títulos de card, sheet, appbar
  titleLarge: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontFamily: 'FamiljenGrotesk',
  ),
  titleMedium: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    fontFamily: 'FamiljenGrotesk',
  ),
  titleSmall: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    fontFamily: 'FamiljenGrotesk',
  ),
  // Body — texto corrido
  bodyLarge: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: 'FamiljenGrotesk',
  ),
  bodyMedium: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: 'FamiljenGrotesk',
  ),
  bodySmall: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: 'FamiljenGrotesk',
  ),
  // Label — chips, badges, legendas
  labelLarge: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: 'FamiljenGrotesk',
  ),
  labelMedium: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: 'FamiljenGrotesk',
  ),
  labelSmall: TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    fontFamily: 'FamiljenGrotesk',
  ),
);
