import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:louvor4_app/core/ui/app_feedback.dart';
import 'package:louvor4_app/core/ui/widgets/song_details_sheet.dart';
import 'package:louvor4_app/core/ui/widgets/user_profile_dialog.dart';
import 'package:louvor4_app/core/ui/widgets/header_project_event.dart';
import 'package:louvor4_app/core/ui/widgets/fade_slide_in.dart';
import 'package:louvor4_app/core/ui/widgets/spring_tap.dart';
import '../../../../core/ui/widgets/song_list_card.dart';
import '../../../medleys/presentation/widgets/medley_card.dart';
import 'package:louvor4_app/features/user_profile/data/impl/user_repository_impl.dart';
import 'package:louvor4_app/features/user_profile/data/user_repository.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/event_program_repository.dart';
import '../../data/events_repository.dart';

import '../../data/impl/event_program_repository_impl.dart';
import '../../data/impl/events_repository_impl.dart';
import '../cubit/event_detail_cubit.dart';
import '../cubit/event_detail_state.dart';
import '../cubit/event_program_cubit.dart';
import '../../domain/entities/event_participant_entity.dart';
import '../widgets/event_participant_card.dart';
import '../widgets/event_program_tab.dart';
import '../widgets/manage_event_participants_sheet.dart';
import '../widgets/manage_event_songs_sheet.dart';
import 'edit_event_page.dart';

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
        RepositoryProvider<EventProgramRepository>(
          create: (_) => EventProgramRepositoryImpl(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) => EventDetailCubit(
              ctx.read<EventsRepository>(),
              ctx.read<UserRepository>(),
            )..load(eventId),
          ),
          BlocProvider(
            create: (ctx) => EventProgramCubit(
              ctx.read<EventProgramRepository>(),
              eventId: eventId,
            ),
          ),
        ],
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

class _EventDetailViewState extends State<_EventDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _programLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.index == 2 && !_programLoaded && mounted) {
      _programLoaded = true;
      context.read<EventProgramCubit>().loadProgram();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: BlocBuilder<EventDetailCubit, EventDetailState>(
        builder: (context, state) {
          if (state.status != EventDetailStatus.success ||
              state.event == null ||
              (!state.isProjectAdmin && !state.canAddSongs))
            return const SizedBox.shrink();
          return _buildFab(state);
        },
      ),
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

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                HeaderProjectEvent(
                  title: event.projectTitle,
                  backgroundImageUrl: event.projectImageUrl,
                  actions: [
                    if (state.isProjectAdmin)
                      PopupMenuButton<_EventHeaderAction>(
                        tooltip: 'Ações do evento',
                        color: cs.surface,
                        icon: const Icon(Icons.more_vert),
                        onSelected: _onHeaderActionSelected,
                        itemBuilder: (context) => [
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
                                color: cs.error,
                              ),
                              title: Text(
                                'Deletar evento',
                                style: TextStyle(color: cs.error),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: FadeSlideIn(
                      child: _EventHeroCard(
                        title: event.title,
                        description: event.description,
                        date: formatDate(event.date),
                        time: formatTime(event.time),
                        location: event.location?.trim().isNotEmpty == true
                            ? event.location!
                            : 'Sem local definido',
                        onLocationTap: event.location?.trim().isNotEmpty == true
                            ? () => _openMaps(event.location!)
                            : null,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _EventDetailTabs(controller: _tabController),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _ParticipantsTab(
                  state: state,
                  onRefresh: () =>
                      context.read<EventDetailCubit>().refreshParticipants(),
                ),
                _SongsTab(
                  state: state,
                  onRemoveSong: _onRemoveSong,
                  onRefresh: () =>
                      context.read<EventDetailCubit>().refreshSongs(),
                ),
                EventProgramTab(isAdmin: state.isProjectAdmin),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    try {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.platformDefault);
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

  Future<bool> _onRemoveSong(String eventSongId) async {
    final cs = Theme.of(context).colorScheme;
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
              style: FilledButton.styleFrom(backgroundColor: cs.error),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return false;

    final removed = await context.read<EventDetailCubit>().removeSong(
      eventSongId,
    );
    if (!mounted) return false;

    if (removed) {
      AppFeedback.showSuccess('Música removida.');
      return true;
    }

    final state = context.read<EventDetailCubit>().state;
    AppFeedback.showError(
      state.actionErrorMessage ?? 'Erro ao remover música.',
    );
    return false;
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

  Widget _buildFab(EventDetailState state) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final index = _tabController.index;

        final action = switch (index) {
          0 when state.isProjectAdmin => (
            icon: Icons.settings_rounded,
            onPressed: () => _onManageSchedule(state),
          ),
          1 when state.isProjectAdmin || state.canAddSongs => (
            icon: Icons.add_rounded,
            onPressed: () => _onAddSongs(state),
          ),
          2 when state.isProjectAdmin => (
            icon: Icons.add_rounded,
            onPressed: _onAddProgramItem,
          ),
          _ => null,
        };

        if (action == null) return const SizedBox.shrink();

        return FloatingActionButton(
          heroTag: 'event_detail_fab',
          onPressed: action.onPressed,
          shape: const CircleBorder(),
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 4,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(action.icon, key: ValueKey(index), size: 28),
          ),
        );
      },
    );
  }

  Future<void> _onAddProgramItem() => showProgramTextItemDialog(context);

  Future<void> _onEditEvent() async {
    final event = context.read<EventDetailCubit>().state.event;
    if (event == null) return;

    final updated = await openEditEventPage(
      context,
      event: event,
      repository: context.read<EventsRepository>(),
    );
    if (updated != true || !mounted) return;

    await context.read<EventDetailCubit>().load(widget.eventId, force: true);
    if (!mounted) return;

    AppFeedback.showSuccess('Evento atualizado com sucesso.');
  }
}

enum _EventHeaderAction { edit, delete }

class _EventDetailTabs extends StatelessWidget {
  final TabController controller;

  const _EventDetailTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const tabs = [
      (assetPath: 'assets/icons/users-round.svg', label: 'Equipe'),
      (assetPath: 'assets/icons/music.svg', label: 'Músicas'),
      (assetPath: 'assets/icons/clipboard-clock.svg', label: 'Roteiro'),
    ];

    return AnimatedBuilder(
      animation: controller.animation ?? controller,
      builder: (context, _) {
        final activeIndex =
            controller.animation?.value.round() ?? controller.index;

        return TabBar(
          controller: controller,
          labelStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            for (var i = 0; i < tabs.length; i++)
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      tabs[i].assetPath,
                      width: 18,
                      height: 18,
                      colorFilter: ColorFilter.mode(
                        i == activeIndex ? cs.primary : cs.onSurfaceVariant,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tabs[i].label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EventHeroCard extends StatelessWidget {
  final String title;
  final String? description;
  final String date;
  final String time;
  final String location;
  final VoidCallback? onLocationTap;

  const _EventHeroCard({
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            height: 1.2,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (description != null && description!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _MetaItem(icon: Icons.calendar_today_rounded, label: date),
            _MetaItem(icon: Icons.access_time_rounded, label: time),
            if (onLocationTap != null)
              SpringTap(
                onTap: onLocationTap,
                pressedScale: 0.95,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.badge),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: cs.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ver localização',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 11,
                        color: cs.onPrimaryContainer,
                      ),
                    ],
                  ),
                ),
              )
            else
              _MetaItem(
                icon: Icons.location_off_rounded,
                label: location,
                muted: true,
              ),
          ],
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool muted;

  const _MetaItem({
    required this.icon,
    required this.label,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: muted ? cs.onSurfaceVariant : cs.primary),
        const SizedBox(width: 5),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: muted ? cs.onSurfaceVariant : cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ParticipantsTab extends StatelessWidget {
  final EventDetailState state;
  final VoidCallback onRefresh;

  const _ParticipantsTab({required this.state, required this.onRefresh});

  Future<bool> _handleParticipantInviteAction(
    BuildContext context, {
    required bool accept,
    required String participantId,
  }) async {
    final cubit = context.read<EventDetailCubit>();
    final success = accept
        ? await cubit.acceptParticipantInvite(participantId)
        : await cubit.declineParticipantInvite(participantId);

    if (success) {
      AppFeedback.showSuccess(
        accept ? 'Participação aceita com sucesso.' : 'Participação recusada.',
      );
      return true;
    }

    AppFeedback.showError(
      cubit.state.actionErrorMessage ??
          (accept
              ? 'Não foi possível aceitar a participação.'
              : 'Não foi possível recusar a participação.'),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EventDetailCubit>();

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: _buildList(context, cubit),
    );
  }

  Widget _buildList(BuildContext context, EventDetailCubit cubit) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 36),
      children: [
        const SizedBox(height: 4),
        if (state.participantsLoadFailed && state.participants.isEmpty)
          _RetryTabState(
            icon: Icons.group_off_rounded,
            title: 'Não foi possível carregar a equipe',
            subtitle: 'Verifique sua conexão e tente novamente.',
            onRetry: onRefresh,
          )
        else if (state.participants.isEmpty)
          const _EmptyTabState(
            icon: Icons.group_off_rounded,
            title: 'Sem participantes',
            subtitle: 'Nenhum integrante foi vinculado a este evento.',
          )
        else
          ...List.generate(state.participants.length, (index) {
            final participant = state.participants[index];
            final canRespondToInvite =
                participant.status == EventParticipantStatus.pending &&
                participant.id.trim().isNotEmpty &&
                cubit.isCurrentUserParticipant(participant);

            return FadeSlideIn(
              delay: staggerDelay(index),
              child: EventParticipantCard(
                name: participant.fullName,
                skill: state.skillsMap[participant.skillId] ?? '',
                status: participant.status,
                profileImage: participant.profileImage,
                onTap: () => showUserProfileDialog(
                  context,
                  name: participant.fullName,
                  profileImageUrl: participant.profileImage,
                  eventSkill: state.skillsMap[participant.skillId] ?? '',
                  eventStatus: participant.status,
                  onAcceptInvite: canRespondToInvite
                      ? () => _handleParticipantInviteAction(
                          context,
                          accept: true,
                          participantId: participant.id,
                        )
                      : null,
                  onDeclineInvite: canRespondToInvite
                      ? () => _handleParticipantInviteAction(
                          context,
                          accept: false,
                          participantId: participant.id,
                        )
                      : null,
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _SongsTab extends StatelessWidget {
  final EventDetailState state;
  final Future<bool> Function(String eventSongId) onRemoveSong;
  final VoidCallback onRefresh;

  const _SongsTab({
    required this.state,
    required this.onRemoveSong,
    required this.onRefresh,
  });

  Future<void> _launchYoutube(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Map<String, List<dynamic>> _groupSongsByAddedBy() {
    final grouped = <String, List<dynamic>>{};

    for (final song in state.songs) {
      final addedBy = _formatAddedBy(song.addedBy);
      grouped.putIfAbsent(addedBy, () => []).add(song);
    }

    return grouped;
  }

  String _formatAddedBy(String value) {
    final words = value.trim().split(RegExp(r'\s+')).where((word) {
      return word.isNotEmpty;
    });

    final normalized = words
        .map((word) {
          return word.length == 1
              ? word.toUpperCase()
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');

    return normalized.isEmpty ? 'Não informado' : normalized;
  }

  @override
  Widget build(BuildContext context) {
    final groupedSongs = _groupSongsByAddedBy();

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 36),
        children: [
          const SizedBox(height: 4),
          if (state.songsLoadFailed && state.songs.isEmpty)
            _RetryTabState(
              icon: Icons.music_off_rounded,
              title: 'Não foi possível carregar o repertório',
              subtitle: 'Verifique sua conexão e tente novamente.',
              onRetry: onRefresh,
            )
          else if (state.songs.isEmpty)
            const _EmptyTabState(
              icon: Icons.music_off_rounded,
              title: 'Sem músicas',
              subtitle: 'Ainda não há repertório cadastrado para este evento.',
            )
          else
            ..._buildGroupedSongSections(
              context,
              groupedSongs,
              state,
              onRemoveSong,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedSongSections(
    BuildContext context,
    Map<String, List<dynamic>> groupedSongs,
    EventDetailState state,
    Future<bool> Function(String eventSongId) onRemoveSong,
  ) {
    var staggerIndex = 0;
    final children = <Widget>[];

    for (final group in groupedSongs.entries) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
          child: Text(
            'Adicionado por: ${group.key}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
      for (final song in group.value) {
        children.add(
          FadeSlideIn(
            delay: staggerDelay(staggerIndex++),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: song.isMedley && song.medleyEntity != null
                  ? MedleyCard(
                      medley: song.medleyEntity!,
                      onDelete:
                          (state.canDeleteSong(song) &&
                              state.deletingSongId != song.id)
                          ? () => onRemoveSong(song.id)
                          : null,
                    )
                  : SongListCard(
                      title: song.title,
                      artist: song.artist ?? 'Desconhecido',
                      musicKey: song.key,
                      bpm: song.bpm?.toString(),
                      youTubeUrl: song.youTubeUrl,
                      hasAudio: song.referenceAudioUrl?.isNotEmpty == true,
                      onTap: () => showSongDetailsModal(
                        context,
                        title: song.title,
                        artist: song.artist ?? 'Desconhecido',
                        musicKey: song.key,
                        bpm: song.bpm?.toString(),
                        youTubeUrl: song.youTubeUrl ?? '',
                        notes: song.notes,
                        referenceAudioUrl: song.referenceAudioUrl,
                      ),
                      onOpenYoutube:
                          (song.youTubeUrl != null &&
                              song.youTubeUrl!.isNotEmpty)
                          ? () => _launchYoutube(song.youTubeUrl!)
                          : null,
                      onDelete:
                          (state.canDeleteSong(song) &&
                              state.deletingSongId != song.id)
                          ? () => onRemoveSong(song.id)
                          : null,
                      isRemoving: state.deletingSongId == song.id,
                    ),
            ),
          ),
        );
      }
      children.add(const SizedBox(height: 6));
    }
    return children;
  }
}

class _DetailLoadingState extends StatelessWidget {
  const _DetailLoadingState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.input),
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
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurfaceVariant,
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

class _RetryTabState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  const _RetryTabState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: cs.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Tentar novamente'),
          ),
        ],
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
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: cs.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
