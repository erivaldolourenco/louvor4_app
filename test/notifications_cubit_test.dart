import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/notifications/data/repositories/notifications_repository.dart';
import 'package:louvor4_app/features/notifications/domain/entities/notification_item_entity.dart';
import 'package:louvor4_app/features/notifications/domain/entities/notification_type.dart';
import 'package:louvor4_app/features/notifications/domain/entities/notifications_page_entity.dart';
import 'package:louvor4_app/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:louvor4_app/features/notifications/presentation/cubit/notifications_state.dart';

class _FakeNotificationsRepository implements NotificationsRepository {
  final Map<int, NotificationsPageEntity> pages;
  int unreadCount;
  int listCalls = 0;
  String? acceptedParticipantId;
  String? declinedParticipantId;

  _FakeNotificationsRepository({
    required this.pages,
    required this.unreadCount,
  });

  @override
  Future<void> acceptEventInvite(String participantId) async {
    acceptedParticipantId = participantId;
    unreadCount = 0;
  }

  @override
  Future<void> declineEventInvite(String participantId) async {
    declinedParticipantId = participantId;
    unreadCount = 0;
  }

  @override
  Future<NotificationsPageEntity> getNotifications({
    required int page,
    required int size,
  }) async {
    listCalls += 1;
    return pages[page]!;
  }

  @override
  Future<int> getUnreadNotificationsCount({int pageSize = 50}) async {
    return unreadCount;
  }

  @override
  Future<void> markAsRead(String notificationId) async {}
}

void main() {
  group('NotificationsCubit', () {
    test(
      'carrega notificações iniciais e atualiza badge de não lidas',
      () async {
        final repo = _FakeNotificationsRepository(
          unreadCount: 3,
          pages: {
            0: NotificationsPageEntity(
              items: [
                _notification(
                  id: 'n1',
                  type: NotificationType.eventInvite,
                  isRead: false,
                  participantId: 'p1',
                ),
                _notification(
                  id: 'n2',
                  type: NotificationType.systemNotification,
                  isRead: true,
                ),
              ],
              page: 0,
              size: 20,
              totalElements: 2,
              totalPages: 1,
              first: true,
              last: true,
            ),
          },
        );

        final cubit = NotificationsCubit(repo);
        await cubit.load();

        expect(cubit.state.status, NotificationsStatus.success);
        expect(cubit.state.notifications, hasLength(2));
        expect(cubit.state.unreadCount, 3);
        expect(cubit.state.hasReachedLastPage, isTrue);

        await cubit.close();
      },
    );

    test('aceita convite, recarrega lista e badge', () async {
      final initialInvite = _notification(
        id: 'invite-1',
        type: NotificationType.eventInvite,
        isRead: false,
        participantId: 'participant-1',
      );
      final updatedNotification = _notification(
        id: 'invite-1',
        type: NotificationType.eventParticipantAccepted,
        isRead: true,
      );

      final repo = _FakeNotificationsRepository(
        unreadCount: 1,
        pages: {
          0: NotificationsPageEntity(
            items: [initialInvite],
            page: 0,
            size: 20,
            totalElements: 1,
            totalPages: 1,
            first: true,
            last: true,
          ),
        },
      );

      final cubit = NotificationsCubit(repo);
      await cubit.load();

      repo.pages[0] = NotificationsPageEntity(
        items: [updatedNotification],
        page: 0,
        size: 20,
        totalElements: 1,
        totalPages: 1,
        first: true,
        last: true,
      );

      await cubit.acceptInvite(initialInvite);

      expect(repo.acceptedParticipantId, 'participant-1');
      expect(
        cubit.state.notifications.single.type,
        NotificationType.eventParticipantAccepted,
      );
      expect(cubit.state.unreadCount, 0);
      expect(cubit.state.actionStatus, NotificationsActionStatus.success);

      await cubit.close();
    });
  });
}

NotificationItemEntity _notification({
  required String id,
  required NotificationType type,
  required bool isRead,
  String? participantId,
}) {
  return NotificationItemEntity(
    id: id,
    type: type,
    userId: 'user-1',
    title: 'Aviso',
    message: 'Mensagem',
    eventParticipantId: participantId,
    dataJson: null,
    isRead: isRead,
    createdAt: DateTime(2026, 3, 31, 10),
    readAt: isRead ? DateTime(2026, 3, 31, 11) : null,
  );
}
