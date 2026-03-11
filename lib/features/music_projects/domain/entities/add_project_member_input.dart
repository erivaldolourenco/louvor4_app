class AddProjectMemberInput {
  final String username;

  const AddProjectMemberInput({required this.username});

  Map<String, dynamic> toJson() {
    return {'username': username.trim()};
  }
}
