import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/events_repository.dart';
import '../../domain/entities/update_event_input_entity.dart';
import 'edit_event_state.dart';

class EditEventCubit extends Cubit<EditEventState> {
  final EventsRepository _repository;

  EditEventCubit(this._repository) : super(const EditEventState());

  void startEditing() {
    emit(
      state.copyWith(status: EditEventStatus.editing, clearErrorMessage: true),
    );
  }

  Future<bool> submit({
    required String eventId,
    required UpdateEventInputEntity input,
  }) async {
    emit(
      state.copyWith(
        status: EditEventStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    try {
      await _repository.updateEvent(eventId, input);
      emit(
        state.copyWith(
          status: EditEventStatus.success,
          clearErrorMessage: true,
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          status: EditEventStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }
}
