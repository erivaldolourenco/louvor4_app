import 'package:equatable/equatable.dart';

class ProjectContextEntity extends Equatable {
  final String id;
  final String name;
  final String? profileImage;

  const ProjectContextEntity({
    required this.id,
    required this.name,
    required this.profileImage,
  });

  @override
  List<Object?> get props => [id, name, profileImage];
}
