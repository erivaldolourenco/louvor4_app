import 'package:equatable/equatable.dart';

enum ProgramItemType { music, medley, text }

class ProgramMedleySong extends Equatable {
  final String id;
  final String title;
  final String artist;

  const ProgramMedleySong({
    required this.id,
    required this.title,
    required this.artist,
  });

  factory ProgramMedleySong.fromJson(Map<String, dynamic> json) {
    return ProgramMedleySong(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, title, artist];
}

sealed class ProgramItemEntity extends Equatable {
  final String id;
  final ProgramItemType type;
  final int position;

  const ProgramItemEntity({
    required this.id,
    required this.type,
    required this.position,
  });

  factory ProgramItemEntity.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String? ?? '').toUpperCase();
    final id = json['id'] as String;
    final position = json['position'] as int? ?? 0;

    if (rawType == 'MUSIC') {
      final musicRaw = json['music'];
      final music = musicRaw is Map ? musicRaw : <String, dynamic>{};
      return MusicProgramItemEntity(
        id: id,
        position: position,
        songId: music['id'] as String? ?? '',
        songTitle: music['title'] as String? ?? '',
        songArtist: music['artist'] as String? ?? '',
        songYouTubeUrl: music['youTubeUrl'] as String?,
        songKey: music['key'] as String?,
        addedBy: music['addBy'] as String?,
      );
    } else if (rawType == 'MEDLEY') {
      final medleyRaw = json['medley'];
      final medley = medleyRaw is Map ? medleyRaw : <String, dynamic>{};
      final rawSongs = medley['songs'];
      final songsList = rawSongs is List ? rawSongs : <dynamic>[];
      final songs = songsList
          .whereType<Map>()
          .map((s) => ProgramMedleySong.fromJson(Map<String, dynamic>.from(s)))
          .toList();
      return MedleyProgramItemEntity(
        id: id,
        position: position,
        medleyId: medley['id'] as String? ?? '',
        medleyName: medley['name'] as String? ?? '',
        songs: songs,
      );
    } else {
      return TextProgramItemEntity(
        id: id,
        position: position,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
      );
    }
  }
}

class MusicProgramItemEntity extends ProgramItemEntity {
  final String songId;
  final String songTitle;
  final String songArtist;
  final String? songYouTubeUrl;
  final String? songKey;
  final String? addedBy;

  const MusicProgramItemEntity({
    required super.id,
    required super.position,
    required this.songId,
    required this.songTitle,
    required this.songArtist,
    this.songYouTubeUrl,
    this.songKey,
    this.addedBy,
  }) : super(type: ProgramItemType.music);

  @override
  List<Object?> get props => [
    id,
    type,
    position,
    songId,
    songTitle,
    songArtist,
    songYouTubeUrl,
    songKey,
    addedBy,
  ];
}

class MedleyProgramItemEntity extends ProgramItemEntity {
  final String medleyId;
  final String medleyName;
  final List<ProgramMedleySong> songs;

  const MedleyProgramItemEntity({
    required super.id,
    required super.position,
    required this.medleyId,
    required this.medleyName,
    required this.songs,
  }) : super(type: ProgramItemType.medley);

  @override
  List<Object?> get props => [id, type, position, medleyId, medleyName, songs];
}

class TextProgramItemEntity extends ProgramItemEntity {
  final String title;
  final String? description;

  const TextProgramItemEntity({
    required super.id,
    required super.position,
    required this.title,
    this.description,
  }) : super(type: ProgramItemType.text);

  @override
  List<Object?> get props => [id, type, position, title, description];
}
