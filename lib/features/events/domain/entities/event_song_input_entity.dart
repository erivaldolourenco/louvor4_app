enum EventSongInputType { song, medley }

class EventSongInputEntity {
  final String itemId;
  final EventSongInputType type;

  const EventSongInputEntity({
    required this.itemId,
    this.type = EventSongInputType.song,
  });

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'type': type == EventSongInputType.medley ? 'MEDLEY' : 'SONG',
  };
}
