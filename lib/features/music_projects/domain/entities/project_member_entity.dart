import 'package:equatable/equatable.dart';

import 'project_member_role.dart';

class ProjectMemberEntity extends Equatable {
  final String id;
  final String userId;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String? profileImage;
  final ProjectMemberRole projectRole;
  final List<String> skillIds;

  const ProjectMemberEntity({
    required this.id,
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.profileImage,
    required this.projectRole,
    required this.skillIds,
  });

  String get fullName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? username : fullName;
  }

  bool get isOwner => projectRole == ProjectMemberRole.owner;

  bool get isAdmin => projectRole.hasAdministrativeAccess;

  factory ProjectMemberEntity.fromJson(Map<String, dynamic> json) {
    return ProjectMemberEntity(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      username: (json['username'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      profileImage: json['profileImage']?.toString(),
      projectRole: projectMemberRoleFromString(json['projectRole']?.toString()),
      skillIds: (json['skills'] as List? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    username,
    firstName,
    lastName,
    email,
    profileImage,
    projectRole,
    skillIds,
  ];
}
