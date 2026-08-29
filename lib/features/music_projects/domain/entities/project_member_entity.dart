import 'package:equatable/equatable.dart';

import 'project_member_role.dart';
import 'project_skill_entity.dart';

enum ProjectMemberStatus { active, pendingInvite, declined, removed }

ProjectMemberStatus _parseProjectMemberStatus(dynamic value) {
  switch (value?.toString().trim().toUpperCase()) {
    case 'PENDING_INVITE':
      return ProjectMemberStatus.pendingInvite;
    case 'DECLINED':
      return ProjectMemberStatus.declined;
    case 'REMOVED':
      return ProjectMemberStatus.removed;
    default:
      return ProjectMemberStatus.active;
  }
}

class ProjectMemberEntity extends Equatable {
  final String id;
  final String userId;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String? profileImage;
  final ProjectMemberRole projectRole;
  final ProjectMemberStatus status;
  final List<ProjectSkillEntity> skills;

  const ProjectMemberEntity({
    required this.id,
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.profileImage,
    required this.projectRole,
    this.status = ProjectMemberStatus.active,
    required this.skills,
  });

  String get fullName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? username : fullName;
  }

  List<String> get skillIds => skills.map((skill) => skill.id).toList();

  bool get isOwner => projectRole == ProjectMemberRole.owner;

  bool get isAdmin => projectRole.hasAdministrativeAccess;

  bool get isPending => status == ProjectMemberStatus.pendingInvite;

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
      status: _parseProjectMemberStatus(json['status']),
      skills: (json['skills'] as List? ?? const [])
          .map(_parseSkill)
          .whereType<ProjectSkillEntity>()
          .toList(),
    );
  }

  // Aceita tanto o novo formato ({id, name, iconKey}) quanto o antigo
  // (apenas o id da skill como string), para compatibilidade retroativa.
  static ProjectSkillEntity? _parseSkill(dynamic item) {
    if (item is Map<String, dynamic>) return ProjectSkillEntity.fromJson(item);
    if (item is Map) {
      return ProjectSkillEntity.fromJson(Map<String, dynamic>.from(item));
    }
    final id = item?.toString().trim();
    if (id == null || id.isEmpty) return null;
    return ProjectSkillEntity(id: id, name: '');
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
    status,
    skills,
  ];
}
