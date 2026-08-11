import 'package:flutter/material.dart';

/// Papéis de cor que complementam o [ColorScheme] padrão do Material 3.
///
/// Use quando um widget precisa de um tom que não existe entre os papéis
/// nativos do [ColorScheme] (primary, secondary, tertiary, surface...), mas
/// que ainda assim deve variar entre os temas claro e escuro. Definido uma
/// vez em [AppTheme.light]/[AppTheme.dark] e lido via
/// `Theme.of(context).extension<AppExtraColors>()!` — sem precisar checar
/// `Theme.of(context).brightness` no widget.
@immutable
class AppExtraColors extends ThemeExtension<AppExtraColors> {
  /// Fundo de badges/círculos que exibem um ícone colorido (ex: ícone de
  /// skill/função ao lado do avatar do participante).
  final Color iconBadgeSurface;

  const AppExtraColors({required this.iconBadgeSurface});

  @override
  AppExtraColors copyWith({Color? iconBadgeSurface}) {
    return AppExtraColors(
      iconBadgeSurface: iconBadgeSurface ?? this.iconBadgeSurface,
    );
  }

  @override
  AppExtraColors lerp(ThemeExtension<AppExtraColors>? other, double t) {
    if (other is! AppExtraColors) return this;
    return AppExtraColors(
      iconBadgeSurface:
          Color.lerp(iconBadgeSurface, other.iconBadgeSurface, t)!,
    );
  }
}
