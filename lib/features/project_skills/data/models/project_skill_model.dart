import '../../domain/entities/project_skill_entity.dart';

class ProjectSkillModel extends ProjectSkillEntity {
  const ProjectSkillModel({required super.id, required super.name});

  factory ProjectSkillModel.fromJson(Map<String, dynamic> json) {
    return ProjectSkillModel(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}
