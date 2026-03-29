enum EventPermission {
  addSong, // pode adicionar música ao repertório
  editSetlist, // pode mudar ordem / tom / bpm
  removeSong, // pode remover música do repertório
  manageParticipants, // pode adicionar/remover participantes
  editEvent,
}

extension EventPermissionApiValue on EventPermission {
  String get apiValue {
    switch (this) {
      case EventPermission.addSong:
        return 'ADD_SONG';
      case EventPermission.editSetlist:
        return 'EDIT_SETLIST';
      case EventPermission.removeSong:
        return 'REMOVE_SONG';
      case EventPermission.manageParticipants:
        return 'MANAGE_PARTICIPANTS';
      case EventPermission.editEvent:
        return 'EDIT_EVENT';
    }
  }
}

class EventParticipant {
  final String memberId;
  final String firstName;
  final String? lastName;
  final String? profileImage;
  final String skillId;
  final Set<EventPermission> permissions;

  const EventParticipant({
    required this.memberId,
    required this.firstName,
    this.lastName,
    this.profileImage,
    required this.skillId,
    required this.permissions,
  });

  String get fullName => '$firstName ${lastName ?? ''}'.trim();

  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    final permissions = (json['permissions'] as List? ?? [])
        .map(_parsePermission)
        .whereType<EventPermission>()
        .toSet();

    return EventParticipant(
      memberId: json['memberId'].toString(),
      firstName: json['firstName'].toString(),
      lastName: json['lastName']?.toString(),
      profileImage: json['profileImage']?.toString(),
      skillId: json['skillId'].toString(),
      permissions: permissions,
    );
  }

  static EventPermission? _parsePermission(dynamic value) {
    final normalized = value?.toString().trim();
    if (normalized == null || normalized.isEmpty) return null;

    switch (normalized.toUpperCase()) {
      case 'ADD_SONG':
      case 'ADDSONG':
        return EventPermission.addSong;
      case 'EDIT_SETLIST':
      case 'EDITSETLIST':
        return EventPermission.editSetlist;
      case 'REMOVE_SONG':
      case 'REMOVESONG':
        return EventPermission.removeSong;
      case 'MANAGE_PARTICIPANTS':
      case 'MANAGEPARTICIPANTS':
        return EventPermission.manageParticipants;
      case 'EDIT_EVENT':
      case 'EDITEVENT':
        return EventPermission.editEvent;
      default:
        return null;
    }
  }
}
