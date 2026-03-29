class UserDetailEntity {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String? phoneNumber;
  final String? profileImage;
  final String? planName;

  UserDetailEntity({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    this.phoneNumber,
    this.profileImage,
    this.planName,
  });

  factory UserDetailEntity.fromJson(Map<String, dynamic> json) {
    return UserDetailEntity(
      id: json['id'] as String?,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      profileImage: json['profileImage'] as String?,
      planName: json['planName'] as String?,
    );
  }

  String get fullName => '$firstName $lastName';

  UserDetailEntity copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? username,
    String? phoneNumber,
    String? profileImage,
    String? planName,
  }) {
    return UserDetailEntity(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      planName: planName ?? this.planName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'username': username,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'planName': planName,
    };
  }
}
