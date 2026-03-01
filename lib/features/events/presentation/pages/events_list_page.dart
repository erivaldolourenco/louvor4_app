import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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

  String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(DateTime(now.year, now.month, now.day)).inDays;

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
    const months = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryBlue = Color(0xFF0166FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Meus Eventos', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Acompanhe as escalas e apresentações',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.only(right: 8),
        //     child: CircleAvatar(
        //       radius: 16,
        //       backgroundColor: primaryBlue.withOpacity(0.1),
        //       child: Text(
        //         state.events.length.toString(),
        //         style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 14),
        //       ),
        //     ),
        //   ),
        // ],
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              itemCount: state.events.length,
              itemBuilder: (context, i) {
                final event = state.events[i];
                final timeStr = event.time.length >= 5 ? event.time.substring(0, 5) : event.time;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Column(
                    children: [
                      // Header da data
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          SizedBox(
                            width: 38,
                            child: Text(
                              event.date.day.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Color(0xFF1D2939)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${getMonthName(event.date.month)} • ${getWeekDay(event.date)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey.shade700),
                          ),
                          const Spacer(),
                          Text(
                            getRelativeTime(event.date),
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Card com a linha da timeline
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Linha da Timeline
                          SizedBox(
                            width: 38,
                            child: Column(
                              children: [
                                Container(width: 1.5, height: 80, color: Colors.grey.shade300),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Card
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => EventDetailPage(eventId: event.id),
                                  ));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: (event.projectImageUrl != null && event.projectImageUrl!.isNotEmpty)
                                            ? Image.network(event.projectImageUrl!, width: 70, height: 70, fit: BoxFit.cover)
                                            : Container(
                                                width: 70,
                                                height: 70,
                                                color: primaryBlue.withOpacity(0.1),
                                                child: const Icon(Icons.music_note, color: primaryBlue, size: 30),
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Info central
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              event.projectTitle,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1D2939)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$timeStr | ${event.location ?? 'Não informado'}',
                                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            // Avatares
                                            if (event.participantsProfileImages.isNotEmpty)
                                              SizedBox(
                                                height: 22,
                                                child: Stack(
                                                  children: List.generate(
                                                    event.participantsProfileImages.length > 5 ? 5 : event.participantsProfileImages.length,
                                                    (index) => Positioned(
                                                      left: index * 14.0,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          border: Border.all(color: Colors.white, width: 1.5),
                                                        ),
                                                        child: CircleAvatar(
                                                          radius: 10,
                                                          backgroundImage: NetworkImage(event.participantsProfileImages[index]),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Linha vertical divisória
                                      // Container(width: 1, height: 50, color: Colors.grey.shade200),
                                      // const SizedBox(width: 12),
                                      // Coluna de música
                                      // Column(
                                      //   mainAxisAlignment: MainAxisAlignment.center,
                                      //   children: [
                                      //     const Icon(Icons.library_music_outlined, color: primaryBlue, size: 22),
                                      //     const SizedBox(height: 4),
                                      //     Text(
                                      //       '${event.repertoireCount}',
                                      //       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1D2939)),
                                      //     ),
                                      //     const Text(
                                      //       'MÚSICAS',
                                      //       style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                                      //     ),
                                      //   ],
                                      // ),
                                      // const SizedBox(width: 4),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
