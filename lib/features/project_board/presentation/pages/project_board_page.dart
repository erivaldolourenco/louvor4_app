import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_async_states.dart';
import '../../../../core/ui/widgets/fade_slide_in.dart';
import '../../../../core/ui/widgets/primary_add_fab.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../../music_projects/data/impl/music_projects_repository_impl.dart';
import '../../data/impl/responsibilities_repository_impl.dart';
import '../../data/responsibilities_repository.dart';
import '../../domain/entities/responsibility_entity.dart';
import '../cubit/project_board_cubit.dart';
import '../cubit/project_board_state.dart';
import '../widgets/responsibility_card.dart';
import '../widgets/responsibility_form_sheet.dart';
import 'responsibility_history_page.dart';

Future<void> openProjectBoardPage(
  BuildContext context, {
  required String projectId,
  String? projectName,
  required bool canManage,
  String? currentUserId,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ProjectBoardPage(
        projectId: projectId,
        projectName: projectName,
        canManage: canManage,
        currentUserId: currentUserId,
      ),
    ),
  );
}

/// Mural do projeto: responsabilidades e quem está com cada uma.
class ProjectBoardPage extends StatelessWidget {
  final String projectId;
  final String? projectName;
  final bool canManage;
  final String? currentUserId;

  const ProjectBoardPage({
    super.key,
    required this.projectId,
    this.projectName,
    required this.canManage,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ResponsibilitiesRepository>(
      create: (_) => ResponsibilitiesRepositoryImpl(),
      child: BlocProvider(
        create: (context) => ProjectBoardCubit(
          context.read<ResponsibilitiesRepository>(),
          projectId: projectId,
        )..load(),
        child: _ProjectBoardView(
          projectName: projectName,
          canManage: canManage,
          currentUserId: currentUserId,
        ),
      ),
    );
  }
}

class _ProjectBoardView extends StatelessWidget {
  final String? projectName;
  final bool canManage;
  final String? currentUserId;

  const _ProjectBoardView({
    required this.projectName,
    required this.canManage,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectBoardCubit, ProjectBoardState>(
      builder: (context, state) {
        final cubit = context.read<ProjectBoardCubit>();

        return Scaffold(
          appBar: StandardSectionAppBar(
            title: 'Mural',
            subtitle: projectName ?? 'Responsabilidades do projeto',
          ),
          floatingActionButton: canManage && !state.isInitialLoading
              ? PrimaryAddFab(
                  heroTag: 'project-board-fab',
                  onPressed: () => _openForm(context, cubit),
                )
              : null,
          body: SafeArea(
            child: Builder(
              builder: (context) {
                if (state.isInitialLoading) {
                  return const AppLoadingState();
                }
                if (state.status == ProjectBoardStatus.failure &&
                    state.responsibilities.isEmpty) {
                  return AppErrorState(
                    message:
                        state.errorMessage ??
                        'Não foi possível carregar o mural.',
                    onRetry: () => cubit.load(),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => cubit.load(silent: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 96),
                    children: [
                      if (state.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
                          child: AppEmptyState(
                            icon: Icons.assignment_ind_outlined,
                            title: 'Nenhuma responsabilidade ainda',
                            description: canManage
                                ? 'Cadastre funções fixas do ministério, como Direção musical ou Som, e defina quem cuida de cada uma em cada período.'
                                : 'Quando o líder cadastrar as responsabilidades do projeto, elas aparecem aqui.',
                            action: canManage
                                ? FilledButton.icon(
                                    onPressed: () => _openForm(context, cubit),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Criar responsabilidade'),
                                  )
                                : null,
                          ),
                        )
                      else ...[
                        _SectionTitle(
                          title: 'Responsabilidades',
                          count: state.responsibilities.length,
                        ),
                        SizedBox(
                          height: ResponsibilityCard.height,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: state.responsibilities.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final responsibility =
                                  state.responsibilities[index];
                              return FadeSlideIn(
                                delay: Duration(
                                  milliseconds: 40 * index.clamp(0, 8),
                                ),
                                child: ResponsibilityCard(
                                  responsibility: responsibility,
                                  currentUserId: currentUserId,
                                  canManage: canManage,
                                  isDeleting:
                                      state.deletingId == responsibility.id,
                                  onTap: () => _openHistory(
                                    context,
                                    cubit,
                                    responsibility,
                                  ),
                                  onEdit: () => _openForm(
                                    context,
                                    cubit,
                                    responsibility: responsibility,
                                  ),
                                  onDelete: () => _confirmDelete(
                                    context,
                                    cubit,
                                    responsibility,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _openForm(
    BuildContext context,
    ProjectBoardCubit cubit, {
    ResponsibilityEntity? responsibility,
  }) async {
    final saved = await showResponsibilityFormSheet(
      context,
      cubit: cubit,
      responsibility: responsibility,
    );
    if (saved == null || !context.mounted) return;

    if (responsibility != null) {
      AppFeedback.showSuccess('Responsabilidade atualizada.');
      return;
    }
    // Recém-criada: já abre o histórico com o formulário de responsável
    AppFeedback.showSuccess(
      'Responsabilidade criada. Agora defina quem vai cuidar dela.',
    );
    await _openHistory(context, cubit, saved, openAssignOnStart: true);
  }

  Future<void> _openHistory(
    BuildContext context,
    ProjectBoardCubit cubit,
    ResponsibilityEntity responsibility, {
    bool openAssignOnStart = false,
  }) async {
    final changed = await openResponsibilityHistoryPage(
      context,
      repository: context.read<ResponsibilitiesRepository>(),
      projectsRepository: MusicProjectsRepositoryImpl(),
      projectId: cubit.projectId,
      responsibility: responsibility,
      canManage: canManage,
      currentUserId: currentUserId,
      openAssignOnStart: openAssignOnStart,
    );
    if (changed == true) {
      await cubit.load(silent: true);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ProjectBoardCubit cubit,
    ResponsibilityEntity responsibility,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir responsabilidade?'),
        content: Text(
          '"${responsibility.name}" e todo o histórico de responsáveis serão excluídos. Essa ação não pode ser desfeita.',
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
    if (confirmed != true || !context.mounted) return;

    final success = await cubit.delete(responsibility);
    if (!context.mounted) return;
    if (success) {
      AppFeedback.showSuccess('Responsabilidade excluída.');
    } else if (cubit.state.actionErrorMessage != null) {
      AppFeedback.showError(cubit.state.actionErrorMessage!);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
