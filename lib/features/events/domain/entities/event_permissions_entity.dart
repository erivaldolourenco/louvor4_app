import 'event_participant_entity.dart';

class EventPermissionsEntity {
  final bool isProjectAdmin;
  final Set<EventPermission> permissions;

  const EventPermissionsEntity({
    required this.isProjectAdmin,
    required this.permissions,
  });

  factory EventPermissionsEntity.fromJson(Map<String, dynamic> json) {
    final permissions = (json['permissions'] as List? ?? [])
        .map(parseEventPermission)
        .whereType<EventPermission>()
        .toSet();

    return EventPermissionsEntity(
      isProjectAdmin: json['isProjectAdmin'] as bool? ?? false,
      permissions: permissions,
    );
  }

  bool has(EventPermission permission) =>
      isProjectAdmin || permissions.contains(permission);
}
