import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../../features/song_categories/domain/entities/song_category_entity.dart';

/// Horizontal scrollable row of category filter chips.
///
/// Unselected chips use the same text color/weight as an inactive tab
/// (`cs.onSurfaceVariant` + `FontWeight.w500`), so this reads consistently
/// wherever a category filter sits next to a tab bar (lista de músicas,
/// adicionar música ao repertório, etc.).
class CategoryFilterChips extends StatelessWidget {
  final List<SongCategoryEntity> categories;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final EdgeInsetsGeometry padding;

  const CategoryFilterChips({
    super.key,
    required this.categories,
    required this.selectedIds,
    required this.onToggle,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final category = categories[index];
          final selected = selectedIds.contains(category.id);
          return FilterChip(
            label: Text(category.name),
            selected: selected,
            onSelected: (_) => onToggle(category.id),
            selectedColor: cs.primaryContainer,
            checkmarkColor: cs.onPrimaryContainer,
            labelStyle: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
            backgroundColor: cs.surfaceContainerLow,
            side: BorderSide(
              color: selected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.25),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          );
        },
      ),
    );
  }
}
