import 'package:equatable/equatable.dart';

class ProjectSkillEntity extends Equatable {
  final String id;
  final String name;
  final String? iconKey;

  const ProjectSkillEntity({required this.id, required this.name, this.iconKey});

  @override
  List<Object?> get props => [id, name, iconKey];
}
