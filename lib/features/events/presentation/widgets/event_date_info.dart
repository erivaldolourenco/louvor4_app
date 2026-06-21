import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_radius.dart';

class EventDateInfo extends StatelessWidget {
  final DateTime date;

  const EventDateInfo({super.key, required this.date});

  String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = date
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

    if (difference == 0) return 'Hoje';
    if (difference == 1) return 'Amanhã';
    if (difference > 1) return 'daqui a $difference dias';
    if (difference == -1) return 'Ontem';
    return '${difference.abs()} dias atrás';
  }

  String getWeekDay(DateTime date) {
    final day = DateFormat('EEEE', 'pt_BR').format(date);
    return day.substring(0, 1).toUpperCase() + day.substring(1).toLowerCase();
  }

  String getMonthName(int month) {
    const months = [
      'JAN',
      'FEV',
      'MAR',
      'ABR',
      'MAI',
      'JUN',
      'JUL',
      'AGO',
      'SET',
      'OUT',
      'NOV',
      'DEZ',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: cs.primaryContainer),
          ),
          child: Text(
            date.day.toString(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.primaryContainer,
              height: 1,
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            '${getMonthName(date.month)} • ${getWeekDay(date)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.outlineVariant,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            getRelativeTime(date),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
