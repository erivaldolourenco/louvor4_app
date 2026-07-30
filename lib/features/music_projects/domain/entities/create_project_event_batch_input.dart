class CreateProjectEventBatchInput {
  final String title;
  final String? description;
  final List<String> dates;
  final String startTime;
  final String location;

  const CreateProjectEventBatchInput({
    required this.title,
    required this.description,
    required this.dates,
    required this.startTime,
    required this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title.trim(),
      'description': description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      'dates': dates,
      'startTime': startTime,
      'location': location.trim(),
    };
  }
}
