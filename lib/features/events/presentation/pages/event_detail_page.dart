import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:louvor4_app/core/ui/app_feedback.dart';
import 'package:louvor4_app/core/ui/widgets/song_details_sheet.dart';
import 'package:louvor4_app/core/ui/widgets/user_profile_dialog.dart';
import 'package:louvor4_app/core/ui/widgets/header_project_event.dart';
import 'package:louvor4_app/features/events/presentation/widgets/event_music_card.dart';
import 'package:louvor4_app/features/user_profile/data/impl/user_repository_impl.dart';
import 'package:louvor4_app/features/user_profile/data/user_repository.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
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
                        color: isDark ? AppColors.surfaceDark : Colors.white,
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
                                color: AppColors.danger,
                              ),
                              title: Text(
                                'Deletar evento',
                                style: TextStyle(color: AppColors.danger),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 34, 16, 0),
                    child: Transform.translate(
                      offset: const Offset(0, -34),
                      child: _EventHeroCard(
                        title: event.title,
                        description: event.description,
                        titleColor: titleColor,
                        mutedColor: mutedColor,
                        items: [
                          _EventInfoItemData(
                            assetPath: 'assets/icons/calendar.svg',
                            text: formatDate(event.date),
                            backgroundColor: isDark
                                ? AppColors.primarySubtleDark
                                : const Color(0xFFEAF2FF),
                            iconColor: AppColors.primary,
                          ),
                          _EventInfoItemData(
                            assetPath: 'assets/icons/alarm-clock.svg',
                            text: formatTime(event.time),
                            backgroundColor: isDark
                                ? AppColors.warningSubtleDark
                                : AppColors.warningSubtleLight,
                            iconColor: AppColors.warning,
                          ),
                          _EventInfoItemData(
                            assetPath: 'assets/icons/map-pinned.svg',
                            text: event.location?.trim().isNotEmpty == true
                                ? event.location!
                                : 'Sem local definido',
                            backgroundColor: isDark
                                ? AppColors.successSubtleDark
                                : AppColors.successSubtleLight,
                            iconColor: AppColors.successBright,
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
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: _EventDetailTabs(controller: _tabController),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _ParticipantsTab(
                  state: state,
                  mutedColor: mutedColor,
                  onManageSchedule: () => _onManageSchedule(state),
                  onRefresh: () => context
                      .read<EventDetailCubit>()
                      .load(widget.eventId, force: true),
                ),
                _SongsTab(
                  state: state,
                  mutedColor: mutedColor,
                  onAddSongs: () => _onAddSongs(state),
                  onRemoveSong: _onRemoveSong,
                  onRefresh: () => context
                      .read<EventDetailCubit>()
                      .load(widget.eventId, force: true),
                ),
                EventProgramTab(
                  isAdmin: state.isProjectAdmin,
                  mutedColor: mutedColor,
                ),
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

  Future<bool> _onRemoveSong(String eventSongId) async {
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
                backgroundColor: AppColors.danger,
              ),
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

    final state = context.read<EventDetailCubit>().state;
    if (removed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Música removida.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.actionErrorMessage ?? 'Erro ao remover música'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.danger,
      ),
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Evento atualizado com sucesso.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );
  }
}

enum _EventHeaderAction { edit, delete }

class _EventDetailTabs extends StatelessWidget {
  final TabController controller;

  const _EventDetailTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: controller.animation ?? controller,
      builder: (context, child) {
        final tabIndex =
            controller.animation?.value.round() ?? controller.index;

        return Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceElevatedDark : AppColors.borderLight,
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          child: TabBar(
            controller: controller,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.input),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                  blurRadius: isDark ? 14 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            tabs: [
              _EventDetailTabLabel(label: 'Equipe', selected: tabIndex == 0),
              _EventDetailTabLabel(label: 'Músicas', selected: tabIndex == 1),
              _EventDetailTabLabel(
                label: 'Programação',
                selected: tabIndex == 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EventHeroCard extends StatelessWidget {
  final String title;
  final String? description;
  final Color? titleColor;
  final Color? mutedColor;
  final List<_EventInfoItemData> items;

  const _EventHeroCard({
    required this.title,
    required this.description,
    required this.titleColor,
    required this.mutedColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark : AppColors.shadowLight,
            blurRadius: isDark ? 24 : 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: titleColor,
                height: 1.05,
              ),
            ),
            if (description != null && description!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 16,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            _EventInfoHighlightsRow(items: items),
          ],
        ),
      ),
    );
  }
}

class _EventDetailTabLabel extends StatelessWidget {
  final String label;
  final bool selected;

  const _EventDetailTabLabel({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Tab(
      height: 40,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: selected
              ? theme.colorScheme.primary
              : (isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight),
        ),
      ),
    );
  }
}

class _ParticipantsTab extends StatelessWidget {
  final EventDetailState state;
  final Color? mutedColor;
  final VoidCallback onManageSchedule;
  final VoidCallback onRefresh;

  const _ParticipantsTab({
    required this.state,
    required this.mutedColor,
    required this.onManageSchedule,
    required this.onRefresh,
  });

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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 36),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'EQUIPE ESCALADA',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: mutedColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            if (state.isProjectAdmin)
              FilledButton(
                onPressed: onManageSchedule,
                style: appPrimaryPillButtonStyleCompact(context),
                child: const Text(
                  'Gerenciar Escala',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
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
          ...state.participants.map((participant) {
            final canRespondToInvite =
                participant.status == EventParticipantStatus.pending &&
                participant.id.trim().isNotEmpty &&
                cubit.isCurrentUserParticipant(participant);

            return EventParticipantCard(
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
            );
          }),
      ],
    );
  }
}

class _SongsTab extends StatelessWidget {
  final EventDetailState state;
  final Color? mutedColor;
  final VoidCallback onAddSongs;
  final Future<bool> Function(String eventSongId) onRemoveSong;
  final VoidCallback onRefresh;

  const _SongsTab({
    required this.state,
    required this.mutedColor,
    required this.onAddSongs,
    required this.onRemoveSong,
    required this.onRefresh,
  });

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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 36),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'REPERTÓRIO DO EVENTO',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: mutedColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            FilledButton(
              onPressed: onAddSongs,
              style: appPrimaryPillButtonStyleCompact(context),
              child: const Text(
                'Nova Música',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
          ...groupedSongs.entries.expand(
            (group) => [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                child: Text(
                  'Adicionado por: ${group.key}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ...group.value.map(
                (song) => EventMusicCard(
                  eventSongId: song.id,
                  title: song.title,
                  artist: song.isMedley
                      ? (song.artist ?? 'Medley')
                      : (song.artist ?? 'Desconhecido'),
                  musicKey: song.key ?? '',
                  bpm: song.bpm,
                  youtubeUrl: song.youTubeUrl,
                  isMedley: song.isMedley,
                  onTap: () => showSongDetailsModal(
                    context,
                    title: song.title,
                    artist: song.isMedley
                        ? (song.artist ?? '')
                        : (song.artist ?? 'Desconhecido'),
                    musicKey: song.key,
                    bpm: song.bpm?.toString(),
                    youTubeUrl: song.youTubeUrl ?? '',
                    notes: song.notes,
                  ),
                  canRemove: state.isProjectAdmin,
                  isRemoving: state.deletingSongId == song.id,
                  onRemove: state.deletingSongId == song.id
                      ? null
                      : () => onRemoveSong(song.id),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
      ],
    );
  }
}

class _EventInfoHighlightItem extends StatelessWidget {
  final String assetPath;
  final String text;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const _EventInfoHighlightItem({
    required this.assetPath,
    required this.text,
    required this.backgroundColor,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = Theme.of(context).textTheme.titleMedium?.color;
    final isLocationAction = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  assetPath,
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                height: 1.2,
                decoration: isLocationAction
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationStyle: TextDecorationStyle.dotted,
                decorationColor: titleColor?.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventInfoHighlightsRow extends StatelessWidget {
  final List<_EventInfoItemData> items;

  const _EventInfoHighlightsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Expanded(
              child: _EventInfoHighlightItem(
                assetPath: item.assetPath,
                text: item.text,
                backgroundColor: item.backgroundColor,
                iconColor: item.iconColor,
                onTap: item.onTap,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _EventInfoItemData {
  final String assetPath;
  final String text;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const _EventInfoItemData({
    required this.assetPath,
    required this.text,
    required this.backgroundColor,
    required this.iconColor,
    this.onTap,
  });
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
            color: isDark ? AppColors.surfaceElevatedDark : AppColors.borderLight,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceElevatedDark : AppColors.borderLight,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceElevatedDark : AppColors.borderLight,
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
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = theme.textTheme.titleMedium?.color;
    final subtitleColor = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.78);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark ? AppColors.borderStrongDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: subtitleColor),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: subtitleColor, fontSize: 13),
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
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = theme.textTheme.titleMedium?.color;
    final subtitleColor = theme.textTheme.bodySmall?.color?.withValues(
      alpha: 0.78,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark ? AppColors.borderStrongDark : AppColors.borderLight,
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
    );
  }
}
