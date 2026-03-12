import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/music_projects_repository.dart';
import '../../domain/entities/music_project_entity.dart';
import '../../domain/entities/update_music_project_input.dart';
import 'edit_music_project_state.dart';

class EditMusicProjectCubit extends Cubit<EditMusicProjectState> {
  final MusicProjectsRepository _repository;

  EditMusicProjectCubit(this._repository)
    : super(const EditMusicProjectState());

  Future<void> loadProject(String projectId) async {
    emit(
      state.copyWith(
        status: EditMusicProjectStatus.loadingProject,
        clearErrorMessage: true,
      ),
    );

    try {
      final project = await _repository.getProjectById(projectId);
      emit(
        state.copyWith(
          status: EditMusicProjectStatus.editing,
          project: project,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EditMusicProjectStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<MusicProjectEntity?> submit(UpdateMusicProjectInput input) async {
    emit(
      state.copyWith(
        status: EditMusicProjectStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    try {
      final project = await _repository.updateProject(input.id, input);
      emit(
        state.copyWith(
          status: EditMusicProjectStatus.editing,
          project: project,
          clearErrorMessage: true,
        ),
      );
      return project;
    } catch (e) {
      emit(
        state.copyWith(
          status: EditMusicProjectStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return null;
    }
  }

  Future<MusicProjectEntity?> submitWithOptionalImage({
    required UpdateMusicProjectInput input,
    String? imagePath,
    String? imageName,
  }) async {
    final updatedProject = await submit(input);
    if (updatedProject == null) return null;

    if (imagePath == null || imageName == null) {
      emit(
        state.copyWith(
          status: EditMusicProjectStatus.success,
          project: updatedProject,
          clearErrorMessage: true,
        ),
      );
      return updatedProject;
    }

    emit(
      state.copyWith(
        status: EditMusicProjectStatus.uploadingImage,
        clearErrorMessage: true,
      ),
    );

    try {
      await _repository.updateProjectProfileImage(
        projectId: input.id,
        filePath: imagePath,
        fileName: imageName,
      );
      final refreshed = await _repository.getProjectById(input.id);
      emit(
        state.copyWith(
          status: EditMusicProjectStatus.success,
          project: refreshed,
          clearErrorMessage: true,
        ),
      );
      return refreshed;
    } catch (e) {
      emit(
        state.copyWith(
          status: EditMusicProjectStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return null;
    }
  }
}
