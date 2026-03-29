import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/music_projects_repository.dart';
import '../../domain/entities/music_project_entity.dart';
import 'project_state.dart';

class ProjectCubit extends Cubit<ProjectState> {
  final MusicProjectsRepository _repository;

  ProjectCubit(this._repository) : super(const ProjectState());

  Future<void> loadProjects({bool force = false}) async {
    if (!force &&
        !state.needsRefresh &&
        state.projects.isNotEmpty &&
        state.status == ProjectStatus.success) {
      return;
    }

    emit(state.copyWith(status: ProjectStatus.loading, errorMessage: null));

    try {
      final projects = await _repository.getUserMusicProjects();
      MusicProjectEntity? active = state.activeProject;

      if (active != null) {
        final stillExists = projects.any((p) => p.id == active!.id);
        if (!stillExists) active = null;
      }

      emit(
        state.copyWith(
          status: ProjectStatus.success,
          projects: projects,
          activeProject: active,
          errorMessage: null,
          needsRefresh: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ProjectStatus.failure,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  void selectProject(MusicProjectEntity project) {
    emit(state.copyWith(activeProject: project));
  }

  void upsertProject(MusicProjectEntity project) {
    final projects = List<MusicProjectEntity>.from(state.projects);
    final index = projects.indexWhere((item) => item.id == project.id);

    if (index >= 0) {
      projects[index] = project;
    } else {
      projects.insert(0, project);
    }

    emit(
      state.copyWith(
        status: ProjectStatus.success,
        projects: projects,
        activeProject: project,
        errorMessage: null,
      ),
    );
  }

  void invalidateProjects() {
    emit(state.copyWith(needsRefresh: true));
  }

  void clearActiveProject() {
    emit(state.copyWith(clearActiveProject: true));
  }
}
