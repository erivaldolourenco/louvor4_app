import 'package:equatable/equatable.dart';

class SongEntity extends Equatable {
  final String? id;
  final String artist;
  final String title;
  final String key;
  final String? bpm;
  final String youTubeUrl;

  const SongEntity({
    this.id,
    required this.artist,
    required this.title,
    required this.key,
    this.bpm,
    required this.youTubeUrl,
  });

  factory SongEntity.fromJson(Map<String, dynamic> json) {
    return SongEntity(
      id: json['id']?.toString(),
      artist: (json['artist'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      key: (json['key'] ?? '').toString(),
      bpm: _normalizeOptionalValue(json['bpm']),
      youTubeUrl: (json['youTubeUrl'] ?? json['youtubeUrl'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'artist': artist,
      'title': title,
      'key': key,
      if (bpm != null && bpm!.isNotEmpty) 'bpm': bpm,
      'youTubeUrl': youTubeUrl,
    };
  }

  static String? _normalizeOptionalValue(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  @override
  List<Object?> get props => [id, artist, title, key, bpm, youTubeUrl];
}
