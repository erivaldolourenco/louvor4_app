import 'music_project_entity.dart';

class CreateMusicProjectInput {
  final String name;
  final MusicProjectType type;

  const CreateMusicProjectInput({required this.name, required this.type});

  Map<String, dynamic> toJson() {
    return {'name': name.trim(), 'type': _typeToApi(type)};
  }

  String _typeToApi(MusicProjectType type) {
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
