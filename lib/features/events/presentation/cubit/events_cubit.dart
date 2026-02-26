import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/events_repository.dart';
import 'events_state.dart';

class EventsCubit extends Cubit<EventsState> {
  final EventsRepository _repo;
  EventsCubit(this._repo) : super(const EventsState());

  Future<void> load() async {
    emit(state.copyWith(status: EventsStatus.loading));
    try {
      final events = await _repo.getEvents();
      emit(state.copyWith(status: EventsStatus.success, events: events));
    } catch (e) {
      emit(state.copyWith(
        status: EventsStatus.failure,
        errorMessage: 'Não foi possível carregar os eventos.',
      ));
    }
  }
}
