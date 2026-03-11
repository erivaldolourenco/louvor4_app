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
    return EventDetailEntity(
      id: json['id'].toString(),
      projectId: json['projectId'].toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      date: DateTime.parse(json['date'].toString()),
      time: json['time'].toString(),
      location: json['location']?.toString(),
      projectTitle: (json['projectTitle'] ?? '').toString(),
      projectImageUrl: json['projectImageUrl']?.toString(),
      participantsCount: (json['participantsCount'] ?? 0) as int,
      repertoireCount: (json['repertoireCount'] ?? 0) as int,
      participantsProfileImages:
          (json['participantsProfileImages'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
