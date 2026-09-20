import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';

/// Campo de busca padrão do app — mesmo visual em todas as telas
/// (Músicas, busca externa, seleção de música em medley, repertório do evento).
class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final TextInputAction? textInputAction;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.autofocus = false,
    this.textInputAction,
  });

  void _clear() {
    controller.clear();
    onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 40,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return TextField(
            controller: controller,
            autofocus: autofocus,
            textInputAction: textInputAction,
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              hintText: hintText,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: _clear,
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          );
        },
      ),
    );
  }
}
