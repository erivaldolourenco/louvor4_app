import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:louvor4_app/features/events/presentation/widgets/event_music_card.dart';
import '../../data/impl/events_repository_impl.dart';
import '../cubit/event_detail_cubit.dart';
import '../cubit/event_detail_state.dart';
import '../widgets/event_participant_card.dart';

class EventDetailPage extends StatelessWidget {
  final String eventId;
  const EventDetailPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => EventsRepositoryImpl(),
      child: BlocProvider(
        create: (ctx) => EventDetailCubit(ctx.read<EventsRepositoryImpl>())..load(eventId),
        child: const _EventDetailView(),
      ),
    );
  }
}

class _EventDetailView extends StatefulWidget {
  const _EventDetailView();
  @override
  State<_EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<_EventDetailView> {
  bool _showParticipants = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fundo leve da imagem
      body: BlocBuilder<EventDetailCubit, EventDetailState>(
        builder: (context, state) {
          if (state.status == EventDetailStatus.loading) return const Center(child: CircularProgressIndicator());
          if (state.event == null) return const Center(child: Text('Erro ao carregar'));

          final event = state.event!;

          return CustomScrollView(
            slivers: [
              // HEADER REDUZIDO (Como na imagem)
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Imagem de capa menor com degradê
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        image: event.projectImageUrl != null
                            ? DecorationImage(image: NetworkImage(event.projectImageUrl!), fit: BoxFit.cover)
                            : null,
                        color: Colors.black87,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    // Título e Botões na mesma linha
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              event.projectTitle.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const Spacer(),
                            _buildActionButton(Icons.edit, null, Colors.white24),
                            const SizedBox(width: 8),
                            _buildActionButton(Icons.delete, null, Colors.redAccent),
                          ],
                        ),
                      ),
                    ),
                    // CARD BRANCO SOBREPOSTO (O efeito de subir a tela)
                    Positioned(
                      top: 140,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                        ),
                        child: Column(
                          children: [
                            Text(event.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF444444))),
                            if (event.description != null)
                              Text('"${event.description}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ESPAÇADOR PARA COMPENSAR O POSITIONED
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
              // INFO ROW (Data, Hora, Local)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(Icons.calendar_month_outlined, event.date.toString().substring(0, 10)),
                      _buildInfoItem(Icons.access_time_filled, event.time.substring(0, 5)),
                      _buildInfoItem(Icons.location_on, event.location ?? "Nao cosnta endereco"),
                    ],
                  ),
                ),
              ),

              // O SELETOR DE ABAS IGUAL À IMAGEM
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9ECEF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        _buildTabItem("Equipe", state.participants.length, _showParticipants, () => setState(() => _showParticipants = true)),
                        _buildTabItem("Músicas", state.songs.length, !_showParticipants, () => setState(() => _showParticipants = false)),
                      ],
                    ),
                  ),
                ),
              ),

              // LISTA DE MÚSICAS ESTILIZADA
              // LISTA CONDICIONAL (EQUIPE OU MÚSICAS)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: _showParticipants
                    ? SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: state.participants.length,
                        (_, i) {
                      final p = state.participants[i];
                      return EventParticipantCard(
                        name: p.fullName,
                        role: p.skillId,
                        profileImage: p.profileImage);
                    },
                  ),
                )
                    : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: state.songs.length,
                        (_, i) {
                      final s = state.songs[i];
                      return EventMusicCard(
                          title: s.title,
                          artist: s.artist ?? "Desconhecido",
                          musicKey: s.key ??"");
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          );
        },
      ),
    );
  }

  // BOTÕES DO TOPO (Editar/Deletar)
  Widget _buildActionButton(IconData icon, String? label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white30)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          if (label != null) ...[const SizedBox(width: 4), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))],
        ],
      ),
    );
  }

  // ITENS DE DATA/HORA
  Widget _buildInfoItem(IconData icon, String text) {
    return Column(
      children: [
        CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: Icon(icon, color: Colors.blue, size: 20)),
        const SizedBox(height: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  // O SELETOR ESTILO "PÍLULA"
  Widget _buildTabItem(String label, int count, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))] : [],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(color: isSelected ? Colors.blue : Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(count.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

}