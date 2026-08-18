import 'package:equatable/equatable.dart';

class ProjectSkillEntity extends Equatable {
  final String id;
  final String name;
  final String? iconKey;

  const ProjectSkillEntity({
    required this.id,
    required this.name,
    this.iconKey,
  });

  factory ProjectSkillEntity.fromJson(Map<String, dynamic> json) {
    return ProjectSkillEntity(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      iconKey: json['iconKey']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, iconKey];
}
