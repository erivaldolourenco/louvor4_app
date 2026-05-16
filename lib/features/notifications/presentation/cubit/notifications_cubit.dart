import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/notifications_repository.dart';
import '../../domain/entities/notification_item_entity.dart';
import '../../domain/entities/notifications_page_entity.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repository;

  NotificationsCubit(this._repository) : super(const NotificationsState());

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) {
      emit(
        state.copyWith(
          status: NotificationsStatus.loading,
          clearErrorMessage: true,
        ),
      );
    }

    try {
      final results = await Future.wait([
        _repository.getNotifications(page: 0, size: state.pageSize),
        _repository.getUnreadNotificationsCount(),
      ]);

      final page = results[0] as NotificationsPageEntity;
      final unreadCount = results[1] as int;

      emit(
        state.copyWith(
          status: NotificationsStatus.success,
          notifications: page.items,
          unreadCount: unreadCount,
          currentPage: page.page,
          pageSize: page.size,
          hasReachedLastPage: page.last,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          errorMessage: _extractMessage(
            error,
            fallback: 'Não foi possível carregar seus avisos.',
          ),
        ),
      );
    }
  }

  Future<void> refresh() => load(showLoading: false);

  Future<void> loadMore() async {
    if (state.status != NotificationsStatus.success ||
        state.isLoadingMore ||
        state.hasReachedLastPage) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true, clearErrorMessage: true));

    try {
      final nextPage = state.currentPage + 1;
      final page = await _repository.getNotifications(
        page: nextPage,
        size: state.pageSize,
      );

      emit(
        state.copyWith(
          status: NotificationsStatus.success,
          notifications: [...state.notifications, ...page.items],
          currentPage: page.page,
          hasReachedLastPage: page.last,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: _extractMessage(
            error,
            fallback: 'Não foi possível carregar mais avisos.',
          ),
        ),
      );
    }
  }

  Future<void> acceptInvite(NotificationItemEntity notification) async {
    final participantId = notification.eventParticipantId;
    if (participantId == null || participantId.isEmpty) return;

    emit(
      state.copyWith(
        actionStatus: NotificationsActionStatus.accepting,
        activeNotificationId: notification.id,
        clearActionMessage: true,
      ),
    );

    try {
      await _repository.acceptEventInvite(participantId);
      emit(
        state.copyWith(
          actionStatus: NotificationsActionStatus.success,
          actionMessage: 'Convite aceito com sucesso.',
          clearActiveNotificationId: true,
        ),
      );
      await load(showLoading: false);
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: NotificationsActionStatus.failure,
          actionMessage: _extractMessage(
            error,
            fallback: 'Não foi possível aceitar o convite.',
          ),
          clearActiveNotificationId: true,
        ),
      );
    }
  }

  Future<void> declineInvite(NotificationItemEntity notification) async {
    final participantId = notification.eventParticipantId;
    if (participantId == null || participantId.isEmpty) return;

    emit(
      state.copyWith(
        actionStatus: NotificationsActionStatus.declining,
        activeNotificationId: notification.id,
        clearActionMessage: true,
      ),
    );

    try {
      await _repository.declineEventInvite(participantId);
      emit(
        state.copyWith(
          actionStatus: NotificationsActionStatus.success,
          actionMessage: 'Convite recusado.',
          clearActiveNotificationId: true,
        ),
      );
      await load(showLoading: false);
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: NotificationsActionStatus.failure,
          actionMessage: _extractMessage(
            error,
            fallback: 'Não foi possível recusar o convite.',
          ),
          clearActiveNotificationId: true,
        ),
      );
    }
  }

  Future<void> dismissNotification(NotificationItemEntity notification) async {
    if (notification.canRespondToInvite) return;

    emit(
      state.copyWith(
        actionStatus: NotificationsActionStatus.dismissing,
        activeNotificationId: notification.id,
        clearActionMessage: true,
      ),
    );

    try {
      await _repository.markAsRead(notification.id);

      final updatedNotifications = state.notifications
          .where((item) => item.id != notification.id)
          .toList(growable: false);
      final nextUnreadCount = notification.isRead
          ? state.unreadCount
          : (state.unreadCount > 0 ? state.unreadCount - 1 : 0);

      emit(
        state.copyWith(
          status: updatedNotifications.isEmpty
              ? NotificationsStatus.success
              : state.status,
          notifications: updatedNotifications,
          unreadCount: nextUnreadCount,
          actionStatus: NotificationsActionStatus.success,
          actionMessage: 'Notificação removida.',
          clearActiveNotificationId: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: NotificationsActionStatus.failure,
          actionMessage: _extractMessage(
            error,
            fallback: 'Não foi possível fechar a notificação.',
          ),
          clearActiveNotificationId: true,
        ),
      );
    }
  }

  String _extractMessage(Object error, {required String fallback}) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) return fallback;
    return message;
  }
}
