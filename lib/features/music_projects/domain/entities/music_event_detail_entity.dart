import 'package:equatable/equatable.dart';

class MusicEventDetailEntity extends Equatable {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final DateTime date;
  final String time;
  final String location;
  final String projectTitle;
  final String? projectImageUrl;
  final int participantsCount;
  final int repertoireCount;

  const MusicEventDetailEntity({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.projectTitle,
    this.projectImageUrl,
    required this.participantsCount,
    required this.repertoireCount,
  });

  factory MusicEventDetailEntity.fromJson(Map<String, dynamic> json) {
    return MusicEventDetailEntity(
      id: (json['id'] ?? '').toString(),
      projectId: (json['projectId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: _normalizeOptionalValue(json['description']),
      date: _parseDate(json['date']),
      time: (json['time'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      projectTitle: (json['projectTitle'] ?? '').toString(),
      projectImageUrl: _normalizeOptionalValue(json['projectImageUrl']),
      participantsCount: _toInt(json['participantsCount']),
      repertoireCount: _toInt(json['repertoireCount']),
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

  static String? _normalizeOptionalValue(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  @override
  List<Object?> get props => [
    id,
    projectId,
    title,
    description,
    date,
    time,
    location,
    projectTitle,
    projectImageUrl,
    participantsCount,
    repertoireCount,
  ];
}
