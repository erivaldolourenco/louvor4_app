import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_async_states.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
import '../../../../core/ui/widgets/primary_add_fab.dart';
import '../../../../core/utils/url_utils.dart';
import '../../data/music_projects_repository.dart';
import '../../domain/entities/project_member_entity.dart';
import '../../domain/entities/project_member_role.dart';
import '../cubit/project_members_cubit.dart';
import '../cubit/project_members_state.dart';

class ProjectMembersTab extends StatelessWidget {
  final String projectId;
  final bool canManageMembers;
  final MusicProjectsRepository repository;

  const ProjectMembersTab({
    super.key,
    required this.projectId,
    required this.canManageMembers,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProjectMembersCubit(
        repository: repository,
        projectId: projectId,
        canManageMembers: canManageMembers,
      )..load(),
      child: const _ProjectMembersTabView(),
    );
  }
}

class _ProjectMembersTabView extends StatelessWidget {
  const _ProjectMembersTabView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectMembersCubit, ProjectMembersState>(
      builder: (context, state) {
        final cubit = context.read<ProjectMembersCubit>();

        if (state.isLoading) {
          return const AppLoadingState();
        }

        if (state.status == ProjectMembersStatus.failure &&
            state.members.isEmpty) {
          return AppErrorState(
            message: state.errorMessage ?? 'Não foi possível carregar os membros.',
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
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Equipe do projeto, permissões e funções musicais',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (state.members.isEmpty)
                    _MembersEmptyState(canManageMembers: cubit.canManageMembers),
                  if (state.members.isNotEmpty)
                    ...state.members.map(
                      (member) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProjectMemberCard(member: member),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
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

  const _ProjectMemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProjectMembersCubit>();
    final state = context.watch<ProjectMembersCubit>().state;
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

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 14,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MemberAvatar(
                imageUrl: member.profileImage,
                fullName: member.fullName,
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
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
                                .map((name) => _SkillTag(label: name))
                                .toList(),
                    ),
                  ],
                ),
              ),
              if (cubit.canManageMembers) ...[
                const SizedBox(width: 10),
                isBusy
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Color(0xFF64748B),
                        ),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            final success = await _showEditMemberSheet(
                              context,
                              member.id,
                            );
                            if (success == true) {
                              AppFeedback.showSuccess(
                                'Membro atualizado com sucesso.',
                              );
                            }
                            return;
                          }

                          if (value == 'remove') {
                            if (!context.mounted) return;
                            final confirmed = await _confirmRemove(context);
                            if (confirmed != true) return;

                            final removed = await cubit.removeMember(member);
                            if (!context.mounted) return;

                            if (removed) {
                              AppFeedback.showSuccess(
                                'Membro removido com sucesso.',
                              );
                            } else if (cubit.state.actionErrorMessage != null) {
                              AppFeedback.showError(
                                cubit.state.actionErrorMessage!,
                              );
                            }
                          }
                        },
                        itemBuilder: (_) {
                          return [
                            if (cubit.canEditMember(member))
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                            if (cubit.canRemoveMember(member))
                              const PopupMenuItem<String>(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Remover'),
                                  ],
                                ),
                              ),
                          ];
                        },
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showEditMemberSheet(BuildContext context, String memberId) {
    final cubit = context.read<ProjectMembersCubit>();
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _EditProjectMemberSheet(memberId: memberId),
      ),
    );
  }

  Future<bool?> _confirmRemove(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover membro'),
          content: Text(
            'Deseja remover ${member.fullName} deste projeto? Essa ação pode ser desfeita adicionando o membro novamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB3261E),
              ),
              child: const Text('Remover'),
            ),
          ],
        );
      },
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
    final state = context.watch<ProjectMembersCubit>().state;
    final cubit = context.read<ProjectMembersCubit>();
    final isSubmitting = state.submission == ProjectMembersSubmission.adding;

    return _MemberSheetScaffold(
      title: 'Adicionar membro',
      subtitle: 'Informe o username do integrante para convidá-lo ao projeto.',
      icon: Icons.group_add_rounded,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FormSectionLabel(label: 'Username'),
            TextFormField(
              controller: _usernameController,
              enabled: !isSubmitting,
              textInputAction: TextInputAction.done,
              decoration: appFormFieldDecoration(
                hintText: 'ex: joao.silva',
                prefixIcon: Icons.alternate_email_rounded,
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
                  child: OutlinedButton(
                    style: appSecondaryPillButtonStyle(),
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(context).maybePop(false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: appPrimaryPillButtonStyle(),
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
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
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

class _EditProjectMemberSheet extends StatefulWidget {
  final String memberId;

  const _EditProjectMemberSheet({required this.memberId});

  @override
  State<_EditProjectMemberSheet> createState() => _EditProjectMemberSheetState();
}

class _EditProjectMemberSheetState extends State<_EditProjectMemberSheet> {
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

    return _MemberSheetScaffold(
      title: 'Editar membro',
      subtitle: 'Ajuste permissões e funções musicais atribuídas ao integrante.',
      icon: Icons.manage_accounts_rounded,
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator()),
            )
          : member == null
          ? Column(
              children: [
                const _InlineErrorMessage(
                  message: 'Não foi possível abrir este membro.',
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _loadMember,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                if (state.skills.isEmpty)
                  const _InlineHint(
                    message: 'Nenhuma função musical cadastrada para este projeto.',
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
                            selectedColor: const Color(0xFFDCEAFE),
                            checkmarkColor: const Color(0xFF0166FF),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _selectedSkillIds.contains(skill.id)
                                  ? const Color(0xFF0166FF)
                                  : const Color(0xFF475569),
                            ),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: appSecondaryPillButtonStyle(),
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.of(context).maybePop(false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: appPrimaryPillButtonStyle(),
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
                                } else if (cubit.state.actionErrorMessage != null) {
                                  AppFeedback.showError(
                                    cubit.state.actionErrorMessage!,
                                  );
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Salvar alterações'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _MemberSheetScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _MemberSheetScaffold({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: title,
      subtitle: subtitle,
      icon: icon,
      child: child,
    );
  }
}

class _FormSectionLabel extends StatelessWidget {
  final String label;

  const _FormSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

class _MemberHeader extends StatelessWidget {
  final ProjectMemberEntity member;

  const _MemberHeader({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _MemberAvatar(imageUrl: member.profileImage, fullName: member.fullName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${member.username}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF2563EB),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permissão no projeto',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
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
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fullName;

  const _MemberAvatar({required this.imageUrl, required this.fullName});

  @override
  Widget build(BuildContext context) {
    if (UrlUtils.isValidNetworkUrl(imageUrl)) {
      return CircleAvatar(
        radius: 26,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }

    final initial = fullName.trim().isEmpty ? '?' : fullName.trim()[0];
    return CircleAvatar(
      radius: 26,
      backgroundColor: const Color(0xFFEFF6FF),
      child: Text(
        initial.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF0166FF),
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final ProjectMemberRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (role) {
      ProjectMemberRole.owner => (
        const Color(0xFFFFF7ED),
        const Color(0xFFC2410C),
      ),
      ProjectMemberRole.admin => (
        const Color(0xFFEFF6FF),
        const Color(0xFF1D4ED8),
      ),
      ProjectMemberRole.member => (
        const Color(0xFFF1F5F9),
        const Color(0xFF475569),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: muted ? const Color(0xFF94A3B8) : const Color(0xFF334155),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _LockedOwnerBanner extends StatelessWidget {
  const _LockedOwnerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_rounded, size: 18, color: Color(0xFFC2410C)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Owner bloqueado para alteração de privilégio administrativo.',
              style: TextStyle(
                color: Color(0xFF9A3412),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF991B1B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InlineHint extends StatelessWidget {
  final String message;

  const _InlineHint({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
