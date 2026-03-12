import 'package:equatable/equatable.dart';

import '../../domain/entities/music_project_entity.dart';

enum EditMusicProjectStatus {
  initial,
  loadingProject,
  editing,
  submitting,
  uploadingImage,
  success,
  error,
}

class EditMusicProjectState extends Equatable {
  final EditMusicProjectStatus status;
  final MusicProjectEntity? project;
  final String? errorMessage;

  const EditMusicProjectState({
    this.status = EditMusicProjectStatus.initial,
    this.project,
    this.errorMessage,
  });

  bool get isLoadingProject => status == EditMusicProjectStatus.loadingProject;
  bool get isSubmitting =>
      status == EditMusicProjectStatus.submitting ||
      status == EditMusicProjectStatus.uploadingImage;

  EditMusicProjectState copyWith({
    EditMusicProjectStatus? status,
    MusicProjectEntity? project,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return EditMusicProjectState(
      status: status ?? this.status,
      project: project ?? this.project,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, project, errorMessage];
}
