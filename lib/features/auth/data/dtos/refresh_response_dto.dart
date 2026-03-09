class RefreshResponseDto {
  final String accessToken;
  final String? refreshToken;
  final String? expiresAt;

  const RefreshResponseDto({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  factory RefreshResponseDto.fromJson(Map<String, dynamic> json) {
    return RefreshResponseDto(
      accessToken: (json['accessToken'] ?? '').toString(),
      refreshToken: json['refreshToken']?.toString(),
      expiresAt: json['expiresAt']?.toString(),
    );
  }
}
