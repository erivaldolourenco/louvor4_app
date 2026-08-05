import 'package:equatable/equatable.dart';

class SongEntity extends Equatable {
  final String? id;
  final String artist;
  final String title;
  final String key;
  final String? bpm;
  final String? album;
  final String? youTubeUrl;
  final String? spotifyUrl;
  final String? deezerUrl;
  final String? coverUrl;
  final String? notes;
  final String? referenceAudioUrl;

  const SongEntity({
    this.id,
    required this.artist,
    required this.title,
    required this.key,
    this.bpm,
    this.album,
    this.youTubeUrl,
    this.spotifyUrl,
    this.deezerUrl,
    this.coverUrl,
    this.notes,
    this.referenceAudioUrl,
  });

  factory SongEntity.fromJson(Map<String, dynamic> json) {
    return SongEntity(
      id: json['id']?.toString(),
      artist: (json['artist'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      key: (json['key'] ?? '').toString(),
      bpm: _normalizeOptionalValue(json['bpm']),
      album: _normalizeOptionalValue(json['album']),
      youTubeUrl: _normalizeOptionalValue(
        json['youTubeUrl'] ?? json['youtubeUrl'],
      ),
      spotifyUrl: _normalizeOptionalValue(json['spotifyUrl']),
      deezerUrl: _normalizeOptionalValue(json['deezerUrl']),
      coverUrl: _normalizeOptionalValue(json['coverUrl']),
      notes: _normalizeOptionalValue(json['notes']),
      referenceAudioUrl: _normalizeOptionalValue(json['referenceAudioUrl']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'artist': artist,
      'title': title,
      'key': key,
      if (bpm != null && bpm!.isNotEmpty) 'bpm': bpm,
      if (album != null && album!.isNotEmpty) 'album': album,
      if (youTubeUrl != null && youTubeUrl!.isNotEmpty)
        'youTubeUrl': youTubeUrl,
      if (spotifyUrl != null && spotifyUrl!.isNotEmpty)
        'spotifyUrl': spotifyUrl,
      if (deezerUrl != null && deezerUrl!.isNotEmpty) 'deezerUrl': deezerUrl,
      if (coverUrl != null && coverUrl!.isNotEmpty) 'coverUrl': coverUrl,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (referenceAudioUrl != null && referenceAudioUrl!.isNotEmpty)
        'referenceAudioUrl': referenceAudioUrl,
    };
  }

  static String? _normalizeOptionalValue(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  @override
  List<Object?> get props => [
    id,
    artist,
    title,
    key,
    bpm,
    album,
    youTubeUrl,
    spotifyUrl,
    deezerUrl,
    coverUrl,
    notes,
    referenceAudioUrl,
  ];
}
