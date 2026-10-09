import 'package:equatable/equatable.dart';

import '../../domain/entities/responsibility_entity.dart';

enum ProjectBoardStatus { initial, loading, success, failure }

class ProjectBoardState extends Equatable {
  final ProjectBoardStatus status;
  final List<ResponsibilityEntity> responsibilities;
  final String? errorMessage;
  final bool isSaving;
  final String? actionErrorMessage;
  final String? deletingId;

  const ProjectBoardState({
    this.status = ProjectBoardStatus.initial,
    this.responsibilities = const [],
    this.errorMessage,
    this.isSaving = false,
    this.actionErrorMessage,
    this.deletingId,
  });

  bool get isInitialLoading =>
      status == ProjectBoardStatus.loading && responsibilities.isEmpty;

  bool get isEmpty =>
      status == ProjectBoardStatus.success && responsibilities.isEmpty;

  ProjectBoardState copyWith({
    ProjectBoardStatus? status,
    List<ResponsibilityEntity>? responsibilities,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isSaving,
    String? actionErrorMessage,
    bool clearActionErrorMessage = false,
    String? deletingId,
    bool clearDeletingId = false,
  }) {
    return ProjectBoardState(
      status: status ?? this.status,
      responsibilities: responsibilities ?? this.responsibilities,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      isSaving: isSaving ?? this.isSaving,
      actionErrorMessage: clearActionErrorMessage
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
      deletingId: clearDeletingId ? null : (deletingId ?? this.deletingId),
    );
  }

  @override
  List<Object?> get props => [
    status,
    responsibilities,
    errorMessage,
    isSaving,
    actionErrorMessage,
    deletingId,
  ];
}
