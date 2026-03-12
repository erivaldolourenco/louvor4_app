import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:louvor4_app/core/ui/widgets/header_project_event.dart';
import 'package:louvor4_app/features/events/presentation/widgets/event_music_card.dart';
import 'package:louvor4_app/features/user_profile/data/impl/user_repository_impl.dart';
import 'package:louvor4_app/features/user_profile/data/user_repository.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/formatters.dart';
import '../../data/events_repository.dart';
import '../../data/impl/events_repository_impl.dart';
import '../cubit/event_detail_cubit.dart';
import '../cubit/event_detail_state.dart';
import 'edit_event_page.dart';
import '../widgets/event_participant_card.dart';
import '../widgets/manage_event_participants_sheet.dart';
import '../widgets/manage_event_songs_sheet.dart';

class EventDetailPage extends StatelessWidget {
  final String eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<EventsRepository>(
          create: (_) => EventsRepositoryImpl(),
        ),
        RepositoryProvider<UserRepository>(create: (_) => UserRepositoryImpl()),
      ],
      child: BlocProvider(
        create: (ctx) => EventDetailCubit(
          ctx.read<EventsRepository>(),
          ctx.read<UserRepository>(),
        )..load(eventId),
        child: _EventDetailView(eventId: eventId),
      ),
    );
  }
}

class _EventDetailView extends StatefulWidget {
  final String eventId;

  const _EventDetailView({required this.eventId});

  @override
  State<_EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<_EventDetailView> {
  bool _showParticipants = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = theme.textTheme.headlineSmall?.color;
    final bodyColor = theme.textTheme.bodyMedium?.color;
    final mutedColor = bodyColor?.withValues(alpha: isDark ? 0.82 : 0.72);

    return Scaffold(
      body: BlocBuilder<EventDetailCubit, EventDetailState>(
        builder: (context, state) {
          if (state.status == EventDetailStatus.loading) {
            return const _DetailLoadingState();
          }

          if (state.status == EventDetailStatus.failure) {
            return _DetailErrorState(
              message:
                  state.errorMessage ??
                  'Não foi possível carregar os detalhes do evento.',
              onRetry: () =>
                  context.read<EventDetailCubit>().load(widget.eventId),
            );
          }

          final event = state.event;
          if (event == null) {
            return _DetailErrorState(
              message: 'Evento não encontrado.',
              onRetry: () =>
                  context.read<EventDetailCubit>().load(widget.eventId),
            );
          }

          return CustomScrollView(
            slivers: [
              HeaderProjectEvent(
                title: event.projectTitle,
                backgroundImageUrl: event.projectImageUrl,
                actions: [
                  if (state.isProjectAdmin)
                    PopupMenuButton<_EventHeaderAction>(
                      tooltip: 'Ações do evento',
                      color: isDark ? const Color(0xFF111827) : Colors.white,
                      icon: const Icon(Icons.more_vert),
                      onSelected: _onHeaderActionSelected,
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _EventHeaderAction.edit,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Editar evento'),
                          ),
                        ),
                        PopupMenuItem(
                          value: _EventHeaderAction.delete,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.delete_outline,
                              color: Color(0xFFB3261E),
                            ),
                            title: Text(
                              'Deletar evento',
                              style: TextStyle(color: Color(0xFFB3261E)),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Column(
                    children: [
                      Text(
                        event.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      if (event.description != null &&
                          event.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          event.description!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: mutedColor,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF111827) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF243041)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        _InlineInfoItem(
                          icon: Icons.calendar_month_outlined,
                          text: formatDate(event.date),
                        ),
                        SizedBox(
                          height: 24,
                          child: VerticalDivider(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                            width: 14,
                          ),
                        ),
                        _InlineInfoItem(
                          icon: Icons.access_time_filled_rounded,
                          text: formatTime(event.time),
                        ),
                        SizedBox(
                          height: 24,
                          child: VerticalDivider(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                            width: 14,
                          ),
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
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
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
                        const SizedBox(width: 6),
                        _buildTabItem(
                          label: 'Músicas',
                          count: state.songs.length,
                          selected: !_showParticipants,
                          onTap: () =>
                              setState(() => _showParticipants = false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showParticipants)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'EQUIPE ESCALADA',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: mutedColor,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                          ),
                        ),
                        if (state.isProjectAdmin)
                          FilledButton(
                            onPressed: () => _onManageSchedule(state),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 6,
                              shadowColor: const Color(0x6610B981),
                            ),
                            child: const Text(
                              'Gerenciar Escala',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              if (!_showParticipants)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'REPERTÓRIO DO EVENTO',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: mutedColor,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                          ),
                        ),
                        FilledButton(
                          onPressed: () => _onAddSongs(state),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 6,
                            shadowColor: const Color(0x662563EB),
                          ),
                          child: const Text(
                            'Nova Música',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
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
                    subtitle:
                        'Ainda não há repertório cadastrado para este evento.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: _showParticipants
                      ? SliverList(
                          delegate: SliverChildBuilderDelegate((context, i) {
                            final participant = state.participants[i];
                            return EventParticipantCard(
                              name: participant.fullName,
                              skill: state.skillsMap[participant.skillId] ?? '',
                              profileImage: participant.profileImage,
                            );
                          }, childCount: state.participants.length),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate((context, i) {
                            final song = state.songs[i];
                            return EventMusicCard(
                              eventSongId: song.id,
                              title: song.title,
                              artist: song.artist ?? 'Desconhecido',
                              musicKey: song.key ?? '',
                              addedBy: song.addedBy,
                              youtubeUrl: song.youTubeUrl,
                              canRemove: state.isProjectAdmin,
                              isRemoving: state.deletingSongId == song.id,
                              onRemove: state.deletingSongId == song.id
                                  ? null
                                  : () => _onRemoveSong(song.id),
                            );
                          }, childCount: state.songs.length),
                        ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 36)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? const Color(0xFF111827) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.18 : 0.05,
                      ),
                      blurRadius: isDark ? 14 : 10,
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
                  color: selected ? activeColor : inactiveColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF172554)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF1D4ED8),
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
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _onManageSchedule(EventDetailState state) async {
    final event = state.event;
    if (event == null) return;

    final changed = await showManageEventParticipantsSheet(
      context,
      event: event,
    );
    if (changed != true || !mounted) return;

    await context.read<EventDetailCubit>().refreshParticipants();
  }

  Future<void> _onAddSongs(EventDetailState state) async {
    final event = state.event;
    if (event == null) return;

    final changed = await showManageEventSongsSheet(context, eventId: event.id);
    if (changed != true || !mounted) return;

    await context.read<EventDetailCubit>().refreshSongs();
  }

  Future<void> _onRemoveSong(String eventSongId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remover música'),
          content: const Text(
            'Tem certeza que deseja remover esta música do evento?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB3261E),
              ),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final removed = await context.read<EventDetailCubit>().removeSong(
      eventSongId,
    );
    if (!mounted) return;

    final state = context.read<EventDetailCubit>().state;
    if (removed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Música removida.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.actionErrorMessage ?? 'Erro ao remover música'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFB3261E),
      ),
    );
  }

  Future<void> _onHeaderActionSelected(_EventHeaderAction action) async {
    switch (action) {
      case _EventHeaderAction.edit:
        await _onEditEvent();
        break;
      case _EventHeaderAction.delete:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deletar evento ainda não foi implementado.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
    }
  }

  Future<void> _onEditEvent() async {
    final event = context.read<EventDetailCubit>().state.event;
    if (event == null) return;

    final updated = await openEditEventPage(
      context,
      event: event,
      repository: context.read<EventsRepository>(),
    );
    if (updated != true || !mounted) return;

    await context.read<EventDetailCubit>().load(widget.eventId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Evento atualizado com sucesso.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }
}

enum _EventHeaderAction { edit, delete }

class _InlineInfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _InlineInfoItem({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final titleColor = Theme.of(context).textTheme.bodyMedium?.color;

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
                  style: TextStyle(
                    color: titleColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
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

  const _DetailErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.78,
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: mutedColor),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedColor, fontWeight: FontWeight.w500),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = theme.textTheme.titleMedium?.color;
    final subtitleColor = theme.textTheme.bodySmall?.color?.withValues(
      alpha: 0.78,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF243041) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: subtitleColor),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
