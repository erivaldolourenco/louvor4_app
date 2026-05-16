class AuthRequestException implements Exception {
  final String message;
  final int? statusCode;

  const AuthRequestException({required this.message, this.statusCode});

  @override
  String toString() => message;
}
