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
      error: AppColors.danger,
      onError: AppColors.onDanger,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Outfit',
      brightness: Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,

      textTheme: _textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          side: BorderSide(color: cs.outlineVariant),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
      ),

      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surfaceContainer,
        indicatorColor: cs.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.onPrimaryContainer);
          }
          return IconThemeData(color: cs.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 12);
          }
          return TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500, fontSize: 12);
        }),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
      ),

      iconTheme: IconThemeData(color: cs.onSurfaceVariant),
    );
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      error: AppColors.dangerBright,
      onError: AppColors.onDanger,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Outfit',
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,

      textTheme: _textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          side: BorderSide(color: cs.outlineVariant),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
      ),

      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surfaceContainer,
        indicatorColor: cs.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.onPrimaryContainer);
          }
          return IconThemeData(color: cs.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 12);
          }
          return TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500, fontSize: 12);
        }),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
      ),

      iconTheme: IconThemeData(color: cs.onSurfaceVariant),
    );
  }
}

const _textTheme = TextTheme(
  // Display — para títulos de destaque muito grandes
  displayLarge:  TextStyle(fontSize: 57, fontWeight: FontWeight.w400, fontFamily: 'Outfit'),
  displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, fontFamily: 'Outfit'),
  displaySmall:  TextStyle(fontSize: 36, fontWeight: FontWeight.w400, fontFamily: 'Outfit'),
  // Headline — seções e cabeçalhos
  headlineLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w400, fontFamily: 'Outfit'),
  headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400, fontFamily: 'Outfit'),
  headlineSmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w400, fontFamily: 'Outfit'),
  // Title — títulos de card, sheet, appbar
  titleLarge:  TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Outfit'),
  titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Outfit'),
  titleSmall:  TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Outfit'),
  // Body — texto corrido
  bodyLarge:  TextStyle(fontSize: 16, fontWeight: FontWeight.w400, fontFamily: 'Outfit'),
  bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, fontFamily: 'Outfit'),
  bodySmall:  TextStyle(fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'Outfit'),
  // Label — chips, badges, legendas
  labelLarge:  TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Outfit'),
  labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Outfit'),
  labelSmall:  TextStyle(fontSize: 11, fontWeight: FontWeight.w500, fontFamily: 'Outfit'),
);
