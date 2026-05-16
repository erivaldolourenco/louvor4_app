class AddProjectSkillRequestModel {
  final String name;
  final String? iconKey;

  const AddProjectSkillRequestModel({required this.name, this.iconKey});

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      if (iconKey != null) 'iconKey': iconKey,
    };
  }
}
