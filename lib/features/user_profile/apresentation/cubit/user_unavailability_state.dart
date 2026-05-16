import 'package:equatable/equatable.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/music_project_entity.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/user_unavailability_entity.dart';

enum UserUnavailabilityStatus { initial, loading, success, empty, error }

enum UserUnavailabilitySubmission { idle, creating, deleting }

class UserUnavailabilityState extends Equatable {
  final UserUnavailabilityStatus status;
  final UserUnavailabilitySubmission submission;
  final List<UserUnavailabilityEntity> items;
  final List<MusicProjectEntity> projects;
  final String? errorMessage;
  final String? actionErrorMessage;
  final String? activeUnavailabilityId;

  const UserUnavailabilityState({
    this.status = UserUnavailabilityStatus.initial,
    this.submission = UserUnavailabilitySubmission.idle,
    this.items = const [],
    this.projects = const [],
    this.errorMessage,
    this.actionErrorMessage,
    this.activeUnavailabilityId,
  });

  bool get isInitialLoading =>
      status == UserUnavailabilityStatus.loading && items.isEmpty;

  bool get isCreating => submission == UserUnavailabilitySubmission.creating;

  bool isDeleting(String id) {
    return submission == UserUnavailabilitySubmission.deleting &&
        activeUnavailabilityId == id;
  }

  UserUnavailabilityState copyWith({
    UserUnavailabilityStatus? status,
    UserUnavailabilitySubmission? submission,
    List<UserUnavailabilityEntity>? items,
    List<MusicProjectEntity>? projects,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionErrorMessage,
    bool clearActionErrorMessage = false,
    String? activeUnavailabilityId,
    bool clearActiveUnavailabilityId = false,
  }) {
    return UserUnavailabilityState(
      status: status ?? this.status,
      submission: submission ?? this.submission,
      items: items ?? this.items,
      projects: projects ?? this.projects,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      actionErrorMessage: clearActionErrorMessage
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
      activeUnavailabilityId: clearActiveUnavailabilityId
          ? null
          : (activeUnavailabilityId ?? this.activeUnavailabilityId),
    );
  }

  @override
  List<Object?> get props => [
    status,
    submission,
    items,
    projects,
    errorMessage,
    actionErrorMessage,
    activeUnavailabilityId,
  ];
}
