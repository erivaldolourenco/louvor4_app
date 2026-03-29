class EventSong {
  final String id;
  final String title;
  final String? artist;
  final String? key;
  final int? bpm;
  final String? youTubeUrl;
  final String? notes;
  final String addedBy;

  const EventSong({
    required this.id,
    required this.title,
    this.artist,
    this.key,
    this.bpm,
    this.youTubeUrl,
    this.notes,
    required this.addedBy,
  });

  factory EventSong.fromJson(Map<String, dynamic> json) {
    return EventSong(
      id: json['id'].toString(),
      title: json['title'].toString(),
      artist: json['artist']?.toString(),
      key: json['key']?.toString(),
      bpm: _toInt(json['bpm']),
      youTubeUrl: json['youTubeUrl']?.toString(),
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
