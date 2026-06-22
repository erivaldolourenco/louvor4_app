import 'package:flutter/material.dart';

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
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
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
              color: cs.surface,
              borderRadius: BorderRadius.circular(AppRadius.sheet),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: isDark ? 0.28 : 0.12),
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
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
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
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sheet),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: isDark ? 0.22 : 0.10),
                        blurRadius: isDark ? 22 : 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 38, color: cs.primary),
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
  final cs = theme.colorScheme;

  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(color: cs.onSurfaceVariant),
    alignLabelWithHint: alignLabelWithHint,
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, color: cs.primary),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: cs.surfaceContainerLow,
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
      borderSide: BorderSide(color: cs.primary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: cs.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: cs.error, width: 1.4),
    ),
    contentPadding: contentPadding,
    counterText: '',
  );
}

ButtonStyle appPrimaryPillButtonStyle(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
    ),
    backgroundColor: cs.primary,
    foregroundColor: cs.onPrimary,
    elevation: isDark ? 0 : 6,
    shadowColor: isDark ? Colors.transparent : cs.primary.withValues(alpha: 0.30),
  );
}

ButtonStyle appSecondaryPillButtonStyle(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
    ),
    side: BorderSide(color: cs.outline),
    foregroundColor: cs.primary,
    backgroundColor: Colors.transparent,
  );
}

ButtonStyle appPrimaryPillButtonStyleCompact(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return FilledButton.styleFrom(
    minimumSize: const Size(0, 44),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
    ),
    backgroundColor: cs.primary,
    foregroundColor: cs.onPrimary,
    elevation: isDark ? 0 : 6,
    shadowColor: isDark ? Colors.transparent : cs.primary.withValues(alpha: 0.30),
    padding: const EdgeInsets.symmetric(horizontal: 16),
  );
}
