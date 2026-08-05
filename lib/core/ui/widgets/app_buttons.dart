import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import 'spring_tap.dart';

/// Botão de pílula preenchido, usado como ação principal dos formulários.
///
/// Usa [SpringTap] para a resposta elástica ao toque e preenche com uma
/// versão suavizada (não 100% opaca) da cor primária, em vez do preenchimento
/// sólido padrão do [FilledButton].
class AppPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final double height;

  const AppPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null;

    final bgColor = enabled
        ? cs.primary
        : cs.onSurface.withValues(alpha: 0.12);
    final fgColor = enabled
        ? cs.onPrimary
        : cs.onSurface.withValues(alpha: 0.38);

    return SpringTap(
      onTap: onPressed,
      pressedScale: 0.97,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.input),
          boxShadow: enabled && !isDark
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: fgColor, size: 20),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: fgColor, fontWeight: FontWeight.w700),
            child: _ButtonContent(icon: icon, child: child),
          ),
        ),
      ),
    );
  }
}

/// Botão de pílula contornado, usado como ação secundária dos formulários.
class AppSecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final Widget? leading;
  final double height;

  const AppSecondaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.leading,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onPressed != null;

    final fgColor = enabled ? cs.primary : cs.onSurface.withValues(alpha: 0.38);
    final borderColor = enabled
        ? cs.outline
        : cs.onSurface.withValues(alpha: 0.12);

    return SpringTap(
      onTap: onPressed,
      pressedScale: 0.97,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: borderColor),
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: fgColor, size: 20),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: fgColor, fontWeight: FontWeight.w700),
            child: _ButtonContent(icon: icon, leading: leading, child: child),
          ),
        ),
      ),
    );
  }
}

/// Botão de pílula contornado para ações destrutivas (ex: excluir, sair).
class AppDestructiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final double height;

  const AppDestructiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onPressed != null;

    final fgColor = enabled ? cs.error : cs.onSurface.withValues(alpha: 0.38);
    final borderColor = enabled
        ? cs.error.withValues(alpha: 0.5)
        : cs.onSurface.withValues(alpha: 0.12);

    return SpringTap(
      onTap: onPressed,
      pressedScale: 0.97,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: borderColor),
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: fgColor, size: 20),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: fgColor, fontWeight: FontWeight.w700),
            child: _ButtonContent(icon: icon, child: child),
          ),
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final Widget child;

  const _ButtonContent({required this.icon, this.leading, required this.child});

  @override
  Widget build(BuildContext context) {
    final leadingWidget = leading ?? (icon != null ? Icon(icon) : null);
    if (leadingWidget == null) return child;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [leadingWidget, const SizedBox(width: 8), Flexible(child: child)],
    );
  }
}
