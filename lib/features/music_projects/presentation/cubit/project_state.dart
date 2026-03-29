import 'package:equatable/equatable.dart';

import '../../domain/entities/music_project_entity.dart';

enum ProjectStatus { initial, loading, success, failure }

class ProjectState extends Equatable {
  final ProjectStatus status;
  final List<MusicProjectEntity> projects;
  final MusicProjectEntity? activeProject;
  final String? errorMessage;
  final bool needsRefresh;

  const ProjectState({
    this.status = ProjectStatus.initial,
    this.projects = const [],
    this.activeProject,
    this.errorMessage,
    this.needsRefresh = false,
  });

  ProjectState copyWith({
    ProjectStatus? status,
    List<MusicProjectEntity>? projects,
    MusicProjectEntity? activeProject,
    bool clearActiveProject = false,
    String? errorMessage,
    bool? needsRefresh,
  }) {
    return ProjectState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      activeProject: clearActiveProject
          ? null
          : (activeProject ?? this.activeProject),
      errorMessage: errorMessage,
      needsRefresh: needsRefresh ?? this.needsRefresh,
    );
  }

  @override
  List<Object?> get props => [
    status,
    projects,
    activeProject,
    errorMessage,
    needsRefresh,
  ];
}
