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
  final String? actionErrorMessage;
  final Map<String, String> skillsMap;
  final bool isProjectAdmin;
  final bool canAddSongs;
  final String? deletingSongId;

  const EventDetailState({
    this.status = EventDetailStatus.initial,
    this.event,
    this.participants = const [],
    this.songs = const [],
    this.errorMessage,
    this.actionErrorMessage,
    this.skillsMap = const {},
    this.isProjectAdmin = false,
    this.canAddSongs = false,
    this.deletingSongId,
  });

  EventDetailState copyWith({
    EventDetailStatus? status,
    EventDetailEntity? event,
    List<EventParticipant>? participants,
    List<EventSong>? songs,
    String? errorMessage,
    String? actionErrorMessage,
    bool clearActionErrorMessage = false,
    Map<String, String>? skillsMap,
    bool? isProjectAdmin,
    bool? canAddSongs,
    String? deletingSongId,
    bool clearDeletingSongId = false,
  }) {
    return EventDetailState(
      status: status ?? this.status,
      event: event ?? this.event,
      participants: participants ?? this.participants,
      songs: songs ?? this.songs,
      errorMessage: errorMessage ?? this.errorMessage,
      actionErrorMessage: clearActionErrorMessage
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
      skillsMap: skillsMap ?? this.skillsMap,
      isProjectAdmin: isProjectAdmin ?? this.isProjectAdmin,
      canAddSongs: canAddSongs ?? this.canAddSongs,
      deletingSongId: clearDeletingSongId
          ? null
          : (deletingSongId ?? this.deletingSongId),
    );
  }

  @override
  List<Object?> get props => [
    status,
    event,
    participants,
    songs,
    errorMessage,
    actionErrorMessage,
    skillsMap,
    isProjectAdmin,
    canAddSongs,
    deletingSongId,
  ];
}
