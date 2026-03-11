import 'package:equatable/equatable.dart';

import '../../domain/entities/project_member_entity.dart';
import '../../domain/entities/project_skill_entity.dart';

enum ProjectMembersStatus { initial, loading, success, failure }

enum ProjectMembersSubmission { idle, loadingMember, adding, updating, removing }

class ProjectMembersState extends Equatable {
  final ProjectMembersStatus status;
  final List<ProjectMemberEntity> members;
  final List<ProjectSkillEntity> skills;
  final String? errorMessage;
  final ProjectMembersSubmission submission;
  final String? activeMemberId;
  final String? actionErrorMessage;

  const ProjectMembersState({
    this.status = ProjectMembersStatus.initial,
    this.members = const [],
    this.skills = const [],
    this.errorMessage,
    this.submission = ProjectMembersSubmission.idle,
    this.activeMemberId,
    this.actionErrorMessage,
  });

  bool get isLoading =>
      status == ProjectMembersStatus.loading && members.isEmpty && skills.isEmpty;

  bool isBusy(String? memberId) {
    if (submission == ProjectMembersSubmission.idle) return false;
    if (submission == ProjectMembersSubmission.adding) return true;
    return activeMemberId == memberId;
  }

  ProjectMembersState copyWith({
    ProjectMembersStatus? status,
    List<ProjectMemberEntity>? members,
    List<ProjectSkillEntity>? skills,
    String? errorMessage,
    bool clearErrorMessage = false,
    ProjectMembersSubmission? submission,
    String? activeMemberId,
    bool clearActiveMemberId = false,
    String? actionErrorMessage,
    bool clearActionErrorMessage = false,
  }) {
    return ProjectMembersState(
      status: status ?? this.status,
      members: members ?? this.members,
      skills: skills ?? this.skills,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      submission: submission ?? this.submission,
      activeMemberId: clearActiveMemberId
          ? null
          : (activeMemberId ?? this.activeMemberId),
      actionErrorMessage: clearActionErrorMessage
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    members,
    skills,
    errorMessage,
    submission,
    activeMemberId,
    actionErrorMessage,
  ];
}
