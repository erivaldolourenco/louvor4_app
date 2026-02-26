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
  });

  factory EventEntity.fromJson(Map<String, dynamic> json) {
    return EventEntity(
      id: json['id'].toString(),
      date: DateTime.parse(json['date'].toString()),
      time: json['time'].toString(),
      title: (json['title'] ?? '').toString(),
      location: json['location']?.toString(),
      projectTitle: (json['projectTitle'] ?? '').toString(),
      projectImageUrl: json['projectImageUrl']?.toString(),
      participantsCount: (json['participantsCount'] ?? 0) as int,
      repertoireCount: (json['repertoireCount'] ?? 0) as int,
    );
  }
}
