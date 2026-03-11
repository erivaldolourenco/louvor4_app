import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/music_projects_repository.dart';
import '../../domain/entities/create_project_event_input.dart';
import 'create_project_event_state.dart';

class CreateProjectEventCubit extends Cubit<CreateProjectEventState> {
  final MusicProjectsRepository _repository;

  CreateProjectEventCubit(this._repository)
    : super(const CreateProjectEventState());

  Future<bool> submit({
    required String projectId,
    required CreateProjectEventInput input,
  }) async {
    emit(
      state.copyWith(
        status: CreateProjectEventStatus.validating,
        clearErrorMessage: true,
      ),
    );

    emit(
      state.copyWith(
        status: CreateProjectEventStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    try {
      await _repository.createProjectEvent(projectId, input);
      emit(
        state.copyWith(
          status: CreateProjectEventStatus.success,
          clearErrorMessage: true,
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          status: CreateProjectEventStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }
}
