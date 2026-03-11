enum ProjectRole { owner, admin, member }

extension ProjectRoleX on ProjectRole {
  bool get canManageSkills =>
      this == ProjectRole.owner || this == ProjectRole.admin;

  String get apiValue {
    switch (this) {
      case ProjectRole.owner:
        return 'OWNER';
      case ProjectRole.admin:
        return 'ADMIN';
      case ProjectRole.member:
        return 'MEMBER';
    }
  }
}

ProjectRole projectRoleFromString(String? value) {
  switch ((value ?? '').trim().toUpperCase()) {
    case 'OWNER':
      return ProjectRole.owner;
    case 'ADMIN':
      return ProjectRole.admin;
    default:
      return ProjectRole.member;
  }
}
