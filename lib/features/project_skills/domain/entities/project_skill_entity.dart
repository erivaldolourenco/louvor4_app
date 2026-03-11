import 'package:equatable/equatable.dart';

class ProjectSkillEntity extends Equatable {
  final String id;
  final String name;

  const ProjectSkillEntity({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}
