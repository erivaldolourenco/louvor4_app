import 'package:equatable/equatable.dart';

import '../../domain/entities/event_entity.dart';

enum EventsStatus { initial, loading, success, failure }

class EventsState extends Equatable {
  final EventsStatus status;
  final List<EventEntity> events;
  final String? errorMessage;

  const EventsState({
    this.status = EventsStatus.initial,
    this.events = const [],
    this.errorMessage,
  });

  EventsState copyWith({
    EventsStatus? status,
    List<EventEntity>? events,
    String? errorMessage,
  }) {
    return EventsState(
      status: status ?? this.status,
      events: events ?? this.events,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, events, errorMessage];
}
