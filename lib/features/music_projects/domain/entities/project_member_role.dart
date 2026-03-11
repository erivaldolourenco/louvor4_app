enum ProjectMemberRole { owner, admin, member }

extension ProjectMemberRoleX on ProjectMemberRole {
  String get apiValue {
    switch (this) {
      case ProjectMemberRole.owner:
        return 'OWNER';
      case ProjectMemberRole.admin:
        return 'ADMIN';
      case ProjectMemberRole.member:
        return 'MEMBER';
    }
  }

  String get label {
    switch (this) {
      case ProjectMemberRole.owner:
        return 'Owner';
      case ProjectMemberRole.admin:
        return 'Administrador';
      case ProjectMemberRole.member:
        return 'Membro';
    }
  }

  bool get hasAdministrativeAccess =>
      this == ProjectMemberRole.owner || this == ProjectMemberRole.admin;
}

ProjectMemberRole projectMemberRoleFromString(String? value) {
  switch ((value ?? '').trim().toUpperCase()) {
    case 'OWNER':
      return ProjectMemberRole.owner;
    case 'ADMIN':
      return ProjectMemberRole.admin;
    default:
      return ProjectMemberRole.member;
  }
}
