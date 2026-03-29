import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/music_projects_repository.dart';
import '../../domain/entities/create_music_project_input.dart';
import '../../domain/entities/music_project_entity.dart';
import '../../domain/exceptions/music_project_request_exception.dart';
import 'create_music_project_state.dart';

class CreateMusicProjectCubit extends Cubit<CreateMusicProjectState> {
  final MusicProjectsRepository _repository;

  CreateMusicProjectCubit(this._repository)
    : super(const CreateMusicProjectState());

  Future<MusicProjectEntity?> submit(CreateMusicProjectInput input) async {
    emit(
      state.copyWith(
        status: CreateMusicProjectStatus.submitting,
        clearError: true,
      ),
    );

    try {
      final project = await _repository.createProject(input);
      emit(
        state.copyWith(
          status: CreateMusicProjectStatus.success,
          createdProject: project,
          clearError: true,
        ),
      );
      return project;
    } on MusicProjectRequestException catch (e) {
      emit(
        state.copyWith(
          status: CreateMusicProjectStatus.error,
          errorMessage: e.message,
          errorStatusCode: e.statusCode,
        ),
      );
      return null;
    } catch (_) {
      emit(
        state.copyWith(
          status: CreateMusicProjectStatus.error,
          errorMessage: 'Não foi possível criar o projeto.',
          errorStatusCode: null,
        ),
      );
      return null;
    }
  }
}
