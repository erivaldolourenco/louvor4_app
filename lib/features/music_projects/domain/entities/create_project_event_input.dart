class CreateProjectEventInput {
  final String title;
  final String? description;
  final String startDate;
  final String startTime;
  final String location;

  const CreateProjectEventInput({
    required this.title,
    required this.description,
    required this.startDate,
    required this.startTime,
    required this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title.trim(),
      'description': description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      'startDate': startDate,
      'startTime': startTime,
      'location': location.trim(),
    };
  }
}
