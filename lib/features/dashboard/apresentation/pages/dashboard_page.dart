import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../../events/data/impl/events_repository_impl.dart';
import '../../../events/presentation/cubit/events_cubit.dart';
import '../../../events/presentation/cubit/events_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => EventsRepositoryImpl(),
      child: BlocProvider(
        create: (ctx) => EventsCubit(ctx.read<EventsRepositoryImpl>())..load(),
        child: const _DashboardView(),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Louvor4')),
      body: BlocBuilder<EventsCubit, EventsState>(
        builder: (context, state) {
          if (state.status == EventsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == EventsStatus.failure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(state.errorMessage ?? 'Erro ao carregar eventos'),
              ),
            );
          }

          if (state.events.isEmpty) {
            return const Center(child: Text('Nenhum evento encontrado.'));
          }

          return RefreshIndicator(
            onRefresh: () => context.read<EventsCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: state.events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final e = state.events[i];

                final dateStr =
                    '${e.date.day.toString().padLeft(2, '0')}/${e.date.month.toString().padLeft(2, '0')}/${e.date.year}';
                final timeStr = e.time.length >= 5
                    ? e.time.substring(0, 5)
                    : e.time;

                return _DashboardEventCard(
                  title: e.title,
                  projectTitle: e.projectTitle,
                  date: dateStr,
                  time: timeStr,
                  location: e.location ?? '-',
                  participantsCount: e.participantsCount,
                  repertoireCount: e.repertoireCount,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DashboardEventCard extends StatelessWidget {
  final String title;
  final String projectTitle;
  final String date;
  final String time;
  final String location;
  final int participantsCount;
  final int repertoireCount;

  const _DashboardEventCard({
    required this.title,
    required this.projectTitle,
    required this.date,
    required this.time,
    required this.location,
    required this.participantsCount,
    required this.repertoireCount,
  });

  @override
  Widget build(BuildContext context) {
    return AppCardSurface(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF0166FF),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  projectTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _InfoChip(icon: Icons.event_outlined, label: date),
                    _InfoChip(icon: Icons.schedule_rounded, label: time),
                    _InfoChip(icon: Icons.place_outlined, label: location),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MetricBadge(
                icon: Icons.groups_2_rounded,
                value: participantsCount.toString(),
                color: const Color(0xFF0166FF),
              ),
              const SizedBox(height: 8),
              _MetricBadge(
                icon: Icons.music_note_rounded,
                value: repertoireCount.toString(),
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MetricBadge({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
