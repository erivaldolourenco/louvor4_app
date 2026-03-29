import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:louvor4_app/features/user_profile/data/user_repository.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/user_detail_entity.dart';

import '../../data/events_repository.dart';
import '../../domain/entities/event_participant_entity.dart';
import '../../domain/entities/project_member_entity.dart';
import '../../domain/entities/event_song_entity.dart';
import '../../domain/entities/skill_entity.dart';
import 'event_detail_state.dart';

class EventDetailCubit extends Cubit<EventDetailState> {
  final EventsRepository _repository;
  final UserRepository _userRepository;
  UserDetailEntity? _currentUser;
  List<ProjectMemberEntity> _projectMembers = const [];

  EventDetailCubit(this._repository, this._userRepository)
    : super(const EventDetailState());

  Future<void> load(String eventId) async {
    emit(state.copyWith(status: EventDetailStatus.loading));

    try {
      final event = await _repository.getEventDetail(eventId);
      final participants = await _safeLoad(
        () => _repository.getEventParticipants(eventId),
        fallback: const <EventParticipant>[],
        debugLabel: 'participantes do evento',
      );
      final songs = await _safeLoad(
        () => _repository.getEventSongs(eventId),
        fallback: const <EventSong>[],
        debugLabel: 'músicas do evento',
      );

      final hasProjectId = event.projectId.trim().isNotEmpty;
      final skillsList = hasProjectId
          ? await _safeLoad(
              () => _repository.getProjectSkills(event.projectId),
              fallback: const <SkillEntity>[],
              debugLabel: 'skills do projeto',
            )
          : const <SkillEntity>[];
      final role = hasProjectId
          ? await _safeLoad(
              () => _repository.getProjectMemberRole(event.projectId),
              fallback: '',
              debugLabel: 'permissão do projeto',
            )
          : '';
      final projectMembers = hasProjectId
          ? await _safeLoad(
              () => _repository.getProjectMembers(event.projectId),
              fallback: const <ProjectMemberEntity>[],
              debugLabel: 'membros do projeto',
            )
          : const <ProjectMemberEntity>[];
      final currentUser = await _safeLoad(
        () => _userRepository.getUserDetail(),
        fallback: null,
        debugLabel: 'usuário atual',
      );

      _projectMembers = projectMembers;
      _currentUser = currentUser;
      final isProjectAdmin =
          role.toUpperCase() == 'ADMIN' || role.toUpperCase() == 'OWNER';
      emit(
        state.copyWith(
          status: EventDetailStatus.success,
          event: event,
          participants: participants,
          songs: songs,
          skillsMap: _buildSkillsMap(skillsList),
          isProjectAdmin: isProjectAdmin,
          canAddSongs: _canCurrentUserAddSongs(
            isProjectAdmin: isProjectAdmin,
            projectMembers: projectMembers,
            participants: participants,
            currentUser: currentUser,
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EventDetailStatus.failure,
          errorMessage: 'Não foi possível carregar os detalhes do evento.',
        ),
      );
    }
  }

  Future<T> _safeLoad<T>(
    Future<T> Function() loader, {
    required T fallback,
    required String debugLabel,
  }) async {
    try {
      return await loader();
    } catch (e) {
      if (kDebugMode) {
        print('Falha ao carregar $debugLabel: $e');
      }
      return fallback;
    }
  }

  Future<void> refreshParticipants() async {
    final event = state.event;
    if (event == null) return;

    try {
      final results = await Future.wait([
        _repository.getEventParticipants(event.id),
        _repository.getProjectSkills(event.projectId),
      ]);

      final participants = results[0] as List<EventParticipant>;
      final skills = results[1] as List<SkillEntity>;
      final isProjectAdmin = state.isProjectAdmin;
      emit(
        state.copyWith(
          participants: participants,
          skillsMap: _buildSkillsMap(skills),
          canAddSongs: _canCurrentUserAddSongs(
            isProjectAdmin: isProjectAdmin,
            projectMembers: _projectMembers,
            participants: participants,
            currentUser: _currentUser,
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Falha ao recarregar participantes: $e');
      }
    }
  }

  Future<void> refreshSongs() async {
    final event = state.event;
    if (event == null) return;

    try {
      final songs = await _repository.getEventSongs(event.id);
      emit(state.copyWith(songs: songs));
    } catch (e) {
      if (kDebugMode) {
        print('Falha ao recarregar músicas: $e');
      }
    }
  }

  Future<bool> removeSong(String eventSongId) async {
    final event = state.event;
    if (event == null) return false;

    emit(
      state.copyWith(
        deletingSongId: eventSongId,
        clearActionErrorMessage: true,
      ),
    );

    try {
      await _repository.removeSongFromEvent(event.id, eventSongId);
      emit(
        state.copyWith(
          songs: state.songs.where((song) => song.id != eventSongId).toList(),
          clearDeletingSongId: true,
          clearActionErrorMessage: true,
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          actionErrorMessage: e.toString().replaceFirst('Exception: ', ''),
          clearDeletingSongId: true,
        ),
      );
      return false;
    }
  }

  Map<String, String> _buildSkillsMap(List<SkillEntity> skills) {
    return {for (final skill in skills) skill.id: skill.name};
  }

  bool _canCurrentUserAddSongs({
    required bool isProjectAdmin,
    required List<ProjectMemberEntity> projectMembers,
    required List<EventParticipant> participants,
    required UserDetailEntity? currentUser,
  }) {
    if (isProjectAdmin) return true;

    final currentUserId = currentUser?.id?.trim();
    if (currentUserId == null || currentUserId.isEmpty) return false;

    final matchingProjectMembers = projectMembers.where((member) {
      return member.userId == currentUserId || member.id == currentUserId;
    }).toList();

    return participants.any((participant) {
      if (!participant.permissions.contains(EventPermission.addSong)) {
        return false;
      }

      if (participant.memberId == currentUserId) {
        return true;
      }

      return matchingProjectMembers.any(
        (member) =>
            participant.memberId == member.id ||
            participant.memberId == member.userId,
      );
    });
  }
}
