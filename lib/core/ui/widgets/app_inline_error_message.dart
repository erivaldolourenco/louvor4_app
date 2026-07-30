import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';

/// Mensagem de erro inline para formulários (abaixo de campos ou no rodapé).
class AppInlineErrorMessage extends StatelessWidget {
  final String message;

  const AppInlineErrorMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: cs.error.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: cs.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
