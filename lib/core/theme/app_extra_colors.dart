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

  /// Fundo de botões preenchidos (texto/ícone em `onPrimary`).
  final Color primaryButton;

  /// Badge de status "Aceito"/"Confirmado" (verde esmeralda).
  final Color confirmedContainer;
  final Color onConfirmedContainer;

  /// Badge de status "Pendente" (laranja — distinto do âmbar de tom/BPM).
  final Color pendingContainer;
  final Color onPendingContainer;

  /// Tags de arranjo/categoria (teal).
  final Color arrangementContainer;
  final Color onArrangementContainer;

  const AppExtraColors({
    required this.iconBadgeSurface,
    required this.primaryButton,
    required this.confirmedContainer,
    required this.onConfirmedContainer,
    required this.pendingContainer,
    required this.onPendingContainer,
    required this.arrangementContainer,
    required this.onArrangementContainer,
  });

  @override
  AppExtraColors copyWith({
    Color? iconBadgeSurface,
    Color? primaryButton,
    Color? confirmedContainer,
    Color? onConfirmedContainer,
    Color? pendingContainer,
    Color? onPendingContainer,
    Color? arrangementContainer,
    Color? onArrangementContainer,
  }) {
    return AppExtraColors(
      iconBadgeSurface: iconBadgeSurface ?? this.iconBadgeSurface,
      primaryButton: primaryButton ?? this.primaryButton,
      confirmedContainer: confirmedContainer ?? this.confirmedContainer,
      onConfirmedContainer: onConfirmedContainer ?? this.onConfirmedContainer,
      pendingContainer: pendingContainer ?? this.pendingContainer,
      onPendingContainer: onPendingContainer ?? this.onPendingContainer,
      arrangementContainer: arrangementContainer ?? this.arrangementContainer,
      onArrangementContainer:
          onArrangementContainer ?? this.onArrangementContainer,
    );
  }

  @override
  AppExtraColors lerp(ThemeExtension<AppExtraColors>? other, double t) {
    if (other is! AppExtraColors) return this;
    return AppExtraColors(
      iconBadgeSurface: Color.lerp(
        iconBadgeSurface,
        other.iconBadgeSurface,
        t,
      )!,
      primaryButton: Color.lerp(primaryButton, other.primaryButton, t)!,
      confirmedContainer: Color.lerp(
        confirmedContainer,
        other.confirmedContainer,
        t,
      )!,
      onConfirmedContainer: Color.lerp(
        onConfirmedContainer,
        other.onConfirmedContainer,
        t,
      )!,
      pendingContainer: Color.lerp(
        pendingContainer,
        other.pendingContainer,
        t,
      )!,
      onPendingContainer: Color.lerp(
        onPendingContainer,
        other.onPendingContainer,
        t,
      )!,
      arrangementContainer: Color.lerp(
        arrangementContainer,
        other.arrangementContainer,
        t,
      )!,
      onArrangementContainer: Color.lerp(
        onArrangementContainer,
        other.onArrangementContainer,
        t,
      )!,
    );
  }
}

/// Fundo dos botões preenchidos. Cai no `primary` quando o tema não registra
/// [AppExtraColors] (ex.: widgets montados em teste com `ThemeData()` puro).
Color appPrimaryButtonColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.extension<AppExtraColors>()?.primaryButton ??
      theme.colorScheme.primary;
}
