import 'package:equatable/equatable.dart';

import '../../domain/entities/event_participant_entity.dart';
import '../../domain/entities/project_member_entity.dart';
import '../../domain/entities/skill_entity.dart';

class SelectableEventMember extends Equatable {
  final ProjectMemberEntity member;
  final bool isSelected;
  final String? selectedSkillId;
  final Set<EventPermission> permissions;

  const SelectableEventMember({
    required this.member,
    required this.isSelected,
    this.selectedSkillId,
    this.permissions = const {},
  });

  List<SkillEntity> get availableSkills => member.skills;

  SelectableEventMember copyWith({
    bool? isSelected,
    String? selectedSkillId,
    bool clearSelectedSkill = false,
    Set<EventPermission>? permissions,
  }) {
    return SelectableEventMember(
      member: member,
      isSelected: isSelected ?? this.isSelected,
      selectedSkillId: clearSelectedSkill
          ? null
          : (selectedSkillId ?? this.selectedSkillId),
      permissions: permissions ?? this.permissions,
    );
  }

  @override
  List<Object?> get props => [member, isSelected, selectedSkillId, permissions];
}
