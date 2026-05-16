class CreateTextProgramItemInputEntity {
  final String title;
  final String? description;

  const CreateTextProgramItemInputEntity({
    required this.title,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    if (description != null && description!.isNotEmpty) 'description': description,
  };
}

class UpdateTextProgramItemInputEntity {
  final String title;
  final String? description;

  const UpdateTextProgramItemInputEntity({
    required this.title,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    if (description != null && description!.isNotEmpty) 'description': description,
  };
}
