import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:louvor4_app/core/ui/widgets/app_card_surface.dart';
import 'package:louvor4_app/core/ui/widgets/standard_section_app_bar.dart';

import '../../data/impl/events_repository_impl.dart';
import '../../domain/entities/event_entity.dart';
import '../cubit/events_cubit.dart';
import '../cubit/events_state.dart';
import '../widgets/event_list_card.dart';

class EventsListPage extends StatelessWidget {
  const EventsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => EventsRepositoryImpl(),
      child: BlocProvider(
        create: (ctx) => EventsCubit(ctx.read<EventsRepositoryImpl>())..load(),
        child: const _EventsListView(),
      ),
    );
  }
}

class _EventsListView extends StatelessWidget {
  const _EventsListView();

  Map<DateTime, List<EventEntity>> _groupEventsByDate(
    List<EventEntity> events,
  ) {
    final sortedEvents = [...events]..sort((a, b) => a.date.compareTo(b.date));
    final grouped = <DateTime, List<EventEntity>>{};

    for (final event in sortedEvents) {
      final dayKey = DateUtils.dateOnly(event.date);
      grouped.putIfAbsent(dayKey, () => []).add(event);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StandardSectionAppBar(
        title: 'Meus Eventos',
        subtitle: 'Acompanhe suas escalas e apresentações',
      ),
      body: BlocBuilder<EventsCubit, EventsState>(
        builder: (context, state) {
          if (state.status == EventsStatus.loading) {
            return const _EventsLoadingState();
          }
          if (state.status == EventsStatus.failure) {
            return _EventsErrorState(
              message: state.errorMessage ?? 'Erro ao carregar eventos',
              onRetry: () => context.read<EventsCubit>().load(),
            );
          }
          if (state.events.isEmpty) {
            return const _EventsEmptyState();
          }

          final groupedEvents = _groupEventsByDate(state.events);
          final sections = groupedEvents.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          return RefreshIndicator(
            onRefresh: () => context.read<EventsCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                for (final section in sections) ...[
                  EventDateHeader(date: section.key),
                  const SizedBox(height: 10),
                  ...List.generate(section.value.length, (index) {
                    final event = section.value[index];
                    return EventTimelineItemWrapper(
                      child: EventListCard(
                        event: event,
                        isFirstInGroup: index == 0,
                        isLastInGroup: index == section.value.length - 1,
                        showTimelineRail: false,
                        bottomSpacing: 0,
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EventsLoadingState extends StatelessWidget {
  const _EventsLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lineColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE5EDF6);
    final cardFill = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        for (var sectionIndex = 0; sectionIndex < 3; sectionIndex++) ...[
          Padding(
            padding: EdgeInsets.only(bottom: sectionIndex == 2 ? 0 : 18),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 190,
                      height: 20,
                      decoration: BoxDecoration(
                        color: lineColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 92,
                      height: 16,
                      decoration: BoxDecoration(
                        color: lineColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _EventTimelineItemSkeleton(
                  cardFill: cardFill,
                  lineColor: lineColor,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _EventTimelineItemSkeleton extends StatelessWidget {
  final Color cardFill;
  final Color lineColor;

  const _EventTimelineItemSkeleton({
    required this.cardFill,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Expanded(child: Container(width: 2, color: lineColor)),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0166FF),
                  ),
                ),
                Expanded(child: Container(width: 2, color: lineColor)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppCardSurface(
              radius: 16,
              color: cardFill,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: lineColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 16,
                            decoration: BoxDecoration(
                              color: lineColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 170,
                            height: 13,
                            decoration: BoxDecoration(
                              color: lineColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 22,
                            child: Stack(
                              children: List.generate(
                                3,
                                (index) => Positioned(
                                  left: index * 14.0,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFDCE6F1),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF111827)
                                            : Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: lineColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _EventsErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xFF64748B),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventsEmptyState extends StatelessWidget {
  const _EventsEmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_rounded,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 10),
            Text(
              'Nenhum evento encontrado',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Quando houver novas escalas, elas aparecerão aqui.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventDateHeader extends StatelessWidget {
  final DateTime date;

  const EventDateHeader({super.key, required this.date});

  String _getRelativeTime(DateTime targetDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final difference = target.difference(today).inDays;

    if (difference == 0) return 'Hoje';
    if (difference == 1) return 'Amanhã';
    if (difference > 1) return 'daqui a $difference dias';
    if (difference == -1) return 'Ontem';
    return '${difference.abs()} dias atrás';
  }

  String _getMonthName(int month) {
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

  String _getWeekDay(DateTime targetDate) {
    final day = DateFormat('EEEE', 'pt_BR').format(targetDate);
    return day.substring(0, 1).toUpperCase() + day.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            date.day.toString(),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 22,
              height: 1,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            '${_getMonthName(date.month)} • ${_getWeekDay(date)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _getRelativeTime(date),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class EventTimelineItemWrapper extends StatelessWidget {
  final Widget child;

  const EventTimelineItemWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EventTimelineColumn(),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class EventTimelineColumn extends StatelessWidget {
  const EventTimelineColumn({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 28,
      child: Column(
        children: [
          Expanded(
            child: SizedBox(
              width: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFDCE3EC),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
