import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:louvor4_app/features/events/presentation/pages/event_detail_page.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_async_states.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../core/ui/widgets/primary_add_fab.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/music_projects_repository.dart';
import '../../domain/entities/music_event_detail_entity.dart';
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
  State<ProjectEventsTab> createState() => _ProjectEventsTabState();
}

class _ProjectEventsTabState extends State<ProjectEventsTab>
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

  Future<void> _onCreateEvent() async {
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
      child: Stack(
        children: [
          ListView(
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
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
          if (widget.isAdmin)
            Positioned(
              right: 16,
              bottom: 16,
              child: PrimaryAddFab(onPressed: _onCreateEvent),
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
                onPressed: _onCreateEvent,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = theme.textTheme.titleMedium?.color;
    final bodyColor = theme.textTheme.bodyMedium?.color;
    final mutedColor = bodyColor?.withValues(alpha: isDark ? 0.82 : 0.72);
    final month = _monthAbbreviation(event.date.month);
    final day = event.date.day.toString().padLeft(2, '0');
    final normalizedTime = event.time.trim().isEmpty
        ? '--:--'
        : formatTime(event.time.trim());
    final location = event.location.isEmpty
        ? 'Local não informado'
        : event.location;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EventDetailPage(eventId: event.id),
            ),
          );
        },
        child: Ink(
          decoration: appCardDecoration(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Coluna 1: data (mês + dia)
                SizedBox(
                  width: 68,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        month,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF0166FF),
                        ),
                      ),
                      Text(
                        day,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 30,
                          height: 1,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Coluna 2: título + linha de hora/local
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            normalizedTime,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF59E0B),
                                ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.place_outlined,
                            size: 15,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: const Color(0xFF10B981)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Coluna 3: métricas
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/users-round.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF2563EB),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.participantsCount}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/music.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFFD97706),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.repertoireCount}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 6),

                // Indicador de navegação
                SizedBox(
                  height: 68,
                  child: Center(
                    child: Icon(Icons.chevron_right_rounded, color: mutedColor),
                  ),
                ),
              ],
            ),
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
