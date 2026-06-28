import 'package:dio/dio.dart';

String extractApiErrorMessage(
  DioException e, {
  String fallback = 'Ocorreu um erro inesperado.',
}) {
  if (e.response == null) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'O servidor demorou demais para responder. Tente novamente.';
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return 'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.';
      default:
        return fallback;
    }
  }

  final data = e.response!.data;

  if (data is Map<String, dynamic>) {
    final msg =
        data['detail'] ?? data['message'] ?? data['error'] ?? data['details'];
    if (msg != null && msg.toString().trim().isNotEmpty) return msg.toString();
  }

  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    final msg =
        map['detail'] ?? map['message'] ?? map['error'] ?? map['details'];
    if (msg != null && msg.toString().trim().isNotEmpty) return msg.toString();
  }

  if (data is String && data.trim().isNotEmpty) return data;

  return fallback;
}
