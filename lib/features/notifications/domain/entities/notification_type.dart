enum NotificationType {
  eventInvite,
  eventParticipantAccepted,
  eventParticipantDeclined,
  eventParticipantRemoved,
  eventUpdated,
  eventCancelled,
  eventReminder,
  eventSongAdded,
  eventSongRemoved,
  eventScheduleUpdated,
  projectMemberAdded,
  projectMemberRemoved,
  projectMemberInvite,
  projectMemberInviteAccepted,
  projectMemberInviteDeclined,
  messageReceived,
  systemNotification,
  unknown,
}

NotificationType notificationTypeFromString(String? value) {
  switch ((value ?? '').trim().toUpperCase()) {
    case 'EVENT_INVITE':
      return NotificationType.eventInvite;
    case 'EVENT_PARTICIPANT_ACCEPTED':
      return NotificationType.eventParticipantAccepted;
    case 'EVENT_PARTICIPANT_DECLINED':
      return NotificationType.eventParticipantDeclined;
    case 'EVENT_PARTICIPANT_REMOVED':
      return NotificationType.eventParticipantRemoved;
    case 'EVENT_UPDATED':
      return NotificationType.eventUpdated;
    case 'EVENT_CANCELLED':
      return NotificationType.eventCancelled;
    case 'EVENT_REMINDER':
      return NotificationType.eventReminder;
    case 'EVENT_SONG_ADDED':
      return NotificationType.eventSongAdded;
    case 'EVENT_SONG_REMOVED':
      return NotificationType.eventSongRemoved;
    case 'EVENT_SCHEDULE_UPDATED':
      return NotificationType.eventScheduleUpdated;
    case 'PROJECT_MEMBER_ADDED':
      return NotificationType.projectMemberAdded;
    case 'PROJECT_MEMBER_REMOVED':
      return NotificationType.projectMemberRemoved;
    case 'PROJECT_MEMBER_INVITE':
      return NotificationType.projectMemberInvite;
    case 'PROJECT_MEMBER_INVITE_ACCEPTED':
      return NotificationType.projectMemberInviteAccepted;
    case 'PROJECT_MEMBER_INVITE_DECLINED':
      return NotificationType.projectMemberInviteDeclined;
    case 'MESSAGE_RECEIVED':
      return NotificationType.messageReceived;
    case 'SYSTEM_NOTIFICATION':
      return NotificationType.systemNotification;
    default:
      return NotificationType.unknown;
  }
}
