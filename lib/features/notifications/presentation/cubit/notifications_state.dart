import 'package:equatable/equatable.dart';

import '../../domain/entities/notification_item_entity.dart';

enum NotificationsStatus { initial, loading, success, failure }

enum NotificationsActionStatus {
  idle,
  accepting,
  declining,
  dismissing,
  success,
  failure,
}

class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final NotificationsActionStatus actionStatus;
  final List<NotificationItemEntity> notifications;
  final int unreadCount;
  final int currentPage;
  final int pageSize;
  final bool hasReachedLastPage;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? actionMessage;
  final String? activeNotificationId;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.actionStatus = NotificationsActionStatus.idle,
    this.notifications = const [],
    this.unreadCount = 0,
    this.currentPage = 0,
    this.pageSize = 20,
    this.hasReachedLastPage = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.actionMessage,
    this.activeNotificationId,
  });

  bool get isInitialLoading =>
      status == NotificationsStatus.loading && notifications.isEmpty;

  bool get isEmpty =>
      status == NotificationsStatus.success && notifications.isEmpty;

  bool isAccepting(String notificationId) {
    return activeNotificationId == notificationId &&
        actionStatus == NotificationsActionStatus.accepting;
  }

  bool isDeclining(String notificationId) {
    return activeNotificationId == notificationId &&
        actionStatus == NotificationsActionStatus.declining;
  }

  bool isDismissing(String notificationId) {
    return activeNotificationId == notificationId &&
        actionStatus == NotificationsActionStatus.dismissing;
  }

  NotificationsState copyWith({
    NotificationsStatus? status,
    NotificationsActionStatus? actionStatus,
    List<NotificationItemEntity>? notifications,
    int? unreadCount,
    int? currentPage,
    int? pageSize,
    bool? hasReachedLastPage,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionMessage,
    bool clearActionMessage = false,
    String? activeNotificationId,
    bool clearActiveNotificationId = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      hasReachedLastPage: hasReachedLastPage ?? this.hasReachedLastPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      actionMessage: clearActionMessage
          ? null
          : (actionMessage ?? this.actionMessage),
      activeNotificationId: clearActiveNotificationId
          ? null
          : (activeNotificationId ?? this.activeNotificationId),
    );
  }

  @override
  List<Object?> get props => [
    status,
    actionStatus,
    notifications,
    unreadCount,
    currentPage,
    pageSize,
    hasReachedLastPage,
    isLoadingMore,
    errorMessage,
    actionMessage,
    activeNotificationId,
  ];
}
