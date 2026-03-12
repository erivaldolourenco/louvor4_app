import 'package:flutter/material.dart';

BoxDecoration appCardDecoration(
  BuildContext context, {
  double radius = 20,
  Color? color,
  Color? borderColor,
  List<BoxShadow>? boxShadow,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color:
        color ?? (isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC)),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color:
          borderColor ??
          (isDark ? const Color(0xFF243041) : const Color(0xFFDCE3EC)),
    ),
    boxShadow:
        boxShadow ??
        [
          BoxShadow(
            color: isDark ? const Color(0x33000000) : const Color(0x140F172A),
            blurRadius: isDark ? 22 : 18,
            offset: const Offset(0, 5),
          ),
        ],
  );
}

class AppCardSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  const AppCardSurface({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.color,
    this.borderColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    return DecoratedBox(
      decoration: appCardDecoration(
        context,
        radius: radius,
        color: color,
        borderColor: borderColor,
        boxShadow: boxShadow,
      ),
      child: content,
    );
  }
}
