import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final e = state.events[i];

                final dateStr =
                    '${e.date.day.toString().padLeft(2, '0')}/${e.date.month.toString().padLeft(2, '0')}/${e.date.year}';
                final timeStr = e.time.length >= 5 ? e.time.substring(0, 5) : e.time;

                return Card(
                  elevation: 0,
                  child: ListTile(
                    title: Text(e.title),
                    subtitle: Text('${e.projectTitle}\n$dateStr • $timeStr • ${e.location ?? '-'}'),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${e.participantsCount} 👥'),
                        const SizedBox(height: 4),
                        Text('${e.repertoireCount} 🎵'),
                      ],
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