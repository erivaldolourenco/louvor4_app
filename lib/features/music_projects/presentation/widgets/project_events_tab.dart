import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:louvor4_app/features/events/presentation/pages/event_detail_page.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_async_states.dart';
import '../../../../core/ui/widgets/app_cached_network_image.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../core/ui/widgets/spring_tap.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/music_projects_repository.dart';
import '../../domain/entities/music_event_detail_entity.dart';
import '../pages/create_project_event_batch_page.dart';
import '../pages/create_project_event_page.dart';

class ProjectEventsTab extends StatefulWidget {
  final String projectId;
  final bool isAdmin;
  final String? fallbackImageUrl;
  final MusicProjectsRepository repository;

  const ProjectEventsTab({
    super.key,
    required this.projectId,
    required this.isAdmin,
    required this.fallbackImageUrl,
    required this.repository,
  });

  @override
  State<ProjectEventsTab> createState() => ProjectEventsTabState();
}

class ProjectEventsTabState extends State<ProjectEventsTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<MusicEventDetailEntity> _events = const [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });
    }

    try {
      final events = await widget.repository.getProjectEvents(widget.projectId);
      if (!mounted) return;
      setState(() {
        _events = events;
        _hasError = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      if (silent) {
        AppFeedback.showError(
          _errorMessage ?? 'Erro ao carregar eventos do projeto.',
        );
      }
    } finally {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> createEvent() async {
    if (!widget.isAdmin) {
      AppFeedback.showError('Apenas administradores podem criar eventos.');
      return;
    }
    final created = await openCreateProjectEventPage(
      context,
      projectId: widget.projectId,
      repository: widget.repository,
    );

    if (created == true) {
      await _loadEvents(silent: true);
    }
  }

  Future<void> createEventBatch() async {
    if (!widget.isAdmin) {
      AppFeedback.showError('Apenas administradores podem criar eventos.');
      return;
    }
    final created = await openCreateProjectEventBatchPage(
      context,
      projectId: widget.projectId,
      repository: widget.repository,
    );

    if (created == true) {
      await _loadEvents(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final subtitleColor = theme.textTheme.bodySmall?.color?.withValues(
      alpha: 0.78,
    );

    if (_isLoading) {
      return const AppLoadingState();
    }

    if (_hasError && _events.isEmpty) {
      return AppErrorState(
        message: _errorMessage ?? 'Não foi possível carregar os eventos.',
        onRetry: _loadEvents,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eventos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Próximos eventos do projeto',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: subtitleColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_events.isEmpty) _buildEmptyState(context),
          if (_events.isNotEmpty)
            ..._events.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ProjectEventCard(event: event),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return AppCardSurface(
      radius: 16,
      padding: const EdgeInsets.all(24),
      child: AppEmptyState(
        icon: Icons.calendar_today_rounded,
        title: 'Nenhum evento agendado',
        description:
            'Este projeto ainda está vazio. Comece criando o primeiro evento para organizar sua escala.',
        action: widget.isAdmin
            ? FilledButton.icon(
                onPressed: createEvent,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Criar Primeiro Evento'),
              )
            : null,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _ProjectEventCard extends StatelessWidget {
  final MusicEventDetailEntity event;

  const _ProjectEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final month = _monthAbbreviation(event.date.month);
    final day = event.date.day.toString().padLeft(2, '0');
    final normalizedTime = event.time.trim().isEmpty
        ? '--:--'
        : formatTime(event.time.trim());
    return AppCardSurface(
      radius: AppRadius.card,
      child: SpringTap(
        pressedScale: 0.97,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EventDetailPage(eventId: event.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Bloco de data, estilo folhinha de calendário
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.thumbnail),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(
                      alpha: isDark ? 0.4 : 0.6,
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.thumbnail),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: cs.primary,
                          alignment: Alignment.center,
                          child: Text(
                            month,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onPrimary,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          width: double.infinity,
                          color: cs.surfaceContainerLow,
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              day,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 28,
                                height: 1,
                                color: isDark ? cs.onPrimary : cs.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (event.description?.isNotEmpty ?? false)
                          ? '$normalizedTime • ${event.description}'
                          : normalizedTime,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 22,
                      child: Row(
                        children: [
                          Expanded(
                            child: event.participantsProfileImages.isNotEmpty
                                ? Stack(
                                    children: List.generate(
                                      event.participantsProfileImages.length >
                                              5
                                          ? 5
                                          : event
                                                .participantsProfileImages
                                                .length,
                                      (index) => Positioned(
                                        left: index * 14.0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: cs.surface,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 10,
                                            backgroundColor: isDark
                                                ? cs.surfaceContainerLow
                                                : cs.outlineVariant,
                                            backgroundImage:
                                                appCachedImageProvider(
                                                  event
                                                      .participantsProfileImages[index],
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 6),
                          SvgPicture.asset(
                            'assets/icons/users-round.svg',
                            width: 15,
                            height: 15,
                            colorFilter: ColorFilter.mode(
                              cs.primary,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${event.participantsCount}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SvgPicture.asset(
                            'assets/icons/music.svg',
                            width: 15,
                            height: 15,
                            colorFilter: ColorFilter.mode(
                              cs.primary,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${event.repertoireCount}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  String _monthAbbreviation(int month) {
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
}
