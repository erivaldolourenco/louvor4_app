enum EventPermission {
  ADD_SONG, // pode adicionar música ao repertório
  EDIT_SETLIST, // pode mudar ordem / tom / bpm
  REMOVE_SONG, // pode remover música do repertório
  MANAGE_PARTICIPANTS, // pode adicionar/remover participantes
  EDIT_EVENT,
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
        .map((p) => EventPermission.values.byName(p.toString()))
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
}
