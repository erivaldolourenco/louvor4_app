class CreateUserInputEntity {
  final String firstName;
  final String lastName;
  final String username;
  final String password;
  final String email;

  const CreateUserInputEntity({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.password,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'username': username.trim(),
      'password': password,
      'email': email.trim(),
    };
  }
}
