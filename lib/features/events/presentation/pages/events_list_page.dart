import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:louvor4_app/core/ui/widgets/app_card_surface.dart';
import 'package:louvor4_app/features/root/presentation/widgets/root_home_header.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/user_detail_entity.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../domain/entities/event_entity.dart';
import '../cubit/events_cubit.dart';
import '../cubit/events_state.dart';
import '../widgets/event_list_card.dart';

Map<DateTime, List<EventEntity>> _groupEventsByDate(
  List<EventEntity> events,
) {
  final grouped = <DateTime, List<EventEntity>>{};
  for (final event in events) {
    final dayKey = DateUtils.dateOnly(event.date);
    grouped.putIfAbsent(dayKey, () => []).add(event);
  }
  return grouped;
}

class EventsListPage extends StatelessWidget {
  final VoidCallback onOpenDrawer;
  final UserDetailEntity? user;
  final bool isLoadingUser;

  const EventsListPage({
    super.key,
    required this.onOpenDrawer,
    required this.user,
    required this.isLoadingUser,
  });

  @override
  Widget build(BuildContext context) {
    return _EventsListView(
      onOpenDrawer: onOpenDrawer,
      user: user,
      isLoadingUser: isLoadingUser,
    );
  }
}

class _EventsListView extends StatefulWidget {
  final VoidCallback onOpenDrawer;
  final UserDetailEntity? user;
  final bool isLoadingUser;

  const _EventsListView({
    required this.onOpenDrawer,
    required this.user,
    required this.isLoadingUser,
  });

  @override
  State<_EventsListView> createState() => _EventsListViewState();
}

class _EventsListViewState extends State<_EventsListView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _pastScrollController = ScrollController();
  bool _pastLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _pastScrollController.addListener(_handlePastScroll);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _pastScrollController.removeListener(_handlePastScroll);
    _pastScrollController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1 && !_pastLoaded) {
      _pastLoaded = true;
      context.read<EventsCubit>().loadPastEvents();
    }
  }

  void _handlePastScroll() {
    final pos = _pastScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      context.read<EventsCubit>().loadMorePastEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootHomeHeader(
        onAvatarTap: widget.onOpenDrawer,
        user: widget.user,
        isLoadingUser: widget.isLoadingUser,
      ),
      body: Column(
        children: [
          _HomeTabBar(controller: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _UpcomingTab(),
                _PastTab(scrollController: _pastScrollController),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTabBar extends StatelessWidget {
  final TabController controller;

  const _HomeTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TabBar.secondary(
      controller: controller,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      tabs: const [
        Tab(text: 'Próximos'),
        Tab(text: 'Passados'),
      ],
    );
  }
}

class _UpcomingTab extends StatelessWidget {
  const _UpcomingTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventsCubit, EventsState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.events != curr.events,
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
    );
  }
}

class _PastTab extends StatelessWidget {
  final ScrollController scrollController;

  const _PastTab({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventsCubit, EventsState>(
      buildWhen: (prev, curr) =>
          prev.pastEventsStatus != curr.pastEventsStatus ||
          prev.pastEvents != curr.pastEvents ||
          prev.pastEventsHasMore != curr.pastEventsHasMore,
      builder: (context, state) {
        if (state.pastEventsStatus == PastEventsStatus.initial ||
            state.pastEventsStatus == PastEventsStatus.loading) {
          return const _EventsLoadingState();
        }
        if (state.pastEventsStatus == PastEventsStatus.failure &&
            state.pastEvents.isEmpty) {
          return _EventsErrorState(
            message: 'Erro ao carregar eventos passados',
            onRetry: () => context.read<EventsCubit>().loadPastEvents(),
          );
        }
        if (state.pastEvents.isEmpty) {
          return const _PastEventsEmptyState();
        }

        final grouped = _groupEventsByDate(state.pastEvents);
        final sections = grouped.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key));

        return RefreshIndicator(
          onRefresh: () => context.read<EventsCubit>().loadPastEvents(),
          child: ListView(
            controller: scrollController,
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
              if (state.pastEventsStatus == PastEventsStatus.loadingMore)
                const _LoadMoreIndicator(),
              if (!state.pastEventsHasMore && state.pastEvents.isNotEmpty)
                const _NoMoreEventsIndicator(),
            ],
          ),
        );
      },
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _NoMoreEventsIndicator extends StatelessWidget {
  const _NoMoreEventsIndicator();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          'Não há mais eventos',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _EventsLoadingState extends StatelessWidget {
  const _EventsLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
  final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final lineColor = isDark
        ? cs.surfaceContainer
        : const Color(0xFFE5EDF6);
    final cardFill = isDark ? cs.surface : cs.surfaceContainer;

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
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 92,
                      height: 16,
                      decoration: BoxDecoration(
                        color: lineColor,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
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
    final cs = Theme.of(context).colorScheme;
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary,
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
                        borderRadius: BorderRadius.circular(AppRadius.input),
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
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 170,
                            height: 13,
                            decoration: BoxDecoration(
                              color: lineColor,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
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
                                      color: cs.surfaceContainerLow,
                                      border: Border.all(
                                        color: cs.surface,
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
                        borderRadius: BorderRadius.circular(AppRadius.pill),
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? cs.onSurfaceVariant
                    : cs.onSurfaceVariant,
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 48,
              color: cs.onSurfaceVariant,
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
                    ? cs.onSurfaceVariant
                    : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PastEventsEmptyState extends StatelessWidget {
  const _PastEventsEmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 48,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              'Nenhum evento passado',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Seus eventos anteriores aparecerão aqui.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? cs.onSurfaceVariant
                    : cs.onSurfaceVariant,
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
  final cs = theme.colorScheme;
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
              color: isDark ? cs.outlineVariant : cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            '${_getMonthName(date.month)} • ${_getWeekDay(date)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? cs.outlineVariant : cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _getRelativeTime(date),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? cs.onSurfaceVariant : cs.onSurfaceVariant,
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
    final cs = Theme.of(context).colorScheme;
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
                      ? cs.onSurfaceVariant
                      : cs.outline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
