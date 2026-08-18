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
  final int? errorStatusCode;
  final String? actionErrorMessage;
  final Map<String, String> skillsMap;
  final bool isProjectAdmin;
  final bool canAddSongs;
  final bool canRemoveSongs;
  final bool canEditChordSheet;
  final bool canEditEvent;
  final bool canManageParticipants;
  final String? currentUserId;
  final String? deletingSongId;
  final bool participantsLoadFailed;
  final bool songsLoadFailed;

  const EventDetailState({
    this.status = EventDetailStatus.initial,
    this.event,
    this.participants = const [],
    this.songs = const [],
    this.errorMessage,
    this.errorStatusCode,
    this.actionErrorMessage,
    this.skillsMap = const {},
    this.isProjectAdmin = false,
    this.canAddSongs = false,
    this.canRemoveSongs = false,
    this.canEditChordSheet = false,
    this.canEditEvent = false,
    this.canManageParticipants = false,
    this.currentUserId,
    this.deletingSongId,
    this.participantsLoadFailed = false,
    this.songsLoadFailed = false,
  });

  EventDetailState copyWith({
    EventDetailStatus? status,
    EventDetailEntity? event,
    List<EventParticipant>? participants,
    List<EventSong>? songs,
    String? errorMessage,
    int? errorStatusCode,
    bool clearErrorStatusCode = false,
    String? actionErrorMessage,
    bool clearActionErrorMessage = false,
    Map<String, String>? skillsMap,
    bool? isProjectAdmin,
    bool? canAddSongs,
    bool? canRemoveSongs,
    bool? canEditChordSheet,
    bool? canEditEvent,
    bool? canManageParticipants,
    String? currentUserId,
    String? deletingSongId,
    bool clearDeletingSongId = false,
    bool? participantsLoadFailed,
    bool? songsLoadFailed,
  }) {
    return EventDetailState(
      status: status ?? this.status,
      event: event ?? this.event,
      participants: participants ?? this.participants,
      songs: songs ?? this.songs,
      errorMessage: errorMessage ?? this.errorMessage,
      errorStatusCode: clearErrorStatusCode
          ? null
          : (errorStatusCode ?? this.errorStatusCode),
      actionErrorMessage: clearActionErrorMessage
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
      skillsMap: skillsMap ?? this.skillsMap,
      isProjectAdmin: isProjectAdmin ?? this.isProjectAdmin,
      canAddSongs: canAddSongs ?? this.canAddSongs,
      canRemoveSongs: canRemoveSongs ?? this.canRemoveSongs,
      canEditChordSheet: canEditChordSheet ?? this.canEditChordSheet,
      canEditEvent: canEditEvent ?? this.canEditEvent,
      canManageParticipants:
          canManageParticipants ?? this.canManageParticipants,
      currentUserId: currentUserId ?? this.currentUserId,
      deletingSongId: clearDeletingSongId
          ? null
          : (deletingSongId ?? this.deletingSongId),
      participantsLoadFailed:
          participantsLoadFailed ?? this.participantsLoadFailed,
      songsLoadFailed: songsLoadFailed ?? this.songsLoadFailed,
    );
  }

  /// `true` quando o erro de carregamento não deve ser resolvido tentando
  /// novamente (ex: acesso negado ou evento não encontrado/removido).
  bool get loadErrorIsRetryable =>
      errorStatusCode != 403 && errorStatusCode != 404;

  bool canDeleteSong(EventSong song) {
    if (isProjectAdmin) return true;
    if (canRemoveSongs) return true;
    if (!canAddSongs) return false;
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) return false;
    return song.addedByUserId == userId;
  }

  bool isSongOwner(EventSong song) {
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) return false;
    return song.addedByUserId == userId;
  }

  bool canEditChordSheetOf(EventSong song) {
    if (isSongOwner(song)) return true;
    if (!canEditChordSheet) return false;
    return song.editChordSheetPermission;
  }

  @override
  List<Object?> get props => [
    status,
    event,
    participants,
    songs,
    errorMessage,
    errorStatusCode,
    actionErrorMessage,
    skillsMap,
    isProjectAdmin,
    canAddSongs,
    canRemoveSongs,
    canEditChordSheet,
    canEditEvent,
    canManageParticipants,
    currentUserId,
    deletingSongId,
    participantsLoadFailed,
    songsLoadFailed,
  ];
}
