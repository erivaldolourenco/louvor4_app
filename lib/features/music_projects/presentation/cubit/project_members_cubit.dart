import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/music_projects_repository.dart';
import '../../domain/entities/add_project_member_input.dart';
import '../../domain/entities/project_member_entity.dart';
import '../../domain/entities/project_member_role.dart';
import '../../domain/entities/project_skill_entity.dart';
import '../../domain/entities/update_project_member_input.dart';
import 'project_members_state.dart';

class ProjectMembersCubit extends Cubit<ProjectMembersState> {
  final MusicProjectsRepository _repository;
  final String projectId;
  final bool canManageMembers;
  final String? currentUserId;

  ProjectMembersCubit({
    required MusicProjectsRepository repository,
    required this.projectId,
    required this.canManageMembers,
    this.currentUserId,
  }) : _repository = repository,
       super(const ProjectMembersState());

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(
        state.copyWith(
          status: ProjectMembersStatus.loading,
          clearErrorMessage: true,
          clearActionErrorMessage: true,
        ),
      );
    }

    try {
      final members = await _repository.getProjectMembers(projectId);
      emit(
        state.copyWith(
          status: ProjectMembersStatus.success,
          members: _sortMembers(members),
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ProjectMembersStatus.failure,
          errorMessage: _extractMessage(e),
        ),
      );
    }
  }

  Future<ProjectMemberEntity?> loadMemberDetail(String memberId) async {
    emit(
      state.copyWith(
        submission: ProjectMembersSubmission.loadingMember,
        activeMemberId: memberId,
        clearActionErrorMessage: true,
      ),
    );

    try {
      // O catálogo completo de skills do projeto só é necessário aqui, para
      // montar as opções de seleção na tela de edição — a listagem de
      // membros não precisa mais dele, pois cada membro já traz suas
      // funções musicais embutidas (id, name, iconKey).
      final results = await Future.wait([
        _repository.getProjectMember(projectId, memberId),
        _repository.getProjectSkills(projectId),
      ]);
      final member = results[0] as ProjectMemberEntity;
      final skills = results[1] as List<ProjectSkillEntity>;
      emit(
        state.copyWith(
          submission: ProjectMembersSubmission.idle,
          clearActiveMemberId: true,
          clearActionErrorMessage: true,
          skills: skills,
        ),
      );
      return member;
    } catch (e) {
      emit(
        state.copyWith(
          submission: ProjectMembersSubmission.idle,
          clearActiveMemberId: true,
          actionErrorMessage: _extractMessage(e),
        ),
      );
      return null;
    }
  }

  Future<bool> addMember(String username) async {
    if (!canManageMembers) {
      emit(
        state.copyWith(
          actionErrorMessage:
              'Apenas administradores podem adicionar membros.',
        ),
      );
      return false;
    }

    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) {
      emit(
        state.copyWith(actionErrorMessage: 'Informe o username do membro.'),
      );
      return false;
    }

    emit(
      state.copyWith(
        submission: ProjectMembersSubmission.adding,
        clearActionErrorMessage: true,
      ),
    );

    try {
      await _repository.addProjectMember(
        projectId,
        AddProjectMemberInput(username: normalizedUsername),
      );
      await _refreshDataAfterMutation();
      emit(
        state.copyWith(
          submission: ProjectMembersSubmission.idle,
          clearActionErrorMessage: true,
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          submission: ProjectMembersSubmission.idle,
          actionErrorMessage: _extractMessage(e),
        ),
      );
      return false;
    }
  }

  Future<bool> updateMember({
    required ProjectMemberEntity member,
    required ProjectMemberRole projectRole,
    required List<String> skillIds,
  }) async {
    if (!canManageMembers) {
      emit(
        state.copyWith(
          actionErrorMessage: 'Apenas administradores podem editar membros.',
        ),
      );
      return false;
    }

    final effectiveRole = member.isOwner ? member.projectRole : projectRole;

    emit(
      state.copyWith(
        submission: ProjectMembersSubmission.updating,
        activeMemberId: member.id,
        clearActionErrorMessage: true,
      ),
    );

    try {
      await _repository.updateProjectMember(
        projectId,
        member.id,
        UpdateProjectMemberInput(
          projectRole: effectiveRole,
          skillIds: skillIds,
        ),
      );
      await _refreshDataAfterMutation();
      emit(
        state.copyWith(
          submission: ProjectMembersSubmission.idle,
          clearActiveMemberId: true,
          clearActionErrorMessage: true,
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          submission: ProjectMembersSubmission.idle,
          clearActiveMemberId: true,
          actionErrorMessage: _extractMessage(e),
        ),
      );
      return false;
    }
  }

  Future<bool> removeMember(ProjectMemberEntity member) async {
    if (!canManageMembers) {
      emit(
        state.copyWith(
          actionErrorMessage: 'Apenas administradores podem remover membros.',
        ),
      );
      return false;
    }

    if (member.isOwner) {
      emit(
        state.copyWith(
          actionErrorMessage: 'O owner do projeto não pode ser removido.',
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        submission: ProjectMembersSubmission.removing,
        activeMemberId: member.id,
        clearActionErrorMessage: true,
      ),
    );

    try {
      await _repository.removeProjectMember(projectId, member.id);
      await _refreshDataAfterMutation();
      emit(
        state.copyWith(
          submission: ProjectMembersSubmission.idle,
          clearActiveMemberId: true,
          clearActionErrorMessage: true,
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          submission: ProjectMembersSubmission.idle,
          clearActiveMemberId: true,
          actionErrorMessage: _extractMessage(e),
        ),
      );
      return false;
    }
  }

  bool isCurrentUser(ProjectMemberEntity member) =>
      currentUserId != null && member.userId == currentUserId;

  bool canEditMember(ProjectMemberEntity member) => canManageMembers;

  bool canRemoveMember(ProjectMemberEntity member) =>
      canManageMembers && !member.isOwner && !isCurrentUser(member);

  bool canLeaveProject(ProjectMemberEntity member) =>
      isCurrentUser(member) && !member.isOwner;

  bool canChangeAdministrativeAccess(ProjectMemberEntity member) =>
      canManageMembers && !member.isOwner;

  Future<bool> leaveProject(ProjectMemberEntity member) async {
    emit(
      state.copyWith(
        submission: ProjectMembersSubmission.leaving,
        activeMemberId: member.id,
        clearActionErrorMessage: true,
      ),
    );

    try {
      await _repository.leaveProject(projectId);
      emit(
        state.copyWith(
          submission: ProjectMembersSubmission.idle,
          clearActiveMemberId: true,
          clearActionErrorMessage: true,
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          submission: ProjectMembersSubmission.idle,
          clearActiveMemberId: true,
          actionErrorMessage: _extractMessage(e),
        ),
      );
      return false;
    }
  }

  Future<void> _refreshDataAfterMutation() async {
    final members = await _repository.getProjectMembers(projectId);
    emit(
      state.copyWith(
        status: ProjectMembersStatus.success,
        members: _sortMembers(members),
      ),
    );
  }

  List<ProjectMemberEntity> _sortMembers(List<ProjectMemberEntity> members) {
    final sorted = [...members];
    sorted.sort((a, b) {
      final roleCompare = _rolePriority(a.projectRole).compareTo(
        _rolePriority(b.projectRole),
      );
      if (roleCompare != 0) return roleCompare;
      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });
    return sorted;
  }

  int _rolePriority(ProjectMemberRole role) {
    switch (role) {
      case ProjectMemberRole.owner:
        return 0;
      case ProjectMemberRole.admin:
        return 1;
      case ProjectMemberRole.member:
        return 2;
    }
  }

  String _extractMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
