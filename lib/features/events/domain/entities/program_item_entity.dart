import 'package:equatable/equatable.dart';

enum ProgramItemType { music, text }

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
      final music = json['music'] as Map? ?? {};
      return MusicProgramItemEntity(
        id: id,
        position: position,
        songId: music['id'] as String? ?? '',
        songTitle: music['title'] as String? ?? '',
        songArtist: music['artist'] as String? ?? '',
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

  const MusicProgramItemEntity({
    required super.id,
    required super.position,
    required this.songId,
    required this.songTitle,
    required this.songArtist,
  }) : super(type: ProgramItemType.music);

  @override
  List<Object?> get props => [id, type, position, songId, songTitle, songArtist];
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
