import 'package:equatable/equatable.dart';

import '../../domain/entities/music_project_entity.dart';

enum ProjectStatus { initial, loading, success, failure }

class ProjectState extends Equatable {
  final ProjectStatus status;
  final List<MusicProjectEntity> projects;
  final MusicProjectEntity? activeProject;
  final String? errorMessage;

  const ProjectState({
    this.status = ProjectStatus.initial,
    this.projects = const [],
    this.activeProject,
    this.errorMessage,
  });

  ProjectState copyWith({
    ProjectStatus? status,
    List<MusicProjectEntity>? projects,
    MusicProjectEntity? activeProject,
    bool clearActiveProject = false,
    String? errorMessage,
  }) {
    return ProjectState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      activeProject: clearActiveProject
          ? null
          : (activeProject ?? this.activeProject),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, projects, activeProject, errorMessage];
}
