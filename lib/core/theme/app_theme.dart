import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';

abstract final class AppTheme {
  static ThemeData light() => ThemeData(
    useMaterial3: true,
    fontFamily: 'Outfit',
    brightness: Brightness.light,

    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.primaryBright,
      onSecondary: AppColors.onPrimary,
      error: AppColors.danger,
      onError: AppColors.onDanger,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      surfaceContainerLow: AppColors.surfaceElevatedLight,
      surfaceContainerHigh: AppColors.surfaceSubtleLight,
      outline: AppColors.borderLight,
      outlineVariant: AppColors.borderStrongLight,
      shadow: AppColors.shadowLight,
    ),

    scaffoldBackgroundColor: AppColors.scaffoldLight,

    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.textPrimaryLight),
      displayMedium: TextStyle(color: AppColors.textPrimaryLight),
      displaySmall: TextStyle(color: AppColors.textPrimaryLight),
      headlineLarge: TextStyle(color: AppColors.textPrimaryLight),
      headlineMedium: TextStyle(color: AppColors.textPrimaryLight),
      headlineSmall: TextStyle(color: AppColors.textPrimaryLight),
      titleLarge: TextStyle(color: AppColors.textPrimaryLight),
      titleMedium: TextStyle(color: AppColors.textPrimaryLight),
      titleSmall: TextStyle(color: AppColors.textMutedLight),
      bodyLarge: TextStyle(color: AppColors.textPrimaryLight),
      bodyMedium: TextStyle(color: AppColors.textPrimaryLight),
      bodySmall: TextStyle(color: AppColors.textMutedLight),
      labelLarge: TextStyle(color: AppColors.textPrimaryLight),
      labelMedium: TextStyle(color: AppColors.textMutedLight),
      labelSmall: TextStyle(color: AppColors.textMutedLight),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.scaffoldLight,
      surfaceTintColor: AppColors.scaffoldLight,
      foregroundColor: AppColors.textPrimaryLight,
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        side: const BorderSide(color: AppColors.borderStrongLight),
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceLight,
      surfaceTintColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimaryLight,
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceElevatedLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.textMutedLight),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 1,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),

    iconTheme: const IconThemeData(color: AppColors.textMutedLight),
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    fontFamily: 'Outfit',
    brightness: Brightness.dark,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.primaryBright,
      onSecondary: AppColors.onPrimary,
      error: AppColors.dangerBright,
      onError: AppColors.onDanger,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerLow: AppColors.surfaceElevatedDark,
      surfaceContainerHigh: AppColors.surfaceSubtleDark,
      outline: AppColors.borderDark,
      outlineVariant: AppColors.borderStrongDark,
      shadow: AppColors.shadowDark,
    ),

    scaffoldBackgroundColor: AppColors.scaffoldDark,

    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.textPrimaryDark),
      displayMedium: TextStyle(color: AppColors.textPrimaryDark),
      displaySmall: TextStyle(color: AppColors.textPrimaryDark),
      headlineLarge: TextStyle(color: AppColors.textPrimaryDark),
      headlineMedium: TextStyle(color: AppColors.textPrimaryDark),
      headlineSmall: TextStyle(color: AppColors.textPrimaryDark),
      titleLarge: TextStyle(color: AppColors.textPrimaryDark),
      titleMedium: TextStyle(color: AppColors.textPrimaryDark),
      titleSmall: TextStyle(color: AppColors.textMutedDark),
      bodyLarge: TextStyle(color: AppColors.textPrimaryDark),
      bodyMedium: TextStyle(color: AppColors.textPrimaryDark),
      bodySmall: TextStyle(color: AppColors.textMutedDark),
      labelLarge: TextStyle(color: AppColors.textPrimaryDark),
      labelMedium: TextStyle(color: AppColors.textMutedDark),
      labelSmall: TextStyle(color: AppColors.textMutedDark),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.textPrimaryDark,
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        side: const BorderSide(color: AppColors.borderStrongDark),
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimaryDark,
        side: const BorderSide(color: AppColors.borderDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceElevatedDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.dangerBright),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.dangerBright, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.textMutedDark),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.borderDark,
      thickness: 1,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),

    iconTheme: const IconThemeData(color: AppColors.textMutedDark),
  );
}
