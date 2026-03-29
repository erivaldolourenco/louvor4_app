import 'package:equatable/equatable.dart';

import '../../domain/entities/music_project_entity.dart';

enum CreateMusicProjectStatus { initial, submitting, success, error }

class CreateMusicProjectState extends Equatable {
  final CreateMusicProjectStatus status;
  final MusicProjectEntity? createdProject;
  final String? errorMessage;
  final int? errorStatusCode;

  const CreateMusicProjectState({
    this.status = CreateMusicProjectStatus.initial,
    this.createdProject,
    this.errorMessage,
    this.errorStatusCode,
  });

  bool get isSubmitting => status == CreateMusicProjectStatus.submitting;

  CreateMusicProjectState copyWith({
    CreateMusicProjectStatus? status,
    MusicProjectEntity? createdProject,
    String? errorMessage,
    int? errorStatusCode,
    bool clearError = false,
  }) {
    return CreateMusicProjectState(
      status: status ?? this.status,
      createdProject: createdProject ?? this.createdProject,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorStatusCode: clearError
          ? null
          : (errorStatusCode ?? this.errorStatusCode),
    );
  }

  @override
  List<Object?> get props => [
    status,
    createdProject,
    errorMessage,
    errorStatusCode,
  ];
}
