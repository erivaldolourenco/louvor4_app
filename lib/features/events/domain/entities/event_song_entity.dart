enum SetlistItemType { song, medley }

class EventSong {
  final String id;
  final String title;
  final String? artist;
  final String? key;
  final int? bpm;
  final String? youTubeUrl;
  final String? notes;
  final String addedBy;
  final SetlistItemType type;

  const EventSong({
    required this.id,
    required this.title,
    this.artist,
    this.key,
    this.bpm,
    this.youTubeUrl,
    this.notes,
    required this.addedBy,
    this.type = SetlistItemType.song,
  });

  bool get isMedley => type == SetlistItemType.medley;

  factory EventSong.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString() ?? 'SONG';
    final isMedley = rawType == 'MEDLEY';

    if (isMedley) {
      final medley = json['eventMedley'] != null
          ? Map<String, dynamic>.from(json['eventMedley'] as Map)
          : <String, dynamic>{};
      return EventSong(
        id: json['id'].toString(),
        title: medley['name']?.toString() ?? 'Medley',
        artist: medley['description']?.toString(),
        notes: medley['notes']?.toString() ?? json['notes']?.toString(),
        addedBy: json['addedBy'].toString(),
        type: SetlistItemType.medley,
      );
    }

    final song = json['eventSong'] != null
        ? Map<String, dynamic>.from(json['eventSong'] as Map)
        : json;
    return EventSong(
      id: json['id'].toString(),
      title: song['title'].toString(),
      artist: song['artist']?.toString(),
      key: song['key']?.toString(),
      bpm: _toInt(song['bpm']),
      youTubeUrl: song['youTubeUrl']?.toString(),
      notes: json['notes']?.toString(),
      addedBy: json['addedBy'].toString(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
