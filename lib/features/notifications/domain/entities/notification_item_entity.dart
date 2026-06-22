import 'dart:convert';

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

  /// projectId extraído de [dataJson], disponível apenas para notificações
  /// do tipo [NotificationType.projectMemberInvite].
  String? get projectInviteId {
    if (type != NotificationType.projectMemberInvite) return null;

    final raw = dataJson;
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final projectId = decoded['projectId'];
        if (projectId != null && projectId.toString().trim().isNotEmpty) {
          return projectId.toString();
        }
      }
    } catch (_) {
      // dataJson inválido ou em formato inesperado — sem ação a oferecer.
    }

    return null;
  }

  bool get canRespondToInvite {
    if (type == NotificationType.eventInvite) {
      return eventParticipantId != null && eventParticipantId!.isNotEmpty;
    }
    if (type == NotificationType.projectMemberInvite) {
      return projectInviteId != null;
    }
    return false;
  }

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
