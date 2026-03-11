class AddProjectSkillRequestModel {
  final String name;

  const AddProjectSkillRequestModel({required this.name});

  Map<String, dynamic> toJson() {
    return {'name': name.trim()};
  }
}
