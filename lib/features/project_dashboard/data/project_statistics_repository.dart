import '../domain/entities/project_statistics_entities.dart';

abstract class ProjectStatisticsRepository {
  /// [from] e [to] no formato "YYYY-MM". Quando nulos, a API usa os últimos 6 meses.
  Future<ProjectScheduleStatsEntity> getScheduleStats(
    String projectId, {
    String? from,
    String? to,
  });

  Future<ProjectInviteStatsEntity> getInviteStats(
    String projectId, {
    String? from,
    String? to,
  });
}
