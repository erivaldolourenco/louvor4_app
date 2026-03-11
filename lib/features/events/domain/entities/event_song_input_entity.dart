class EventSongInputEntity {
  final String songId;

  const EventSongInputEntity({required this.songId});

  Map<String, dynamic> toJson() {
    return {'songId': songId};
  }
}
