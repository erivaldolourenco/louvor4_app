import 'package:equatable/equatable.dart';

class ProjectSkillEntity extends Equatable {
  final String id;
  final String name;

  const ProjectSkillEntity({required this.id, required this.name});

  factory ProjectSkillEntity.fromJson(Map<String, dynamic> json) {
    return ProjectSkillEntity(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [id, name];
}
