class EventDetailEntity {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final DateTime date;
  final String time;
  final String? location;
  final String projectTitle;
  final String? projectImageUrl;
  final int participantsCount;
  final int repertoireCount;
  final List<String> participantsProfileImages; // Adicionado para os avatares

  const EventDetailEntity({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.date,
    required this.time,
    this.location,
    required this.projectTitle,
    this.projectImageUrl,
    required this.participantsCount,
    required this.repertoireCount,
    this.participantsProfileImages = const [],
  });

  factory EventDetailEntity.fromJson(Map<String, dynamic> json) {
    final projectMap = _asMap(json['project']);

    return EventDetailEntity(
      id: _readString(json['id']),
      projectId: _readString(json['projectId'] ?? projectMap?['id']),
      title: (json['title'] ?? '').toString(),
      description: _normalizeOptionalValue(json['description']),
      date: _parseDate(json['date']),
      time: json['time'].toString(),
      location: _normalizeOptionalValue(json['location']),
      projectTitle: _readString(
        json['projectTitle'] ?? projectMap?['title'] ?? '',
      ),
      projectImageUrl: _normalizeOptionalValue(
        json['projectImageUrl'] ?? projectMap?['imageUrl'],
      ),
      participantsCount: _toInt(json['participantsCount']),
      repertoireCount: _toInt(json['repertoireCount']),
      participantsProfileImages:
          (json['participantsProfileImages'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
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
