class EventEntity {
  final String id;
  final DateTime date;
  final String time;
  final String title;
  final String? location;
  final String projectTitle;
  final String? projectImageUrl;
  final int participantsCount;
  final int repertoireCount;
  final List<String>
  participantsProfileImages; // Atualizado para bater com o novo campo

  const EventEntity({
    required this.id,
    required this.date,
    required this.time,
    required this.title,
    this.location,
    required this.projectTitle,
    this.projectImageUrl,
    required this.participantsCount,
    required this.repertoireCount,
    this.participantsProfileImages = const [],
  });

  factory EventEntity.fromJson(Map<String, dynamic> json) {
    return EventEntity(
      id: _readString(json['id']),
      date: _parseDate(json['date']),
      time: json['time'].toString(),
      title: (json['title'] ?? '').toString(),
      location: _normalizeOptionalValue(json['location']),
      projectTitle: (json['projectTitle'] ?? '').toString(),
      projectImageUrl: _normalizeOptionalValue(json['projectImageUrl']),
      participantsCount: _toInt(json['participantsCount']),
      repertoireCount: _toInt(json['repertoireCount']),
      participantsProfileImages:
          (json['participantsProfileImages'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _readString(dynamic value) {
    final normalized = _normalizeOptionalValue(value);
    return normalized ?? '';
  }

  static String? _normalizeOptionalValue(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized.isEmpty || normalized.toLowerCase() == 'null'
        ? null
        : normalized;
  }
}
