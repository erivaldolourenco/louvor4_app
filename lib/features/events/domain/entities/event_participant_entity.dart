enum EventPermission {
  addSong, // pode adicionar música ao repertório
  editSetlist, // pode mudar ordem / tom / bpm
  removeSong, // pode remover música do repertório
  manageParticipants, // pode adicionar/remover participantes
  editEvent,
  editChordSheet, // pode editar a cifra de músicas do evento marcadas como editáveis pelo dono
}

enum EventParticipantStatus { pending, accepted, declined, unknown }

extension EventParticipantStatusPresentation on EventParticipantStatus {
  String get label {
    switch (this) {
      case EventParticipantStatus.pending:
        return 'Pendente';
      case EventParticipantStatus.accepted:
        return 'Aceito';
      case EventParticipantStatus.declined:
        return 'Recusado';
      case EventParticipantStatus.unknown:
        return 'Sem status';
    }
  }
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
      case EventPermission.editChordSheet:
        return 'EDIT_CHORD_SHEET';
    }
  }
}

class EventParticipant {
  final String id;
  final String memberId;
  final String? userId;
  final String firstName;
  final String? lastName;
  final String? profileImage;
  final String skillId;
  final String? skillIconKey;
  final EventParticipantStatus status;
  final Set<EventPermission> permissions;

  const EventParticipant({
    this.id = '',
    required this.memberId,
    this.userId,
    required this.firstName,
    this.lastName,
    this.profileImage,
    required this.skillId,
    this.skillIconKey,
    this.status = EventParticipantStatus.accepted,
    required this.permissions,
  });

  String get fullName => '$firstName ${lastName ?? ''}'.trim();

  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    final user = _asMap(json['user']);
    final member = _asMap(json['member']);
    final memberUser = _asMap(member?['user']);
    final skill = _asMap(json['skill']);
    final permissions = (json['permissions'] as List? ?? [])
        .map(_parsePermission)
        .whereType<EventPermission>()
        .toSet();

    return EventParticipant(
      id: _firstNonEmpty([
        json['eventParticipantId'],
        json['participantId'],
        json['id'],
      ]),
      memberId: _firstNonEmpty([
        json['memberId'],
        json['projectMemberId'],
        member?['memberId'],
        member?['id'],
        json['id'],
      ]),
      userId: _firstNullable([
        json['userId'],
        user?['id'],
        member?['userId'],
        memberUser?['id'],
      ]),
      firstName: _firstNonEmpty([
        json['firstName'],
        member?['firstName'],
        user?['firstName'],
        memberUser?['firstName'],
      ]),
      lastName: _firstNullable([
        json['lastName'],
        member?['lastName'],
        user?['lastName'],
        memberUser?['lastName'],
      ]),
      profileImage: _firstNullable([
        json['profileImage'],
        json['imageUrl'],
        member?['profileImage'],
        member?['imageUrl'],
        user?['profileImage'],
        memberUser?['profileImage'],
      ]),
      skillId: _firstNonEmpty([
        json['skillId'],
        json['projectSkillId'],
        skill == null ? null : skill['id'],
      ]),
      skillIconKey: _firstNullable([
        json['skillIconKey'],
        skill == null ? null : skill['iconKey'],
      ]),
      status: _parseStatus(json['status']),
      permissions: permissions,
    );
  }

  static String? _readNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final normalized = _readNullableString(value);
      if (normalized != null) return normalized;
    }
    return '';
  }

  static String? _firstNullable(List<dynamic> values) {
    for (final value in values) {
      final normalized = _readNullableString(value);
      if (normalized != null) return normalized;
    }
    return null;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static EventParticipantStatus _parseStatus(dynamic value) {
    final normalized = value?.toString().trim().toUpperCase();
    switch (normalized) {
      case 'PENDING':
        return EventParticipantStatus.pending;
      case 'ACCEPTED':
        return EventParticipantStatus.accepted;
      case 'DECLINED':
        return EventParticipantStatus.declined;
      default:
        return EventParticipantStatus.unknown;
    }
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
      case 'EDIT_CHORD_SHEET':
      case 'EDITCHORDSHEET':
        return EventPermission.editChordSheet;
      default:
        return null;
    }
  }
}
