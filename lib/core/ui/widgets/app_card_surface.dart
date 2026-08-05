import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';

BoxDecoration appCardDecoration(
  BuildContext context, {
  double radius = AppRadius.cardLarge,
  Color? color,
  Color? borderColor,
  List<BoxShadow>? boxShadow,
}) {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: color ?? cs.surfaceContainerLow,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: borderColor ?? cs.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
    ),
    boxShadow: boxShadow ?? [
      BoxShadow(
        color: isDark ? Colors.black.withValues(alpha: 0.32) : cs.shadow.withValues(alpha: 0.06),
        blurRadius: isDark ? 24 : 16,
        offset: const Offset(0, 6),
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
    this.radius = AppRadius.cardLarge,
    this.color,
    this.borderColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final content = padding == null ? child : Padding(padding: padding!, child: child);

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
