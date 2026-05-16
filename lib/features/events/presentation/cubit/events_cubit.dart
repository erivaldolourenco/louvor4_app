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
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          errorMessage: 'Não foi possível carregar os eventos.',
        ),
      );
    }
  }

  Future<void> loadPastEvents() async {
    if (state.pastEventsStatus == PastEventsStatus.loading) return;
    emit(
      state.copyWith(
        pastEventsStatus: PastEventsStatus.loading,
        pastEventsPage: 0,
        pastEventsHasMore: true,
        pastEvents: [],
      ),
    );
    try {
      final result = await _repo.getPastEvents(0);
      emit(
        state.copyWith(
          pastEventsStatus: PastEventsStatus.success,
          pastEvents: result.events,
          pastEventsHasMore: result.hasMore,
        ),
      );
    } catch (_) {
      emit(state.copyWith(pastEventsStatus: PastEventsStatus.failure));
    }
  }

  Future<void> loadMorePastEvents() async {
    if (!state.pastEventsHasMore ||
        state.pastEventsStatus == PastEventsStatus.loading ||
        state.pastEventsStatus == PastEventsStatus.loadingMore) {
      return;
    }
    emit(state.copyWith(pastEventsStatus: PastEventsStatus.loadingMore));
    try {
      final nextPage = state.pastEventsPage + 1;
      final result = await _repo.getPastEvents(nextPage);
      emit(
        state.copyWith(
          pastEventsStatus: PastEventsStatus.success,
          pastEvents: [...state.pastEvents, ...result.events],
          pastEventsPage: nextPage,
          pastEventsHasMore: result.hasMore,
        ),
      );
    } catch (_) {
      emit(state.copyWith(pastEventsStatus: PastEventsStatus.failure));
    }
  }
}
