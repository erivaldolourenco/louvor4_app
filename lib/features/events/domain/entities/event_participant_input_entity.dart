import 'package:equatable/equatable.dart';

class EventParticipantInputEntity extends Equatable {
  final String memberId;
  final String skillId;
  final List<String> permissions;

  const EventParticipantInputEntity({
    required this.memberId,
    required this.skillId,
    this.permissions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'skillId': skillId,
      'permissions': permissions,
    };
  }

  @override
  List<Object?> get props => [memberId, skillId, permissions];
}
