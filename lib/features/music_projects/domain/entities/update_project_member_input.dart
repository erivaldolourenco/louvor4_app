import 'project_member_role.dart';

class UpdateProjectMemberInput {
  final ProjectMemberRole projectRole;
  final List<String> skillIds;

  const UpdateProjectMemberInput({
    required this.projectRole,
    required this.skillIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'projectRole': projectRole.apiValue,
      'skillIds': skillIds,
    };
  }
}
