class LoginResponseDto {
  final String accessToken;
  final String refreshToken;
  final String? expiresAt;
  final Map<String, dynamic> user;

  const LoginResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.expiresAt,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      accessToken: (json['accessToken'] ?? '').toString(),
      refreshToken: (json['refreshToken'] ?? '').toString(),
      expiresAt: json['expiresAt']?.toString(),
      user: Map<String, dynamic>.from(json['user'] as Map),
    );
  }
}
