import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:louvor4_app/features/events/presentation/widgets/event_music_card.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/formatters.dart';
import '../../data/impl/events_repository_impl.dart';
import '../cubit/event_detail_cubit.dart';
import '../cubit/event_detail_state.dart';
import '../widgets/event_participant_card.dart';

class EventDetailPage extends StatelessWidget {
  final String eventId;

  const EventDetailPage({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => EventsRepositoryImpl(),
      child: BlocProvider(
        create: (ctx) => EventDetailCubit(ctx.read<EventsRepositoryImpl>())..load(eventId),
        child: _EventDetailView(eventId: eventId),
      ),
    );
  }
}

class _EventDetailView extends StatefulWidget {
  final String eventId;

  const _EventDetailView({
    required this.eventId,
  });

  @override
  State<_EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<_EventDetailView> {
  bool _showParticipants = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocBuilder<EventDetailCubit, EventDetailState>(
        builder: (context, state) {
          if (state.status == EventDetailStatus.loading) {
            return const _DetailLoadingState();
          }

          if (state.status == EventDetailStatus.failure) {
            return _DetailErrorState(
              message: state.errorMessage ?? 'Não foi possível carregar os detalhes do evento.',
              onRetry: () => context.read<EventDetailCubit>().load(widget.eventId),
            );
          }

          final event = state.event;
          if (event == null) {
            return _DetailErrorState(
              message: 'Evento não encontrado.',
              onRetry: () => context.read<EventDetailCubit>().load(widget.eventId),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 110,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                title: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    event.projectTitle,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (event.projectImageUrl != null && event.projectImageUrl!.isNotEmpty)
                        Image.network(
                          event.projectImageUrl!,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(color: const Color(0xFF1E293B)),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.25),
                              Colors.black.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Column(
                    children: [
                      Text(
                        event.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (event.description != null && event.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          event.description!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        _InlineInfoItem(
                          icon: Icons.calendar_month_outlined,
                          text: formatDate(event.date),
                        ),
                        const SizedBox(
                          height: 24,
                          child: VerticalDivider(color: Color(0xFFE2E8F0), width: 14),
                        ),
                        _InlineInfoItem(
                          icon: Icons.access_time_filled_rounded,
                          text: formatTime(event.time),
                        ),
                        const SizedBox(
                          height: 24,
                          child: VerticalDivider(color: Color(0xFFE2E8F0), width: 14),
                        ),
                        _InlineInfoItem(
                          icon: Icons.location_on_outlined,
                          text: event.location?.trim().isNotEmpty == true
                              ? event.location!
                              : 'Não consta endereço',
                          onTap: event.location?.trim().isNotEmpty == true
                              ? () => _openMaps(event.location!)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _buildTabItem(
                          label: 'Equipe',
                          count: state.participants.length,
                          selected: _showParticipants,
                          onTap: () => setState(() => _showParticipants = true),
                        ),
                        _buildTabItem(
                          label: 'Músicas',
                          count: state.songs.length,
                          selected: !_showParticipants,
                          onTap: () => setState(() => _showParticipants = false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showParticipants && state.participants.isEmpty)
                const SliverToBoxAdapter(
                  child: _EmptyTabState(
                    icon: Icons.group_off_rounded,
                    title: 'Sem participantes',
                    subtitle: 'Nenhum integrante foi vinculado a este evento.',
                  ),
                )
              else if (!_showParticipants && state.songs.isEmpty)
                const SliverToBoxAdapter(
                  child: _EmptyTabState(
                    icon: Icons.music_off_rounded,
                    title: 'Sem músicas',
                    subtitle: 'Ainda não há repertório cadastrado para este evento.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: _showParticipants
                      ? SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final participant = state.participants[i];
                              return EventParticipantCard(
                                name: participant.fullName,
                                skill: state.skillsMap[participant.skillId] ?? '',
                                profileImage: participant.profileImage,
                              );
                            },
                            childCount: state.participants.length,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final song = state.songs[i];
                              return EventMusicCard(
                                title: song.title,
                                artist: song.artist ?? 'Desconhecido',
                                musicKey: song.key ?? '',
                                youtubeUrl: song.youTubeUrl,
                              );
                            },
                            childCount: state.songs.length,
                          ),
                        ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 36),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabItem({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? const Color(0xFF0F4CDA) : const Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }
}

class _InlineInfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _InlineInfoItem({
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF1D4ED8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLoadingState extends StatelessWidget {
  const _DetailLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ],
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFF64748B)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
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

class _EmptyTabState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyTabState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
