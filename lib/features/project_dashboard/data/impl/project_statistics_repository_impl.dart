import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_message.dart';
import '../../domain/entities/project_statistics_entities.dart';
import '../project_statistics_repository.dart';

class ProjectStatisticsRepositoryImpl implements ProjectStatisticsRepository {
  final Dio _dio;

  ProjectStatisticsRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  @override
  Future<ProjectScheduleStatsEntity> getScheduleStats(
    String projectId, {
    String? from,
    String? to,
  }) async {
    final data = await _get(
      '/music-project/$projectId/statistics/schedules',
      from: from,
      to: to,
      fallback: 'Não foi possível carregar as escalas.',
    );
    return ProjectScheduleStatsEntity.fromJson(data);
  }

  @override
  Future<ProjectInviteStatsEntity> getInviteStats(
    String projectId, {
    String? from,
    String? to,
  }) async {
    final data = await _get(
      '/music-project/$projectId/statistics/invites',
      from: from,
      to: to,
      fallback: 'Não foi possível carregar os convites.',
    );
    return ProjectInviteStatsEntity.fromJson(data);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    String? from,
    String? to,
    required String fallback,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: {'from': ?from, 'to': ?to},
      );
      final data = response.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw Exception(fallback);
    } on DioException catch (e) {
      throw Exception(extractApiErrorMessage(e, fallback: fallback));
    }
  }
}
