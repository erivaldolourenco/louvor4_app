import '../../../medleys/domain/entities/medley_entity.dart';

enum SetlistItemType { song, medley }

class EventSong {
  final String id;
  final String? songId;
  final String title;
  final String? artist;
  final String? key;
  final int? bpm;
  final String? youTubeUrl;
  final String? spotifyUrl;
  final String? deezerUrl;
  final String? coverUrl;
  final String? notes;
  final String? referenceAudioUrl;
  final String? vsAudioUrl;
  final String addedBy;
  final String? addedByUserId;
  final SetlistItemType type;
  final MedleyEntity? medleyEntity;

  /// Se `true`, o dono da música permitiu que outros membros do evento (com
  /// a permissão [EventPermission.editChordSheet]) editem a cifra dela.
  final bool editChordSheetPermission;

  const EventSong({
    required this.id,
    this.songId,
    required this.title,
    this.artist,
    this.key,
    this.bpm,
    this.youTubeUrl,
    this.spotifyUrl,
    this.deezerUrl,
    this.coverUrl,
    this.notes,
    this.referenceAudioUrl,
    this.vsAudioUrl,
    required this.addedBy,
    this.addedByUserId,
    this.type = SetlistItemType.song,
    this.medleyEntity,
    this.editChordSheetPermission = false,
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
        addedByUserId: json['addedByUserId']?.toString(),
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
      songId: song['songId']?.toString(),
      title: song['title']?.toString() ?? '',
      artist: song['artist']?.toString(),
      key: song['key']?.toString(),
      bpm: _toInt(song['bpm']),
      youTubeUrl: _normalizeOptionalValue(
        song['youTubeUrl'] ?? song['youtubeUrl'],
      ),
      spotifyUrl: _normalizeOptionalValue(song['spotifyUrl']),
      deezerUrl: _normalizeOptionalValue(song['deezerUrl']),
      coverUrl: _normalizeOptionalValue(song['coverUrl']),
      notes: json['notes']?.toString(),
      referenceAudioUrl: _normalizeOptionalValue(song['referenceAudioUrl']),
      vsAudioUrl: _normalizeOptionalValue(song['vsAudioUrl']),
      addedBy: json['addedBy']?.toString() ?? '',
      addedByUserId: json['addedByUserId']?.toString(),
      editChordSheetPermission: song['editChordSheetPermission'] == true,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static String? _normalizeOptionalValue(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }
}
