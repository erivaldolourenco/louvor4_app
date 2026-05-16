import 'package:equatable/equatable.dart';

import '../../domain/entities/event_entity.dart';

enum EventsStatus { initial, loading, success, failure }

enum PastEventsStatus { initial, loading, loadingMore, success, failure }

class EventsState extends Equatable {
  final EventsStatus status;
  final List<EventEntity> events;
  final String? errorMessage;

  final List<EventEntity> pastEvents;
  final PastEventsStatus pastEventsStatus;
  final int pastEventsPage;
  final bool pastEventsHasMore;

  const EventsState({
    this.status = EventsStatus.initial,
    this.events = const [],
    this.errorMessage,
    this.pastEvents = const [],
    this.pastEventsStatus = PastEventsStatus.initial,
    this.pastEventsPage = 0,
    this.pastEventsHasMore = true,
  });

  EventsState copyWith({
    EventsStatus? status,
    List<EventEntity>? events,
    String? errorMessage,
    List<EventEntity>? pastEvents,
    PastEventsStatus? pastEventsStatus,
    int? pastEventsPage,
    bool? pastEventsHasMore,
  }) {
    return EventsState(
      status: status ?? this.status,
      events: events ?? this.events,
      errorMessage: errorMessage ?? this.errorMessage,
      pastEvents: pastEvents ?? this.pastEvents,
      pastEventsStatus: pastEventsStatus ?? this.pastEventsStatus,
      pastEventsPage: pastEventsPage ?? this.pastEventsPage,
      pastEventsHasMore: pastEventsHasMore ?? this.pastEventsHasMore,
    );
  }

  @override
  List<Object?> get props => [
    status,
    events,
    errorMessage,
    pastEvents,
    pastEventsStatus,
    pastEventsPage,
    pastEventsHasMore,
  ];
}
