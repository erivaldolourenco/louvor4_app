import '../../domain/entities/notifications_page_entity.dart';
import '../datasources/notifications_remote_datasource.dart';
import 'notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource _remoteDataSource;

  NotificationsRepositoryImpl({NotificationsRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? NotificationsRemoteDataSource();

  @override
  Future<void> acceptEventInvite(String participantId) {
    return _remoteDataSource.acceptEventInvite(participantId);
  }

  @override
  Future<void> declineEventInvite(String participantId) {
    return _remoteDataSource.declineEventInvite(participantId);
  }

  @override
  Future<void> respondProjectInvite(String projectId, bool accepted) {
    return _remoteDataSource.respondProjectInvite(projectId, accepted);
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return _remoteDataSource.markAsRead(notificationId);
  }

  @override
  Future<NotificationsPageEntity> getNotifications({
    required int page,
    required int size,
  }) {
    return _remoteDataSource.getNotifications(page: page, size: size);
  }

  @override
  Future<int> getUnreadNotificationsCount({int pageSize = 50}) async {
    var page = 0;
    var unreadCount = 0;
    var hasNext = true;

    while (hasNext) {
      final response = await _remoteDataSource.getNotifications(
        page: page,
        size: pageSize,
      );

      unreadCount += response.items.where((item) => !item.isRead).length;
      hasNext = !response.last;
      page += 1;
    }

    return unreadCount;
  }
}
