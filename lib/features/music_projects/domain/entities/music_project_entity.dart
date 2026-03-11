import 'package:equatable/equatable.dart';

enum MusicProjectType { band, ministry, singer, unknown }

class MusicProjectEntity extends Equatable {
  final String id;
  final String name;
  final MusicProjectType type;
  final String? profileImage;

  const MusicProjectEntity({
    required this.id,
    required this.name,
    required this.type,
    this.profileImage,
  });

  factory MusicProjectEntity.fromJson(Map<String, dynamic> json) {
    return MusicProjectEntity(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: _parseType((json['type'] ?? '').toString()),
      profileImage: _normalizeOptionalValue(json['profileImage']),
    );
  }

  static MusicProjectType _parseType(String raw) {
    switch (raw.toUpperCase()) {
      case 'BAND':
        return MusicProjectType.band;
      case 'MINISTRY':
        return MusicProjectType.ministry;
      case 'SINGER':
        return MusicProjectType.singer;
      default:
        return MusicProjectType.unknown;
    }
  }

  static String? _normalizeOptionalValue(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  @override
  List<Object?> get props => [id, name, type, profileImage];
}
