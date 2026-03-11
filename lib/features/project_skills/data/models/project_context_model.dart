import '../../domain/entities/project_context_entity.dart';

class ProjectContextModel extends ProjectContextEntity {
  const ProjectContextModel({
    required super.id,
    required super.name,
    required super.profileImage,
  });

  factory ProjectContextModel.fromJson(Map<String, dynamic> json) {
    return ProjectContextModel(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      profileImage: json['profileImage']?.toString(),
    );
  }
}
