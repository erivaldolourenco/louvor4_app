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
  static const Duration _cacheDuration = Duration(minutes: 10);
  static final Map<String, _CachedEventDetailData> _cacheByEventId = {};

  final EventsRepository _repository;
  final UserRepository _userRepository;
  UserDetailEntity? _currentUser;
  List<ProjectMemberEntity> _projectMembers = const [];

  EventDetailCubit(this._repository, this._userRepository)
    : super(const EventDetailState());

  Future<void> load(String eventId, {bool force = false}) async {
    // Emite loading imediatamente para que a tela mostre o skeleton enquanto
    // busca os dados, evitando exibir a tela de erro/vazio antes do carregamento.
    emit(state.copyWith(status: EventDetailStatus.loading));

    // Carrega o usuário primeiro para validar se o cache pertence a ele.
    // Isso evita que um usuário veja dados em cache de outro (ex: admin → não-admin).
    final currentUser = await _safeLoad(
      () => _userRepository.getUserDetail(),
      fallback: null,
      debugLabel: 'usuário atual',
    );

    final cached = !force ? _cacheByEventId[eventId] : null;
    if (cached != null &&
        !cached.isExpired &&
        cached.currentUser?.id == currentUser?.id) {
      _projectMembers = cached.projectMembers;
      _currentUser = cached.currentUser;
      emit(cached.state);
      return;
    }

    try {
      final event = await _repository.getEventDetail(eventId);
      bool participantsFailed = false;
      bool songsFailed = false;

      final participants = await _safeLoad(
        () => _repository.getEventParticipants(eventId),
        fallback: const <EventParticipant>[],
        debugLabel: 'participantes do evento',
        onError: () => participantsFailed = true,
      );
      final songs = await _safeLoad(
        () => _repository.getEventSongs(eventId),
        fallback: const <EventSong>[],
        debugLabel: 'músicas do evento',
        onError: () => songsFailed = true,
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

      _projectMembers = projectMembers;
      _currentUser = currentUser;
      final isProjectAdmin =
          role.toUpperCase() == 'ADMIN' || role.toUpperCase() == 'OWNER';
      final nextState = state.copyWith(
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
        currentUserId: currentUser?.id,
        participantsLoadFailed: participantsFailed,
        songsLoadFailed: songsFailed,
      );
      emit(nextState);
      _cacheByEventId[eventId] = _CachedEventDetailData(
        state: nextState,
        currentUser: currentUser,
        projectMembers: projectMembers,
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
    VoidCallback? onError,
  }) async {
    try {
      return await loader();
    } catch (e) {
      if (kDebugMode) {
        print('Falha ao carregar $debugLabel: $e');
      }
      onError?.call();
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
      final nextState = state.copyWith(
        participants: participants,
        skillsMap: _buildSkillsMap(skills),
        canAddSongs: _canCurrentUserAddSongs(
          isProjectAdmin: isProjectAdmin,
          projectMembers: _projectMembers,
          participants: participants,
          currentUser: _currentUser,
        ),
      );
      emit(nextState);
      _writeCache(event.id, nextState);
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
      final nextState = state.copyWith(songs: songs);
      emit(nextState);
      _writeCache(event.id, nextState);
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
      final nextState = state.copyWith(
        songs: state.songs.where((song) => song.id != eventSongId).toList(),
        clearDeletingSongId: true,
        clearActionErrorMessage: true,
      );
      emit(nextState);
      _writeCache(event.id, nextState);
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

  Future<bool> acceptParticipantInvite(String participantId) async {
    if (participantId.trim().isEmpty) return false;

    emit(state.copyWith(clearActionErrorMessage: true));

    try {
      await _repository.acceptEventParticipant(participantId);
      await refreshParticipants();
      emit(state.copyWith(clearActionErrorMessage: true));
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          actionErrorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }

  Future<bool> declineParticipantInvite(String participantId) async {
    if (participantId.trim().isEmpty) return false;

    emit(state.copyWith(clearActionErrorMessage: true));

    try {
      await _repository.declineEventParticipant(participantId);
      await refreshParticipants();
      emit(state.copyWith(clearActionErrorMessage: true));
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          actionErrorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }

  bool isCurrentUserParticipant(EventParticipant participant) {
    final currentUserId = _currentUser?.id?.trim();
    if (currentUserId == null || currentUserId.isEmpty) {
      return false;
    }

    if (participant.userId == currentUserId) {
      return true;
    }

    if (participant.memberId == currentUserId) {
      return true;
    }

    return _projectMembers.any(
      (member) =>
          member.userId == currentUserId &&
          (participant.memberId == member.id ||
              participant.memberId == member.userId),
    );
  }

  Map<String, String> _buildSkillsMap(List<SkillEntity> skills) {
    return {for (final skill in skills) skill.id: skill.name};
  }

  void _writeCache(String eventId, EventDetailState nextState) {
    _cacheByEventId[eventId] = _CachedEventDetailData(
      state: nextState,
      currentUser: _currentUser,
      projectMembers: _projectMembers,
    );
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

class _CachedEventDetailData {
  final EventDetailState state;
  final UserDetailEntity? currentUser;
  final List<ProjectMemberEntity> projectMembers;
  final DateTime createdAt;

  _CachedEventDetailData({
    required this.state,
    required this.currentUser,
    required this.projectMembers,
  }) : createdAt = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(createdAt) >= EventDetailCubit._cacheDuration;
}
