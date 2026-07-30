import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';

/// Aplica [AppRadius.textarea] às bordas de campos multilinha, em vez do
/// raio de pílula ([AppRadius.input]) usado por padrão nos inputs de uma
/// linha — que fica desproporcional em caixas mais altas.
class AppTextAreaTheme extends StatelessWidget {
  final Widget child;

  const AppTextAreaTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decorationTheme = theme.inputDecorationTheme;
    final radius = BorderRadius.circular(AppRadius.textarea);

    InputBorder? withRadius(InputBorder? border) {
      if (border is OutlineInputBorder) {
        return border.copyWith(borderRadius: radius);
      }
      return border;
    }

    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: decorationTheme.copyWith(
          border: withRadius(decorationTheme.border),
          enabledBorder: withRadius(decorationTheme.enabledBorder),
          focusedBorder: withRadius(decorationTheme.focusedBorder),
          errorBorder: withRadius(decorationTheme.errorBorder),
          focusedErrorBorder: withRadius(decorationTheme.focusedErrorBorder),
          disabledBorder: withRadius(decorationTheme.disabledBorder),
        ),
      ),
      child: child,
    );
  }
}
