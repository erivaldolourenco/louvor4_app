class UpdateUserInputEntity {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;

  const UpdateUserInputEntity({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
    };
  }
}
