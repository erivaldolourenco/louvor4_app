import '../../domain/entities/notifications_page_entity.dart';

abstract class NotificationsRepository {
  Future<NotificationsPageEntity> getNotifications({
    required int page,
    required int size,
  });

  Future<int> getUnreadNotificationsCount({int pageSize = 50});

  Future<void> acceptEventInvite(String participantId);

  Future<void> declineEventInvite(String participantId);

  Future<void> respondProjectInvite(String projectId, bool accepted);

  Future<void> markAsRead(String notificationId);
}
