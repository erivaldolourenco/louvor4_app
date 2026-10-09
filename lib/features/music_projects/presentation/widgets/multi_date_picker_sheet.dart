import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/app_buttons.dart';

/// Abre um calendário onde o usuário marca/desmarca várias datas e confirma
/// todas de uma vez. Retorna as datas selecionadas (ordenadas) ou `null` se
/// o usuário fechar sem confirmar.
Future<List<DateTime>?> showMultiDatePickerSheet(
  BuildContext context, {
  required List<DateTime> initialDates,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showModalBottomSheet<List<DateTime>>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _MultiDatePickerSheet(
      initialDates: initialDates,
      firstDate: _dateOnly(firstDate),
      lastDate: _dateOnly(lastDate),
    ),
  );
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

const _monthNames = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

// Semana começando no domingo, como no calendário brasileiro.
const _weekdayLabels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

class _MultiDatePickerSheet extends StatefulWidget {
  final List<DateTime> initialDates;
  final DateTime firstDate;
  final DateTime lastDate;

  const _MultiDatePickerSheet({
    required this.initialDates,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_MultiDatePickerSheet> createState() => _MultiDatePickerSheetState();
}

class _MultiDatePickerSheetState extends State<_MultiDatePickerSheet> {
  late final Set<DateTime> _selected = widget.initialDates
      .map(_dateOnly)
      .toSet();
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    final sorted = _selected.toList()..sort();
    final anchor = sorted.isNotEmpty ? sorted.first : today;
    _visibleMonth = DateTime(anchor.year, anchor.month);
  }

  bool get _canGoBack => _visibleMonth.isAfter(
    DateTime(widget.firstDate.year, widget.firstDate.month),
  );

  bool get _canGoForward => _visibleMonth.isBefore(
    DateTime(widget.lastDate.year, widget.lastDate.month),
  );

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _toggle(DateTime day) {
    setState(() {
      if (!_selected.remove(day)) _selected.add(day);
    });
  }

  bool _isSelectable(DateTime day) =>
      !day.isBefore(widget.firstDate) && !day.isAfter(widget.lastDate);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final count = _selected.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Selecionar datas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque nos dias para marcar ou desmarcar.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                tooltip: 'Mês anterior',
                onPressed: _canGoBack ? () => _changeMonth(-1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Próximo mês',
                onPressed: _canGoForward ? () => _changeMonth(1) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final label in _weekdayLabels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          _buildMonthGrid(context),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: count == 0
                    ? null
                    : () => setState(() => _selected.clear()),
                child: const Text('Limpar'),
              ),
              const Spacer(),
              Text(
                count == 1 ? '1 data' : '$count datas',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppPrimaryButton(
            onPressed: () {
              final result = _selected.toList()..sort();
              Navigator.of(context).pop(result);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = _dateOnly(DateTime.now());
    final daysInMonth = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    // DateTime.weekday: segunda = 1 ... domingo = 7 → domingo vira coluna 0.
    final leadingBlanks = _visibleMonth.weekday % 7;
    final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemBuilder: (context, index) {
        final dayNumber = index - leadingBlanks + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }
        final day = DateTime(
          _visibleMonth.year,
          _visibleMonth.month,
          dayNumber,
        );
        final selectable = _isSelectable(day);
        final selected = _selected.contains(day);
        final isToday = day == today;

        return Padding(
          padding: const EdgeInsets.all(3),
          child: Material(
            color: selected ? cs.primary : Colors.transparent,
            shape: CircleBorder(
              side: isToday && !selected
                  ? BorderSide(color: cs.primary)
                  : BorderSide.none,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: selectable ? () => _toggle(day) : null,
              child: Center(
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    fontWeight: selected || isToday
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: !selectable
                        ? cs.onSurface.withValues(alpha: 0.3)
                        : selected
                        ? cs.onPrimary
                        : isToday
                        ? cs.primary
                        : cs.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
