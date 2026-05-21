import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

class AppFormSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget child;

  const AppFormSheet({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetColor = theme.colorScheme.surface;
    final titleColor = theme.textTheme.titleLarge?.color;
    final subtitleColor = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.78,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: sheetColor,
              borderRadius: BorderRadius.circular(AppRadius.sheet),
              boxShadow: [
                BoxShadow(
                  color: isDark ? AppColors.shadowDark : AppColors.sheetShadowLight,
                  blurRadius: isDark ? 28 : 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 68, 22, 22),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (icon != null)
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.scaffoldDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppRadius.sheet),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? AppColors.iconContainerShadowDark
                            : AppColors.iconContainerShadowLight,
                        blurRadius: isDark ? 22 : 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 38, color: AppColors.primaryBright),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

InputDecoration appFormFieldDecoration(
  BuildContext context, {
  required String hintText,
  IconData? prefixIcon,
  Widget? suffixIcon,
  bool alignLabelWithHint = false,
  EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 18,
  ),
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final fillColor = isDark ? AppColors.scaffoldDark : AppColors.inputFillLight;
  final borderColor = isDark ? AppColors.borderSubtleDark : AppColors.inputBorderLight;
  final hintColor = isDark ? AppColors.textMutedDark : AppColors.hintLight;

  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(color: hintColor),
    alignLabelWithHint: alignLabelWithHint,
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, color: theme.colorScheme.primary),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: fillColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: const BorderSide(color: AppColors.primaryBright, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: const BorderSide(color: AppColors.dangerBright),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: const BorderSide(color: AppColors.dangerBright, width: 1.4),
    ),
    contentPadding: contentPadding,
    counterText: '',
  );
}

ButtonStyle appPrimaryPillButtonStyle(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(56),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
    backgroundColor: AppColors.primaryBright,
    foregroundColor: AppColors.onPrimary,
    elevation: isDark ? 0 : 6,
    shadowColor: isDark ? Colors.transparent : AppColors.primaryButtonShadow,
  );
}

ButtonStyle appSecondaryPillButtonStyle(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(56),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
    side: BorderSide(
      color: isDark ? AppColors.borderSubtleDark : AppColors.secondaryButtonBorderLight,
    ),
    foregroundColor: isDark ? AppColors.secondaryButtonFgDark : AppColors.primary,
    backgroundColor: isDark ? AppColors.scaffoldDark : AppColors.secondaryButtonBgLight,
  );
}

// Compact variant for inline Row use — avoids the infinite-width minimum that
// Size.fromHeight sets, which crashes when the button is not wrapped in Expanded.
ButtonStyle appPrimaryPillButtonStyleCompact(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return FilledButton.styleFrom(
    minimumSize: const Size(0, 44),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
    backgroundColor: AppColors.primaryBright,
    foregroundColor: AppColors.onPrimary,
    elevation: isDark ? 0 : 6,
    shadowColor: isDark ? Colors.transparent : AppColors.primaryButtonShadow,
    padding: const EdgeInsets.symmetric(horizontal: 16),
  );
}
