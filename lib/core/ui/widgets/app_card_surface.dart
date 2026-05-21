import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

BoxDecoration appCardDecoration(
  BuildContext context, {
  double radius = AppRadius.cardLarge,
  Color? color,
  Color? borderColor,
  List<BoxShadow>? boxShadow,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: color ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceElevatedLight),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: borderColor ?? (isDark ? AppColors.borderStrongDark : AppColors.borderStrongLight),
    ),
    boxShadow: boxShadow ?? [
      BoxShadow(
        color: isDark ? AppColors.shadowDark : AppColors.shadowLight,
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
