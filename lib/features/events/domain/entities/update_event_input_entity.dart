class UpdateEventInputEntity {
  final String title;
  final String? description;
  final String startDate;
  final String startTime;
  final String location;

  const UpdateEventInputEntity({
    required this.title,
    this.description,
    required this.startDate,
    required this.startTime,
    required this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'startDate': startDate,
      'startTime': startTime,
      'location': location,
    };
  }
}
