import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/events_repository.dart';
import 'event_detail_state.dart';

class EventDetailCubit extends Cubit<EventDetailState> {
  final EventsRepository _repository;

  EventDetailCubit(this._repository) : super(const EventDetailState());

  Future<void> load(String eventId) async {
    emit(state.copyWith(status: EventDetailStatus.loading));

    try {
      // Em um app real, usaríamos um Future.wait para carregar em paralelo
      final event = await _repository.getEventDetail(eventId);
      final participants = await _repository.getEventParticipants(eventId);
      final songs = await _repository.getEventSongs(eventId);

      emit(state.copyWith(
        status: EventDetailStatus.success,
        event: event,
        participants: participants,
        songs: songs,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: EventDetailStatus.failure,
        errorMessage: 'Não foi possível carregar os detalhes do evento.',
      ));
    }
  }
}
