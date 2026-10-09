import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_radius.dart';
import 'dashboard_format.dart';

/// Seletor de mês/ano: setas para mês anterior/próximo e toque no rótulo
/// para escolher qualquer mês e ano numa grade.
class MonthYearSelector extends StatelessWidget {
  /// Sempre no dia 1 do mês selecionado.
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  const MonthYearSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  void _shift(int months) =>
      onChanged(DateTime(selected.year, selected.month + months));

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (_) => _MonthYearPickerSheet(initial: selected),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: 'Mês anterior',
          onPressed: () => _shift(-1),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Material(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () => _openPicker(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        DashboardFormat.longMonth(
                          DashboardFormat.yearMonth(selected),
                        ),
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Próximo mês',
          onPressed: () => _shift(1),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _MonthYearPickerSheet extends StatefulWidget {
  final DateTime initial;

  const _MonthYearPickerSheet({required this.initial});

  @override
  State<_MonthYearPickerSheet> createState() => _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends State<_MonthYearPickerSheet> {
  late int _year = widget.initial.year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final now = DateTime.now();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Ano anterior',
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    '$_year',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Próximo ano',
                  onPressed: () => setState(() => _year++),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.8,
              children: List.generate(12, (index) {
                final month = index + 1;
                final isSelected =
                    _year == widget.initial.year &&
                    month == widget.initial.month;
                final isCurrent = _year == now.year && month == now.month;
                final label = DateFormat(
                  'MMM',
                  'pt_BR',
                ).format(DateTime(_year, month)).replaceAll('.', '');

                return Material(
                  color: isSelected ? cs.primary : cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    onTap: () =>
                        Navigator.of(context).pop(DateTime(_year, month)),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: isCurrent && !isSelected
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(color: cs.primary),
                            )
                          : null,
                      child: Text(
                        label[0].toUpperCase() + label.substring(1),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isSelected ? cs.onPrimary : cs.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(DateTime(now.year, now.month)),
              child: const Text('Ir para o mês atual'),
            ),
          ],
        ),
      ),
    );
  }
}
