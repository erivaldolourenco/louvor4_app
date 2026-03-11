import 'package:equatable/equatable.dart';

import '../../domain/entities/project_role.dart';
import '../../domain/entities/project_skill_entity.dart';

enum ProjectSkillsStatus { initial, loading, success, failure }

enum ProjectSkillsSubmission { idle, creating, deleting }

class ProjectSkillsState extends Equatable {
  final ProjectSkillsStatus status;
  final ProjectSkillsSubmission submission;
  final List<ProjectSkillEntity> skills;
  final ProjectRole? role;
  final String? projectName;
  final String? errorMessage;
  final String? actionErrorMessage;
  final String? activeSkillId;

  const ProjectSkillsState({
    this.status = ProjectSkillsStatus.initial,
    this.submission = ProjectSkillsSubmission.idle,
    this.skills = const [],
    this.role,
    this.projectName,
    this.errorMessage,
    this.actionErrorMessage,
    this.activeSkillId,
  });

  bool get isInitialLoading =>
      status == ProjectSkillsStatus.loading && skills.isEmpty;

  bool get isEmpty =>
      status == ProjectSkillsStatus.success && skills.isEmpty;

  bool get canManageSkills => role?.canManageSkills == true;

  bool isDeletingSkill(String skillId) {
    return submission == ProjectSkillsSubmission.deleting &&
        activeSkillId == skillId;
  }

  ProjectSkillsState copyWith({
    ProjectSkillsStatus? status,
    ProjectSkillsSubmission? submission,
    List<ProjectSkillEntity>? skills,
    ProjectRole? role,
    String? projectName,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionErrorMessage,
    bool clearActionErrorMessage = false,
    String? activeSkillId,
    bool clearActiveSkillId = false,
  }) {
    return ProjectSkillsState(
      status: status ?? this.status,
      submission: submission ?? this.submission,
      skills: skills ?? this.skills,
      role: role ?? this.role,
      projectName: projectName ?? this.projectName,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      actionErrorMessage: clearActionErrorMessage
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
      activeSkillId: clearActiveSkillId
          ? null
          : (activeSkillId ?? this.activeSkillId),
    );
  }

  @override
  List<Object?> get props => [
    status,
    submission,
    skills,
    role,
    projectName,
    errorMessage,
    actionErrorMessage,
    activeSkillId,
  ];
}
