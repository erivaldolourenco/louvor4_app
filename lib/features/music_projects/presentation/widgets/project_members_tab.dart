import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:louvor4_app/core/ui/widgets/app_cached_network_image.dart';
import 'package:louvor4_app/core/ui/widgets/user_profile_dialog.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_async_states.dart';
import '../../../../core/ui/widgets/app_buttons.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../core/ui/widgets/circular_icon_action_button.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
import '../../../../core/ui/widgets/primary_add_fab.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../../../core/utils/url_utils.dart';
import '../../data/music_projects_repository.dart';
import '../../domain/entities/project_member_entity.dart';
import '../../domain/entities/project_member_role.dart';
import '../cubit/project_members_cubit.dart';
import '../cubit/project_members_state.dart';

class ProjectMembersTab extends StatefulWidget {
  final String projectId;
  final bool canManageMembers;
  final MusicProjectsRepository repository;
  final String? currentUserId;
  final VoidCallback? onLeaveProject;

  const ProjectMembersTab({
    super.key,
    required this.projectId,
    required this.canManageMembers,
    required this.repository,
    this.currentUserId,
    this.onLeaveProject,
  });

  @override
  State<ProjectMembersTab> createState() => _ProjectMembersTabState();
}

class _ProjectMembersTabState extends State<ProjectMembersTab>
    with AutomaticKeepAliveClientMixin {
  late final ProjectMembersCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ProjectMembersCubit(
      repository: widget.repository,
      projectId: widget.projectId,
      canManageMembers: widget.canManageMembers,
      currentUserId: widget.currentUserId,
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
    return BlocProvider.value(
      value: _cubit,
      child: _ProjectMembersTabView(onLeaveProject: widget.onLeaveProject),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _ProjectMembersTabView extends StatelessWidget {
  final VoidCallback? onLeaveProject;

  const _ProjectMembersTabView({this.onLeaveProject});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectMembersCubit, ProjectMembersState>(
      builder: (context, state) {
        final cubit = context.read<ProjectMembersCubit>();
        final subtitleColor = Theme.of(
          context,
        ).textTheme.bodySmall?.color?.withValues(alpha: 0.78);

        if (state.isLoading) {
          return const AppLoadingState();
        }

        if (state.status == ProjectMembersStatus.failure &&
            state.members.isEmpty) {
          return AppErrorState(
            message:
                state.errorMessage ?? 'Não foi possível carregar os membros.',
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
                              'Membros',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Equipe do projeto, permissões e funções musicais',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: subtitleColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (state.members.isEmpty)
                    _MembersEmptyState(
                      canManageMembers: cubit.canManageMembers,
                    ),
                  if (state.members.isNotEmpty)
                    ...state.members.map(
                      (member) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProjectMemberCard(
                          member: member,
                          onLeaveProject: onLeaveProject,
                        ),
                      ),
                    ),
                ],
              ),
              if (cubit.canManageMembers)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: PrimaryAddFab(
                    onPressed: () => _showAddMemberSheet(context),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddMemberSheet(BuildContext context) async {
    final cubit = context.read<ProjectMembersCubit>();
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const _AddProjectMemberSheet(),
      ),
    );

    if (success == true) {
      AppFeedback.showSuccess('Membro adicionado com sucesso.');
    }
  }
}

class _MembersEmptyState extends StatelessWidget {
  final bool canManageMembers;

  const _MembersEmptyState({required this.canManageMembers});

  @override
  Widget build(BuildContext context) {
    return AppCardSurface(
      radius: 16,
      padding: const EdgeInsets.all(24),
      child: AppEmptyState(
        icon: Icons.group_off_rounded,
        title: 'Nenhum membro vinculado',
        description: canManageMembers
            ? 'Adicione integrantes pelo username para começar a montar a equipe do projeto.'
            : 'Este projeto ainda não possui membros cadastrados.',
      ),
    );
  }
}

class _ProjectMemberCard extends StatelessWidget {
  final ProjectMemberEntity member;
  final VoidCallback? onLeaveProject;

  const _ProjectMemberCard({required this.member, this.onLeaveProject});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProjectMembersCubit>();
    final state = context.watch<ProjectMembersCubit>().state;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final titleColor = theme.textTheme.titleMedium?.color;
    final skillNames = member.skillIds
        .map(
          (skillId) => state.skills
              .where((skill) => skill.id == skillId)
              .map((skill) => skill.name)
              .firstOrNull,
        )
        .whereType<String>()
        .toList();
    final isBusy = state.isBusy(member.id);

    final decoration = appCardDecoration(
      context,
      color: member.isOwner
          ? Color.alphaBlend(
              cs.tertiaryContainer.withValues(alpha: 0.18),
              cs.surfaceContainerLow,
            )
          : null,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: decoration.borderRadius,
        boxShadow: decoration.boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: decoration.copyWith(boxShadow: const []),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    onTap: () => showUserProfileDialog(
                      context,
                      name: member.fullName,
                      profileImageUrl: member.profileImage,
                      username: member.username,
                      email: member.email,
                      projectPermission: member.projectRole.label,
                      musicSkills: skillNames,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _MemberAvatar(
                            imageUrl: member.profileImage,
                            fullName: member.fullName,
                            role: member.projectRole,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        member.fullName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: titleColor,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _RoleBadge(role: member.projectRole),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: skillNames.isEmpty
                                      ? const [
                                          _SkillTag(
                                            label: 'Sem funções musicais',
                                            muted: true,
                                          ),
                                        ]
                                      : skillNames
                                            .map(
                                              (name) => _SkillTag(label: name),
                                            )
                                            .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Builder(
                  builder: (context) {
                    final canEdit = cubit.canEditMember(member);
                    final canRemove = cubit.canRemoveMember(member);
                    final canLeave = cubit.canLeaveProject(member);
                    final hasActions = canEdit || canRemove || canLeave;

                    if (!hasActions) return const SizedBox.shrink();

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 10),
                        if (isBusy)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (canEdit)
                                CircularIconActionButton(
                                  tooltip: 'Editar membro',
                                  onPressed: () async {
                                    final success = await _openEditMemberPage(
                                      context,
                                      member.id,
                                    );
                                    if (success == true) {
                                      AppFeedback.showSuccess(
                                        'Membro atualizado com sucesso.',
                                      );
                                    }
                                  },
                                  assetPath: 'assets/icons/settings-2.svg',
                                  iconColor: cs.onPrimaryContainer,
                                  backgroundColor: cs.primaryContainer,
                                  borderColor: cs.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              if (canEdit && canRemove)
                                const SizedBox(width: 8),
                              if (canRemove)
                                CircularIconActionButton(
                                  tooltip: 'Remover membro',
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Remover membro'),
                                        content: Text(
                                          'Deseja remover ${member.fullName} do projeto?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text('Cancelar'),
                                          ),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: cs.error,
                                              foregroundColor: cs.onError,
                                            ),
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: const Text('Remover'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed != true) return;
                                    final success = await cubit.removeMember(
                                      member,
                                    );
                                    if (!context.mounted) return;
                                    if (success) {
                                      AppFeedback.showSuccess(
                                        'Membro removido com sucesso.',
                                      );
                                    } else if (cubit.state.actionErrorMessage !=
                                        null) {
                                      AppFeedback.showError(
                                        cubit.state.actionErrorMessage!,
                                      );
                                    }
                                  },
                                  assetPath: 'assets/icons/trash-2.svg',
                                  iconColor: cs.onErrorContainer,
                                  backgroundColor: cs.errorContainer,
                                  borderColor: cs.error.withValues(alpha: 0.3),
                                ),
                              if (canLeave)
                                IconButton(
                                  tooltip: 'Sair do projeto',
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Sair do projeto'),
                                        content: const Text(
                                          'Tem certeza que deseja sair deste projeto? Você perderá acesso a eventos, membros e configurações.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text('Cancelar'),
                                          ),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: cs.error,
                                              foregroundColor: cs.onError,
                                            ),
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: const Text('Sair'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed != true) return;
                                    final success = await cubit.leaveProject(
                                      member,
                                    );
                                    if (!context.mounted) return;
                                    if (success) {
                                      onLeaveProject?.call();
                                    } else if (cubit.state.actionErrorMessage !=
                                        null) {
                                      AppFeedback.showError(
                                        cubit.state.actionErrorMessage!,
                                      );
                                    }
                                  },
                                  style: IconButton.styleFrom(
                                    backgroundColor: cs.errorContainer,
                                    shape: CircleBorder(
                                      side: BorderSide(
                                        color: cs.error.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    minimumSize: const Size(40, 40),
                                    padding: EdgeInsets.zero,
                                  ),
                                  icon: Icon(
                                    Icons.logout_rounded,
                                    size: 18,
                                    color: cs.onErrorContainer,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _openEditMemberPage(BuildContext context, String memberId) {
    final cubit = context.read<ProjectMembersCubit>();
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: _EditProjectMemberPage(memberId: memberId),
        ),
      ),
    );
  }
}

class _AddProjectMemberSheet extends StatefulWidget {
  const _AddProjectMemberSheet();

  @override
  State<_AddProjectMemberSheet> createState() => _AddProjectMemberSheetState();
}

class _AddProjectMemberSheetState extends State<_AddProjectMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = context.watch<ProjectMembersCubit>().state;
    final cubit = context.read<ProjectMembersCubit>();
    final isSubmitting = state.submission == ProjectMembersSubmission.adding;

    return _MemberSheetScaffold(
      title: 'Adicionar membro',
      subtitle: 'Informe o username do integrante para convidá-lo ao projeto.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _usernameController,
              enabled: !isSubmitting,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'ex: joao.silva',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Informe o username do membro.';
                }
                return null;
              },
            ),
            if (state.actionErrorMessage != null) ...[
              const SizedBox(height: 12),
              _InlineErrorMessage(message: state.actionErrorMessage!),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(context).maybePop(false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPrimaryButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            final success = await cubit.addMember(
                              _usernameController.text,
                            );
                            if (!mounted) return;
                            if (success) {
                              Navigator.of(this.context).pop(true);
                            } else if (cubit.state.actionErrorMessage != null) {
                              AppFeedback.showError(
                                cubit.state.actionErrorMessage!,
                              );
                            }
                          },
                    child: isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : const Text('Adicionar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProjectMemberPage extends StatefulWidget {
  final String memberId;

  const _EditProjectMemberPage({required this.memberId});

  @override
  State<_EditProjectMemberPage> createState() => _EditProjectMemberPageState();
}

class _EditProjectMemberPageState extends State<_EditProjectMemberPage> {
  ProjectMemberEntity? _member;
  bool _isLoading = true;
  ProjectMemberRole _selectedRole = ProjectMemberRole.member;
  final Set<String> _selectedSkillIds = {};

  @override
  void initState() {
    super.initState();
    _loadMember();
  }

  Future<void> _loadMember() async {
    final cubit = context.read<ProjectMembersCubit>();
    final member = await cubit.loadMemberDetail(widget.memberId);
    if (!mounted) return;

    if (member == null) {
      setState(() => _isLoading = false);
      AppFeedback.showError(
        cubit.state.actionErrorMessage ??
            'Não foi possível carregar os detalhes do membro.',
      );
      return;
    }

    setState(() {
      _member = member;
      _selectedRole = member.projectRole;
      _selectedSkillIds
        ..clear()
        ..addAll(member.skillIds);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProjectMembersCubit>();
    final state = context.watch<ProjectMembersCubit>().state;
    final member = _member;
    final isSubmitting =
        member != null &&
        state.submission == ProjectMembersSubmission.updating &&
        state.activeMemberId == member.id;

    return Scaffold(
      appBar: const StandardSectionAppBar(
        title: 'Editar Membro',
        subtitle: 'Ajuste permissões e funções musicais do integrante',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : member == null
          ? SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _InlineErrorMessage(
                        message: 'Não foi possível abrir este membro.',
                      ),
                      const SizedBox(height: 18),
                      AppPrimaryButton(
                        onPressed: _loadMember,
                        icon: Icons.refresh_rounded,
                        height: 48,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MemberHeader(member: member),
                    const SizedBox(height: 18),
                    _PermissionCard(
                      member: member,
                      selectedRole: _selectedRole,
                      onRoleChanged: cubit.canChangeAdministrativeAccess(member)
                          ? (isAdmin) {
                              setState(() {
                                _selectedRole = isAdmin
                                    ? ProjectMemberRole.admin
                                    : ProjectMemberRole.member;
                              });
                            }
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Funções musicais',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (state.skills.isEmpty)
                      const _InlineHint(
                        message:
                            'Nenhuma função musical cadastrada para este projeto.',
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: state.skills
                            .map(
                              (skill) => FilterChip(
                                label: Text(skill.name),
                                selected: _selectedSkillIds.contains(skill.id),
                                onSelected: isSubmitting
                                    ? null
                                    : (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedSkillIds.add(skill.id);
                                          } else {
                                            _selectedSkillIds.remove(skill.id);
                                          }
                                        });
                                      },
                                selectedColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                checkmarkColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _selectedSkillIds.contains(skill.id)
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    if (state.actionErrorMessage != null) ...[
                      const SizedBox(height: 14),
                      _InlineErrorMessage(message: state.actionErrorMessage!),
                    ],
                    const SizedBox(height: 22),
                    AppPrimaryButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final success = await cubit.updateMember(
                                member: member,
                                projectRole: _selectedRole,
                                skillIds: _selectedSkillIds.toList(),
                              );
                              if (!mounted) return;
                              if (success) {
                                Navigator.of(this.context).pop(true);
                              } else if (cubit.state.actionErrorMessage !=
                                  null) {
                                AppFeedback.showError(
                                  cubit.state.actionErrorMessage!,
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar alterações'),
                    ),
                    const SizedBox(height: 10),
                    AppSecondaryButton(
                      onPressed: isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _MemberSheetScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _MemberSheetScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(title: title, subtitle: subtitle, child: child);
  }
}

class _MemberHeader extends StatelessWidget {
  final ProjectMemberEntity member;

  const _MemberHeader({required this.member});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final titleColor = theme.textTheme.titleMedium?.color;
    final mutedColor = theme.textTheme.bodySmall?.color?.withValues(
      alpha: 0.78,
    );

    return AppCardSurface(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _MemberAvatar(
            imageUrl: member.profileImage,
            fullName: member.fullName,
            role: member.projectRole,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${member.username}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: mutedColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final ProjectMemberEntity member;
  final ProjectMemberRole selectedRole;
  final ValueChanged<bool>? onRoleChanged;

  const _PermissionCard({
    required this.member,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = selectedRole.hasAdministrativeAccess;

    return SizedBox(
      width: double.infinity,
      child: AppCardSurface(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permissão no projeto',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: isAdmin,
              onChanged: onRoleChanged,
              title: const Text(
                'Acesso administrativo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                member.isOwner
                    ? 'O owner do projeto permanece com privilégios administrativos bloqueados.'
                    : isAdmin
                    ? 'Pode gerenciar membros, eventos e configurações do projeto.'
                    : 'Acesso restrito como membro comum.',
              ),
            ),
            if (member.isOwner) ...[
              const SizedBox(height: 6),
              const _LockedOwnerBanner(),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fullName;
  final ProjectMemberRole? role;

  const _MemberAvatar({
    required this.imageUrl,
    required this.fullName,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ringColor = switch (role) {
      ProjectMemberRole.owner => cs.tertiary,
      ProjectMemberRole.admin => cs.primary,
      ProjectMemberRole.member || null => null,
    };

    final avatar = UrlUtils.isValidNetworkUrl(imageUrl)
        ? CircleAvatar(
            radius: 26,
            backgroundImage: appCachedImageProvider(imageUrl),
          )
        : CircleAvatar(
            radius: 26,
            backgroundColor: cs.primaryContainer,
            child: Text(
              (fullName.trim().isEmpty ? '?' : fullName.trim()[0])
                  .toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          );

    if (ringColor == null) return avatar;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 2),
      ),
      child: avatar,
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final ProjectMemberRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (background, foreground) = switch (role) {
      ProjectMemberRole.owner => (cs.tertiaryContainer, cs.onTertiaryContainer),
      ProjectMemberRole.admin => (cs.primaryContainer, cs.onPrimaryContainer),
      ProjectMemberRole.member => (cs.surfaceContainerLow, cs.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        role.label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}

class _SkillTag extends StatelessWidget {
  final String label;
  final bool muted;

  const _SkillTag({required this.label, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: muted ? cs.surfaceContainer : cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: muted ? Border.all(color: cs.outlineVariant) : null,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: muted ? cs.onSurfaceVariant : cs.onPrimaryContainer,
          fontWeight: muted ? FontWeight.w500 : FontWeight.w700,
        ),
      ),
    );
  }
}

class _LockedOwnerBanner extends StatelessWidget {
  const _LockedOwnerBanner();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, size: 18, color: cs.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Owner bloqueado para alteração de privilégio administrativo.',
              style: TextStyle(
                color: cs.onTertiaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineErrorMessage extends StatelessWidget {
  final String message;

  const _InlineErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: cs.error.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InlineHint extends StatelessWidget {
  final String message;

  const _InlineHint({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
