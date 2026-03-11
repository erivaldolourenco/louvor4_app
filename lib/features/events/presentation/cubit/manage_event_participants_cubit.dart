import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/events_repository.dart';
import '../../domain/entities/event_participant_entity.dart';
import '../../domain/entities/event_participant_input_entity.dart';
import '../../domain/entities/project_member_entity.dart';
import '../models/selectable_event_member.dart';
import 'manage_event_participants_state.dart';

class ManageEventParticipantsCubit extends Cubit<ManageEventParticipantsState> {
  final EventsRepository _repository;

  ManageEventParticipantsCubit(this._repository)
    : super(const ManageEventParticipantsState());

  Future<void> load({
    required String eventId,
    required String projectId,
  }) async {
    emit(
      state.copyWith(
        status: ManageEventParticipantsStatus.loading,
        clearErrorMessage: true,
      ),
    );

    try {
      final results = await Future.wait([
        _repository.getProjectMembers(projectId),
        _repository.getEventParticipants(eventId),
        _repository.getProjectSkills(projectId),
      ]);

      final projectMembers = results[0] as List<ProjectMemberEntity>;
      final eventParticipants = results[1] as List<EventParticipant>;
      final projectSkills = results[2] as List;
      final Map<String, String> skillsMap = {
        for (final skill in projectSkills)
          skill.id.toString(): skill.name.toString(),
      };
      final selectedMembers = _mergeMembers(projectMembers, eventParticipants);

      emit(
        state.copyWith(
          status: ManageEventParticipantsStatus.ready,
          members: selectedMembers,
          skillsMap: skillsMap,
          clearErrorMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ManageEventParticipantsStatus.failure,
          errorMessage: 'Não foi possível carregar os membros do projeto.',
        ),
      );
    }
  }

  void toggleMember(String memberId, bool selected) {
    emit(
      state.copyWith(
        status: _effectiveReadyStatus(),
        members: state.members.map((item) {
          if (item.member.id != memberId) return item;
          return item.copyWith(isSelected: selected);
        }).toList(),
        clearErrorMessage: true,
      ),
    );
  }

  void updateSkill(String memberId, String? skillId) {
    emit(
      state.copyWith(
        status: _effectiveReadyStatus(),
        members: state.members.map((item) {
          if (item.member.id != memberId) return item;
          return item.copyWith(
            selectedSkillId: (skillId == null || skillId.isEmpty)
                ? null
                : skillId,
          );
        }).toList(),
        clearErrorMessage: true,
      ),
    );
  }

  void togglePermission(
    String memberId,
    EventPermission permission,
    bool enabled,
  ) {
    emit(
      state.copyWith(
        status: _effectiveReadyStatus(),
        members: state.members.map((item) {
          if (item.member.id != memberId) return item;

          final updatedPermissions = Set<EventPermission>.from(
            item.permissions,
          );
          if (enabled) {
            updatedPermissions.add(permission);
          } else {
            updatedPermissions.remove(permission);
          }

          return item.copyWith(permissions: updatedPermissions);
        }).toList(),
        clearErrorMessage: true,
      ),
    );
  }

  Future<bool> submit(String eventId) async {
    final payload = state.members
        .where(
          (item) =>
              item.isSelected && (item.selectedSkillId?.isNotEmpty ?? false),
        )
        .map(
          (item) => EventParticipantInputEntity(
            memberId: item.member.id,
            skillId: item.selectedSkillId!,
            permissions: item.permissions
                .map((permission) => permission.name)
                .toList(),
          ),
        )
        .toList();

    emit(
      state.copyWith(
        status: ManageEventParticipantsStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    try {
      await _repository.saveEventParticipants(eventId, payload);
      emit(
        state.copyWith(
          status: ManageEventParticipantsStatus.success,
          clearErrorMessage: true,
        ),
      );
      return true;
    } catch (_) {
      emit(
        state.copyWith(
          status: ManageEventParticipantsStatus.failure,
          errorMessage: 'Não foi possível salvar a escala do evento.',
        ),
      );
      return false;
    }
  }

  List<SelectableEventMember> _mergeMembers(
    List<ProjectMemberEntity> members,
    List<EventParticipant> participants,
  ) {
    final participantsByMemberId = {
      for (final participant in participants) participant.memberId: participant,
    };

    final merged = members.map((member) {
      final participant = participantsByMemberId[member.id];
      final skillId = participant?.skillId;
      final hasSkill = member.skills.any((skill) => skill.id == skillId);

      return SelectableEventMember(
        member: member,
        isSelected: participant != null,
        selectedSkillId: hasSkill ? skillId : null,
        permissions: participant?.permissions ?? <EventPermission>{},
      );
    }).toList();

    merged.sort((a, b) {
      if (a.isSelected != b.isSelected) {
        return a.isSelected ? -1 : 1;
      }
      return a.member.fullName.toLowerCase().compareTo(
        b.member.fullName.toLowerCase(),
      );
    });

    return merged;
  }

  ManageEventParticipantsStatus _effectiveReadyStatus() {
    return state.status == ManageEventParticipantsStatus.failure
        ? ManageEventParticipantsStatus.ready
        : state.status;
  }
}
