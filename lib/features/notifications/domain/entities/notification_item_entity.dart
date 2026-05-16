import 'package:equatable/equatable.dart';

import 'notification_type.dart';

class NotificationItemEntity extends Equatable {
  final String id;
  final NotificationType type;
  final String userId;
  final String title;
  final String message;
  final String? eventParticipantId;
  final String? dataJson;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationItemEntity({
    required this.id,
    required this.type,
    required this.userId,
    required this.title,
    required this.message,
    required this.eventParticipantId,
    required this.dataJson,
    required this.isRead,
    required this.createdAt,
    required this.readAt,
  });

  bool get canRespondToInvite =>
      type == NotificationType.eventInvite &&
      eventParticipantId != null &&
      eventParticipantId!.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    type,
    userId,
    title,
    message,
    eventParticipantId,
    dataJson,
    isRead,
    createdAt,
    readAt,
  ];
}
