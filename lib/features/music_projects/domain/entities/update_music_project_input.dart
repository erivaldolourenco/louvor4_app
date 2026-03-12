import 'music_project_entity.dart';

class UpdateMusicProjectInput {
  final String id;
  final String name;
  final MusicProjectType type;

  const UpdateMusicProjectInput({
    required this.id,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'type': _typeToApiValue(type)};
  }

  static String _typeToApiValue(MusicProjectType type) {
    switch (type) {
      case MusicProjectType.band:
        return 'BAND';
      case MusicProjectType.ministry:
        return 'MINISTRY';
      case MusicProjectType.singer:
        return 'SINGER';
      case MusicProjectType.unknown:
        return 'MINISTRY';
    }
  }
}
