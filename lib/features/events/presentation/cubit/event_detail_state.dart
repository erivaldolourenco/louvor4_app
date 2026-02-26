import 'package:equatable/equatable.dart';

import '../../domain/entities/event_detail_entity.dart';
import '../../domain/entities/event_participant_entity.dart';
import '../../domain/entities/event_song_entity.dart';

enum EventDetailStatus { initial, loading, success, failure }

class EventDetailState extends Equatable {
  final EventDetailStatus status;
  final EventDetailEntity? event;
  final List<EventParticipant> participants;
  final List<EventSong> songs;
  final String? errorMessage;
  final Map<String, String> skillsMap;

  const EventDetailState({
    this.status = EventDetailStatus.initial,
    this.event,
    this.participants = const [],
    this.songs = const [],
    this.errorMessage,
    this.skillsMap = const {},
  });

  EventDetailState copyWith({
    EventDetailStatus? status,
    EventDetailEntity? event,
    List<EventParticipant>? participants,
    List<EventSong>? songs,
    String? errorMessage,
    Map<String, String>? skillsMap,
  }) {
    return EventDetailState(
      status: status ?? this.status,
      event: event ?? this.event,
      participants: participants ?? this.participants,
      songs: songs ?? this.songs,
      errorMessage: errorMessage ?? this.errorMessage,
      skillsMap: skillsMap ?? this.skillsMap,
    );
  }

  @override
  List<Object?> get props => [status, event, participants, songs, errorMessage];
}
