import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/notifications_page_model.dart';

class NotificationsRemoteDataSource {
  final Dio _dio;

  NotificationsRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  Future<NotificationsPageModel> getNotifications({
    required int page,
    required int size,
  }) async {
    try {
      final response = await _dio.get(
        '/users/notifications',
        queryParameters: {'page': page, 'size': size},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return NotificationsPageModel.fromJson(data);
      }
      if (data is Map) {
        return NotificationsPageModel.fromJson(Map<String, dynamic>.from(data));
      }

      throw Exception('Resposta inválida ao carregar notificações.');
    } on DioException catch (error) {
      throw Exception(_extractApiMessage(error));
    }
  }

  Future<void> acceptEventInvite(String participantId) async {
    try {
      await _dio.patch('/events/participants/$participantId/accept');
    } on DioException catch (error) {
      throw Exception(_extractApiMessage(error));
    }
  }

  Future<void> declineEventInvite(String participantId) async {
    try {
      await _dio.patch('/events/participants/$participantId/decline');
    } on DioException catch (error) {
      throw Exception(_extractApiMessage(error));
    }
  }

  Future<void> respondProjectInvite(String projectId, bool accepted) async {
    try {
      await _dio.post(
        '/music-project/$projectId/members/invite/respond',
        data: {'accepted': accepted},
      );
    } on DioException catch (error) {
      throw Exception(_extractApiMessage(error));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _dio.get('/notifications/$notificationId/read');
    } on DioException catch (error) {
      throw Exception(_extractApiMessage(error));
    }
  }

  String _extractApiMessage(
    DioException error, {
    String fallback = 'Não foi possível concluir a operação.',
  }) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['detail'] ?? data['message'] ?? data['error'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message = map['detail'] ?? map['message'] ?? map['error'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    return error.message ?? fallback;
  }
}
