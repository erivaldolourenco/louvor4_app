import 'package:equatable/equatable.dart';

class MedleyItemEntity extends Equatable {
  final String? id;
  final String? songId;
  final String? songTitle;
  final String? songArtist;
  final String? youTubeUrl;
  final String? spotifyUrl;
  final String? deezerUrl;
  final String? key;
  final String? notes;
  final int sequence;

  const MedleyItemEntity({
    this.id,
    this.songId,
    this.songTitle,
    this.songArtist,
    this.youTubeUrl,
    this.spotifyUrl,
    this.deezerUrl,
    this.key,
    this.notes,
    required this.sequence,
  });

  factory MedleyItemEntity.fromJson(Map<String, dynamic> json) {
    // API may return nested song data under 'song' or 'Song' key
    final rawSong = json['song'] ?? json['Song'];
    final songMap = rawSong is Map
        ? Map<String, dynamic>.from(rawSong)
        : null;

    return MedleyItemEntity(
      id: json['id']?.toString(),
      songId: json['songId']?.toString() ?? songMap?['id']?.toString(),
      songTitle: json['songTitle']?.toString() ?? songMap?['title']?.toString(),
      songArtist: json['songArtist']?.toString() ?? songMap?['artist']?.toString(),
      youTubeUrl: json['youTubeUrl']?.toString() ?? songMap?['youTubeUrl']?.toString(),
      spotifyUrl: _normalizeOptional(json['spotifyUrl'] ?? songMap?['spotifyUrl']),
      deezerUrl: _normalizeOptional(json['deezerUrl'] ?? songMap?['deezerUrl']),
      key: json['key']?.toString() ?? songMap?['key']?.toString(),
      notes: _normalizeOptional(json['notes']),
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
    );
  }

  static String? _normalizeOptional(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  @override
  List<Object?> get props => [
    id,
    songId,
    songTitle,
    songArtist,
    youTubeUrl,
    spotifyUrl,
    deezerUrl,
    key,
    notes,
    sequence,
  ];
}
