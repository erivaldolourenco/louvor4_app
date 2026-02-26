import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/impl/events_repository_impl.dart';
import '../cubit/events_cubit.dart';
import '../cubit/events_state.dart';
import 'event_detail_page.dart';

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

  String getMonthAbbreviation(int month) {
    const months = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Meus Eventos', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Acompanhe as escalas e apresentações que você faz parte',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              child: Text(
                '1',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<EventsCubit, EventsState>(
        builder: (context, state) {
          if (state.status == EventsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == EventsStatus.failure) {
            return Center(child: Text(state.errorMessage ?? 'Erro ao carregar eventos'));
          }

          if (state.events.isEmpty) {
            return const Center(child: Text('Nenhum evento encontrado.'));
          }

          return RefreshIndicator(
            onRefresh: () => context.read<EventsCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final e = state.events[i];
                final timeStr = e.time.length >= 5 ? e.time.substring(0, 5) : e.time;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => EventDetailPage(eventId: e.id),
                      ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Text(
                                getMonthAbbreviation(e.date.month),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(e.date.day.toString(), style: theme.textTheme.titleLarge),
                            ],
                          ),
                          const SizedBox(width: 16),
                          (e.projectImageUrl != null && e.projectImageUrl!.isNotEmpty)
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(e.projectImageUrl!),
                                )
                              : const CircleAvatar(
                                  child: Icon(Icons.music_note),
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.title, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(
                                  '$timeStr | ${e.location ?? 'evento da igreja'}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.people_outline, size: 16, color: theme.colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(e.participantsCount.toString()),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.music_note_outlined, size: 16, color: theme.colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(e.repertoireCount.toString()),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
