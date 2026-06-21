import '../../../medleys/domain/entities/medley_entity.dart';

enum SetlistItemType { song, medley }

class EventSong {
  final String id;
  final String title;
  final String? artist;
  final String? key;
  final int? bpm;
  final String? youTubeUrl;
  final String? notes;
  final String? referenceAudioUrl;
  final String addedBy;
  final SetlistItemType type;
  final MedleyEntity? medleyEntity;

  const EventSong({
    required this.id,
    required this.title,
    this.artist,
    this.key,
    this.bpm,
    this.youTubeUrl,
    this.notes,
    this.referenceAudioUrl,
    required this.addedBy,
    this.type = SetlistItemType.song,
    this.medleyEntity,
  });

  bool get isMedley => type == SetlistItemType.medley;

  factory EventSong.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString() ?? 'SONG';
    final isMedley = rawType == 'MEDLEY';

    if (isMedley) {
      final eventMedleyRaw = json['eventMedley'];
      final medleyMap = eventMedleyRaw is Map
          ? Map<String, dynamic>.from(eventMedleyRaw)
          : <String, dynamic>{};
      final medleyEntity = MedleyEntity.fromJson(medleyMap);

      return EventSong(
        id: json['id']?.toString() ?? '',
        title: medleyEntity.name.isNotEmpty ? medleyEntity.name : 'Medley',
        artist: medleyEntity.description,
        notes: medleyEntity.notes ?? json['notes']?.toString(),
        addedBy: json['addedBy']?.toString() ?? '',
        type: SetlistItemType.medley,
        medleyEntity: medleyEntity,
      );
    }

    final eventSongRaw = json['eventSong'];
    final song = eventSongRaw is Map
        ? Map<String, dynamic>.from(eventSongRaw)
        : json;
    return EventSong(
      id: json['id']?.toString() ?? '',
      title: song['title']?.toString() ?? '',
      artist: song['artist']?.toString(),
      key: song['key']?.toString(),
      bpm: _toInt(song['bpm']),
      youTubeUrl: song['youTubeUrl']?.toString(),
      notes: json['notes']?.toString(),
      referenceAudioUrl: song['referenceAudioUrl']?.toString(),
      addedBy: json['addedBy']?.toString() ?? '',
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
