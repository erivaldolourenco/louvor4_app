import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/events_local_cache.dart';
import '../../data/events_repository.dart';
import 'events_state.dart';

class EventsCubit extends Cubit<EventsState> {
  final EventsRepository _repo;
  final EventsLocalCache _cache;

  EventsCubit(this._repo, {EventsLocalCache? cache})
    : _cache = cache ?? EventsLocalCache(),
      super(const EventsState());

  Future<void> load() async {
    if (state.events.isEmpty) {
      final cached = await _cache.readUpcomingEvents();
      if (cached.isNotEmpty) {
        emit(
          state.copyWith(
            status: EventsStatus.success,
            events: cached,
            isOffline: true,
          ),
        );
      } else {
        emit(state.copyWith(status: EventsStatus.loading));
      }
    }

    try {
      final events = await _repo.getEvents();
      emit(
        state.copyWith(
          status: EventsStatus.success,
          events: events,
          isOffline: false,
        ),
      );
      unawaited(_cache.saveUpcomingEvents(events));
    } catch (e) {
      if (state.events.isNotEmpty) {
        emit(state.copyWith(isOffline: true));
      } else {
        emit(
          state.copyWith(
            status: EventsStatus.failure,
            errorMessage: 'Não foi possível carregar os eventos.',
          ),
        );
      }
    }
  }

  Future<void> loadPastEvents({bool force = false}) async {
    if (state.pastEventsStatus == PastEventsStatus.loading) return;
    // Já carregado com sucesso nesta sessão do cubit — evita refazer a
    // busca de rede toda vez que a aba "Passados" é reativada (a tela que
    // a hospeda é recriada a cada navegação, então não dá pra confiar
    // numa flag local de "já carreguei").
    if (!force && state.pastEventsStatus == PastEventsStatus.success) return;
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
