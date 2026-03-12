import 'package:flutter/material.dart';

class AppFormSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const AppFormSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF111827) : Colors.white;
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
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? const Color(0x33000000)
                      : const Color(0x140166FF),
                  blurRadius: isDark ? 28 : 24,
                  offset: Offset(0, 8),
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
          Positioned(
            top: -8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? const Color(0x22000000)
                          : const Color(0x12000000),
                      blurRadius: isDark ? 22 : 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, size: 38, color: const Color(0xFF0166FF)),
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
  final fillColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FF);
  final borderColor = isDark
      ? const Color(0xFF334155)
      : const Color(0xFFE5E7EB);
  final hintColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF);

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
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: Color(0xFF0166FF), width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: Color(0xFFEF4444)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
    ),
    contentPadding: contentPadding,
    counterText: '',
  );
}

ButtonStyle appPrimaryPillButtonStyle(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(56),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    backgroundColor: const Color(0xFF0166FF),
    foregroundColor: Colors.white,
    elevation: isDark ? 0 : 6,
    shadowColor: isDark ? Colors.transparent : const Color(0x330166FF),
  );
}

ButtonStyle appSecondaryPillButtonStyle(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(56),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    side: BorderSide(
      color: isDark ? const Color(0xFF334155) : const Color(0xFFD6E4FF),
    ),
    foregroundColor: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF2563EB),
    backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FBFF),
  );
}
