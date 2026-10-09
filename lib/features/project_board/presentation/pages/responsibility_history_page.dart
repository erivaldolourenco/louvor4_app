import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_async_states.dart';
import '../../../../core/ui/widgets/app_cached_network_image.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../core/ui/widgets/primary_add_fab.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../../music_projects/data/music_projects_repository.dart';
import '../../data/responsibilities_repository.dart';
import '../../domain/entities/responsibility_entity.dart';
import '../widgets/assignment_form_sheet.dart';
import '../widgets/responsibility_dates.dart';

/// Retorna `true` se algum período foi alterado (para o mural recarregar).
Future<bool?> openResponsibilityHistoryPage(
  BuildContext context, {
  required ResponsibilitiesRepository repository,
  required MusicProjectsRepository projectsRepository,
  required String projectId,
  required ResponsibilityEntity responsibility,
  required bool canManage,
  String? currentUserId,
  bool openAssignOnStart = false,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => ResponsibilityHistoryPage(
        repository: repository,
        projectsRepository: projectsRepository,
        projectId: projectId,
        responsibility: responsibility,
        canManage: canManage,
        currentUserId: currentUserId,
        openAssignOnStart: openAssignOnStart,
      ),
    ),
  );
}

class ResponsibilityHistoryPage extends StatefulWidget {
  final ResponsibilitiesRepository repository;
  final MusicProjectsRepository projectsRepository;
  final String projectId;
  final ResponsibilityEntity responsibility;
  final bool canManage;
  final String? currentUserId;

  /// Abre o formulário de adicionar responsável assim que o histórico carrega
  /// (usado logo após criar a responsabilidade).
  final bool openAssignOnStart;

  const ResponsibilityHistoryPage({
    super.key,
    required this.repository,
    required this.projectsRepository,
    required this.projectId,
    required this.responsibility,
    required this.canManage,
    this.currentUserId,
    this.openAssignOnStart = false,
  });

  @override
  State<ResponsibilityHistoryPage> createState() =>
      _ResponsibilityHistoryPageState();
}

class _ResponsibilityHistoryPageState extends State<ResponsibilityHistoryPage> {
  List<ResponsibilityAssignmentEntity> _history = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _deletingId;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load().then((_) {
      if (mounted && widget.openAssignOnStart && widget.canManage) {
        _openAssignForm();
      }
    });
  }

  Future<void> _openAssignForm() async {
    final saved = await showAssignmentFormSheet(
      context,
      repository: widget.repository,
      projectsRepository: widget.projectsRepository,
      projectId: widget.projectId,
      responsibility: widget.responsibility,
      history: _history,
    );
    if (saved == true && mounted) {
      _changed = true;
      AppFeedback.showSuccess('Responsável adicionado.');
      await _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = _history.isEmpty;
      _errorMessage = null;
    });
    try {
      final history = await widget.repository.getHistory(
        widget.projectId,
        widget.responsibility.id,
      );
      if (!mounted) return;
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _delete(ResponsibilityAssignmentEntity period) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir período?'),
        content: Text(
          'O período de ${period.fullName} (${formatPeriod(period.startDate, period.endDate)}) será removido do histórico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingId = period.id);
    try {
      await widget.repository.deleteAssignment(
        widget.projectId,
        widget.responsibility.id,
        period.id,
      );
      if (!mounted) return;
      setState(() {
        _deletingId = null;
        _changed = true;
        _history = _history.where((p) => p.id != period.id).toList();
      });
      AppFeedback.showSuccess('Período excluído.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _deletingId = null);
      AppFeedback.showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = widget.responsibility.description;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: StandardSectionAppBar(
          title: widget.responsibility.name,
          subtitle: 'Histórico de responsáveis',
        ),
        floatingActionButton: widget.canManage && !_isLoading
            ? PrimaryAddFab(
                heroTag: 'responsibility-history-fab',
                iconAsset: 'assets/icons/user-round-plus.svg',
                onPressed: _openAssignForm,
              )
            : null,
        body: SafeArea(
          child: Builder(
            builder: (context) {
              if (_isLoading) return const AppLoadingState();
              if (_errorMessage != null && _history.isEmpty) {
                return AppErrorState(message: _errorMessage!, onRetry: _load);
              }

              final today = dateOnly(DateTime.now());
              return RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    if (description != null) ...[
                      Text(description, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 16),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Responsáveis',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (_history.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: AppEmptyState(
                          icon: Icons.history_rounded,
                          title: 'Ninguém definido ainda',
                          description: widget.canManage
                              ? 'Toque no botão + para definir quem cuida desta responsabilidade e por quanto tempo.'
                              : 'Quando o líder definir um responsável, o período aparece aqui.',
                        ),
                      )
                    else
                      ..._history.map(
                        (period) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PeriodTile(
                            period: period,
                            today: today,
                            isMine:
                                widget.currentUserId != null &&
                                period.userId == widget.currentUserId,
                            isDeleting: _deletingId == period.id,
                            onDelete: widget.canManage
                                ? () => _delete(period)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PeriodTile extends StatelessWidget {
  final ResponsibilityAssignmentEntity period;
  final DateTime today;
  final bool isMine;
  final bool isDeleting;
  final VoidCallback? onDelete;

  const _PeriodTile({
    required this.period,
    required this.today,
    required this.isMine,
    required this.isDeleting,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isCurrent =
        !today.isBefore(period.startDate) && !today.isAfter(period.endDate);
    final isPast = period.endDate.isBefore(today);
    final avatarImage = appCachedImageProvider(period.profileImage);

    final (String label, Color background, Color foreground) = isCurrent
        ? ('Atual', cs.primaryContainer, cs.onPrimaryContainer)
        : isPast
        ? ('Encerrado', cs.surfaceContainerHigh, cs.onSurfaceVariant)
        : ('Agendado', cs.tertiaryContainer, cs.onTertiaryContainer);

    return Opacity(
      opacity: isPast ? 0.7 : 1,
      child: DecoratedBox(
        decoration: appCardDecoration(
          context,
          radius: AppRadius.cardHero,
          borderColor: isCurrent ? cs.primary.withValues(alpha: 0.5) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: cs.primaryContainer,
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? Icon(Icons.person_rounded, color: cs.onPrimaryContainer)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period.accountDeleted
                          ? 'Conta excluída'
                          : isMine
                          ? '${period.fullName} (você)'
                          : period.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatFullDate(period.startDate)} a ${formatFullDate(period.endDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isDeleting)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (onDelete != null)
                IconButton(
                  tooltip: 'Excluir período',
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, color: cs.error),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
