class MusicProjectRequestException implements Exception {
  final String message;
  final int? statusCode;

  const MusicProjectRequestException({required this.message, this.statusCode});

  @override
  String toString() => message;
}
