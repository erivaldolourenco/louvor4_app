import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/project_skills_repository.dart';
import '../../domain/entities/project_role.dart';
import '../../domain/entities/project_skill_entity.dart';
import 'project_skills_state.dart';

class ProjectSkillsCubit extends Cubit<ProjectSkillsState> {
  final ProjectSkillsRepository _repository;
  final String projectId;
  final ProjectRole? _initialRole;
  final String? _initialProjectName;

  ProjectSkillsCubit({
    required ProjectSkillsRepository repository,
    required this.projectId,
    ProjectRole? initialRole,
    String? initialProjectName,
  }) : _repository = repository,
       _initialRole = initialRole,
       _initialProjectName = initialProjectName,
       super(
         ProjectSkillsState(
           role: initialRole,
           projectName: initialProjectName,
         ),
       );

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(
        state.copyWith(
          status: ProjectSkillsStatus.loading,
          clearErrorMessage: true,
          clearActionErrorMessage: true,
        ),
      );
    }

    try {
      final roleFuture = state.role != null
          ? Future.value(state.role!)
          : (_initialRole != null
                ? Future.value(_initialRole)
                : _repository.getMemberRole(projectId));
      final projectNameFuture = state.projectName != null
          ? Future.value(state.projectName)
          : (_initialProjectName != null
                ? Future.value(_initialProjectName)
                : _repository.getProjectContext(projectId).then(
                    (project) => project.name,
                  ));

      final results = await Future.wait([
        roleFuture,
        projectNameFuture,
        _repository.getProjectSkills(projectId),
      ]);

      emit(
        state.copyWith(
          status: ProjectSkillsStatus.success,
          role: results[0] as ProjectRole,
          projectName: results[1] as String?,
          skills: _sortSkills(results[2] as List<ProjectSkillEntity>),
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ProjectSkillsStatus.failure,
          errorMessage: _extractMessage(e),
        ),
      );
    }
  }

  Future<bool> createSkill(String name) async {
    if (!state.canManageSkills) {
      emit(
        state.copyWith(
          actionErrorMessage:
              'Apenas administradores podem adicionar funções.',
        ),
      );
      return false;
    }

    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      emit(
        state.copyWith(actionErrorMessage: 'Informe o nome da função.'),
      );
      return false;
    }

    emit(
      state.copyWith(
        submission: ProjectSkillsSubmission.creating,
        clearActionErrorMessage: true,
      ),
    );

    try {
      await _repository.addProjectSkill(projectId, normalizedName);
      await _reloadSkills();
      emit(
        state.copyWith(
          submission: ProjectSkillsSubmission.idle,
          clearActionErrorMessage: true,
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          submission: ProjectSkillsSubmission.idle,
          actionErrorMessage: _extractMessage(e),
        ),
      );
      return false;
    }
  }

  Future<bool> deleteSkill(ProjectSkillEntity skill) async {
    if (!state.canManageSkills) {
      emit(
        state.copyWith(
          actionErrorMessage:
              'Apenas administradores podem excluir funções.',
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        submission: ProjectSkillsSubmission.deleting,
        activeSkillId: skill.id,
        clearActionErrorMessage: true,
      ),
    );

    try {
      await _repository.deleteProjectSkill(skill.id);
      emit(
        state.copyWith(
          submission: ProjectSkillsSubmission.idle,
          clearActiveSkillId: true,
          skills: state.skills.where((item) => item.id != skill.id).toList(),
          clearActionErrorMessage: true,
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          submission: ProjectSkillsSubmission.idle,
          clearActiveSkillId: true,
          actionErrorMessage: _extractMessage(e),
        ),
      );
      return false;
    }
  }

  Future<void> _reloadSkills() async {
    final skills = await _repository.getProjectSkills(projectId);
    emit(
      state.copyWith(
        status: ProjectSkillsStatus.success,
        skills: _sortSkills(skills),
      ),
    );
  }

  List<ProjectSkillEntity> _sortSkills(List<ProjectSkillEntity> skills) {
    final sorted = [...skills];
    sorted.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return sorted;
  }

  String _extractMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
