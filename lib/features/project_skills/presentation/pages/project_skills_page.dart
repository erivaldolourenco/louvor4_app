import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_async_states.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../core/ui/widgets/primary_add_fab.dart';
import '../../data/repositories/project_skills_repository.dart';
import '../../data/repositories/project_skills_repository_impl.dart';
import '../../domain/entities/project_role.dart';
import '../../domain/entities/project_skill_entity.dart';
import '../state/project_skills_cubit.dart';
import '../state/project_skills_state.dart';
import '../widgets/add_project_skill_sheet.dart';

class ProjectSkillsPage extends StatefulWidget {
  final String projectId;
  final ProjectRole? initialRole;
  final String? initialProjectName;
  final ProjectSkillsRepository? repository;

  const ProjectSkillsPage({
    super.key,
    required this.projectId,
    this.initialRole,
    this.initialProjectName,
    this.repository,
  });

  @override
  State<ProjectSkillsPage> createState() => _ProjectSkillsPageState();
}

class _ProjectSkillsPageState extends State<ProjectSkillsPage>
    with AutomaticKeepAliveClientMixin {
  late final ProjectSkillsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ProjectSkillsCubit(
      repository: widget.repository ?? ProjectSkillsRepositoryImpl(),
      projectId: widget.projectId,
      initialRole: widget.initialRole,
      initialProjectName: widget.initialProjectName,
    )..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider.value(value: _cubit, child: const _ProjectSkillsView());
  }

  @override
  bool get wantKeepAlive => true;
}

class _ProjectSkillsView extends StatelessWidget {
  const _ProjectSkillsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectSkillsCubit, ProjectSkillsState>(
      builder: (context, state) {
        final cubit = context.read<ProjectSkillsCubit>();
        final subtitleColor = Theme.of(
          context,
        ).textTheme.bodySmall?.color?.withValues(alpha: 0.78);

        if (state.isInitialLoading) {
          return const AppLoadingState();
        }

        if (state.status == ProjectSkillsStatus.failure &&
            state.skills.isEmpty) {
          return AppErrorState(
            message:
                state.errorMessage ?? 'Não foi possível carregar as funções.',
            onRetry: () => cubit.load(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => cubit.load(silent: true),
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
                              'Funções',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state.projectName?.trim().isNotEmpty == true
                                  ? 'Funções disponíveis em ${state.projectName}'
                                  : 'Instrumentos, vocais e funções do projeto',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: subtitleColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (state.isEmpty)
                    _SkillsEmptyState(canManageSkills: state.canManageSkills),
                  if (state.skills.isNotEmpty)
                    ...state.skills.map(
                      (skill) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProjectSkillCard(skill: skill),
                      ),
                    ),
                ],
              ),
              if (state.canManageSkills)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: PrimaryAddFab(
                    onPressed: () => _showAddSkillSheet(context),
                    heroTag: 'project-skills-add-fab',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddSkillSheet(BuildContext context) async {
    final cubit = context.read<ProjectSkillsCubit>();
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const AddProjectSkillSheet()),
    );

    if (success == true) {
      AppFeedback.showSuccess('Função adicionada com sucesso.');
    }
  }
}

class _SkillsEmptyState extends StatelessWidget {
  final bool canManageSkills;

  const _SkillsEmptyState({required this.canManageSkills});

  @override
  Widget build(BuildContext context) {
    return AppCardSurface(
      radius: 16,
      padding: const EdgeInsets.all(24),
      child: AppEmptyState(
        icon: Icons.music_off_rounded,
        title: 'Nenhuma função cadastrada',
        description: canManageSkills
            ? 'Cadastre funções como Vocal, Guitarra ou Teclado para usar nas escalas.'
            : 'Este projeto ainda não possui funções musicais cadastradas.',
      ),
    );
  }
}

class _ProjectSkillCard extends StatelessWidget {
  final ProjectSkillEntity skill;

  const _ProjectSkillCard({required this.skill});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProjectSkillsCubit>();
    final state = context.watch<ProjectSkillsCubit>().state;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = theme.textTheme.titleMedium?.color;
    final isDeleting = state.isDeletingSkill(skill.id);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: appCardDecoration(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF172554)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: Color(0xFF0166FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  skill.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
              ),
              if (state.canManageSkills) ...[
                const SizedBox(width: 10),
                isDeleting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _CircularSkillActionButton(
                        tooltip: 'Excluir função',
                        onPressed: () => _onDeleteSkill(context, cubit, skill),
                        assetPath: 'assets/icons/trash-2.svg',
                        iconColor: const Color(0xFFB3261E),
                        backgroundColor: isDark
                            ? const Color(0xFF2A1313)
                            : const Color(0xFFFFF1F2),
                        borderColor: isDark
                            ? const Color(0xFF7F1D1D)
                            : const Color(0xFFFECDD3),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onDeleteSkill(
    BuildContext context,
    ProjectSkillsCubit cubit,
    ProjectSkillEntity skill,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir função'),
          content: Text(
            'Deseja excluir a função "${skill.name}"? Essa ação não poderá ser desfeita.',
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
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final deleted = await cubit.deleteSkill(skill);
    if (!context.mounted) return;

    if (deleted) {
      AppFeedback.showSuccess('Função excluída com sucesso.');
    } else if (cubit.state.actionErrorMessage != null) {
      AppFeedback.showError(cubit.state.actionErrorMessage!);
    }
  }
}

class _CircularSkillActionButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onPressed;
  final String assetPath;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;

  const _CircularSkillActionButton({
    required this.tooltip,
    required this.onPressed,
    required this.assetPath,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: SvgPicture.asset(
                assetPath,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
