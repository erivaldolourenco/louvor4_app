class EventSong {
  final String id;
  final String title;
  final String? artist;
  final String? key;
  final int? bpm;
  final String? youTubeUrl;
  final String addedBy;

  const EventSong({
    required this.id,
    required this.title,
    this.artist,
    this.key,
    this.bpm,
    this.youTubeUrl,
    required this.addedBy,
  });

  factory EventSong.fromJson(Map<String, dynamic> json) {
    return EventSong(
      id: json['id'].toString(),
      title: json['title'].toString(),
      artist: json['artist']?.toString(),
      key: json['key']?.toString(),
      bpm: (json['bpm'] as int?),
      youTubeUrl: json['youTubeUrl']?.toString(),
      addedBy: json['addedBy'].toString(),
    );
  }
}
