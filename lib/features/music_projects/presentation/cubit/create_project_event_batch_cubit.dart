import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/music_projects_repository.dart';
import '../../domain/entities/create_project_event_batch_input.dart';
import 'create_project_event_batch_state.dart';

class CreateProjectEventBatchCubit extends Cubit<CreateProjectEventBatchState> {
  final MusicProjectsRepository _repository;

  CreateProjectEventBatchCubit(this._repository)
    : super(const CreateProjectEventBatchState());

  Future<bool> submit({
    required String projectId,
    required CreateProjectEventBatchInput input,
  }) async {
    emit(
      state.copyWith(
        status: CreateProjectEventBatchStatus.validating,
        clearErrorMessage: true,
      ),
    );

    emit(
      state.copyWith(
        status: CreateProjectEventBatchStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    try {
      await _repository.createProjectEventBatch(projectId, input);
      emit(
        state.copyWith(
          status: CreateProjectEventBatchStatus.success,
          clearErrorMessage: true,
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          status: CreateProjectEventBatchStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }
}
