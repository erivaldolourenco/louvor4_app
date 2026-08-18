import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/widgets/app_buttons.dart';
import '../../domain/entities/song_category_entity.dart';

/// Abre um modal (sobe de baixo pra cima) para selecionar categorias — usado
/// tanto para filtrar listas quanto para atribuir categorias a um item.
/// Retorna o novo conjunto de ids selecionados, ou `null` se o usuário
/// cancelar sem confirmar.
Future<Set<String>?> showCategoryFilterSheet(
  BuildContext context, {
  required List<SongCategoryEntity> categories,
  required Set<String> initiallySelectedIds,
  String title = 'Filtrar por categoria',
  String subtitle = 'Selecione uma ou mais categorias para filtrar.',
  String applyLabel = 'Aplicar',
  String clearLabel = 'Limpar filtros',
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.bottomSheet),
      ),
    ),
    builder: (_) => CategoryFilterSheet(
      categories: categories,
      initiallySelectedIds: initiallySelectedIds,
      title: title,
      subtitle: subtitle,
      applyLabel: applyLabel,
      clearLabel: clearLabel,
    ),
  );
}

class CategoryFilterSheet extends StatefulWidget {
  final List<SongCategoryEntity> categories;
  final Set<String> initiallySelectedIds;
  final String title;
  final String subtitle;
  final String applyLabel;
  final String clearLabel;

  const CategoryFilterSheet({
    super.key,
    required this.categories,
    required this.initiallySelectedIds,
    this.title = 'Filtrar por categoria',
    this.subtitle = 'Selecione uma ou mais categorias para filtrar.',
    this.applyLabel = 'Aplicar',
    this.clearLabel = 'Limpar filtros',
  });

  @override
  State<CategoryFilterSheet> createState() => _CategoryFilterSheetState();
}

class _CategoryFilterSheetState extends State<CategoryFilterSheet> {
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.initiallySelectedIds};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.categories.map((category) {
                final selected = _selectedIds.contains(category.id);
                return FilterChip(
                  label: Text(category.name),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedIds.add(category.id);
                      } else {
                        _selectedIds.remove(category.id);
                      }
                    });
                  },
                  selectedColor: cs.primaryContainer,
                  checkmarkColor: cs.onPrimaryContainer,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? cs.onPrimaryContainer : null,
                  ),
                  backgroundColor: cs.surface,
                  side: BorderSide(
                    color: selected ? cs.primary : cs.outlineVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () => setState(() => _selectedIds.clear()),
                    child: Text(widget.clearLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPrimaryButton(
                    onPressed: () => Navigator.of(context).pop(_selectedIds),
                    child: Text(widget.applyLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
