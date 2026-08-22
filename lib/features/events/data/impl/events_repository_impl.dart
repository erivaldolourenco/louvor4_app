import 'package:dio/dio.dart';
import 'package:louvor4_app/features/events/domain/entities/skill_entity.dart';
import 'package:louvor4_app/features/songs/domain/entities/song_entity.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_message.dart';
import '../../domain/entities/event_detail_entity.dart';
import '../../domain/entities/event_participant_input_entity.dart';
import '../../domain/entities/event_permissions_entity.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/event_participant_entity.dart';
import '../../domain/entities/event_song_input_entity.dart';
import '../../domain/entities/event_song_entity.dart';
import '../../domain/entities/project_member_entity.dart';
import '../../domain/entities/update_event_input_entity.dart';
import '../events_repository.dart';

class EventsRepositoryImpl implements EventsRepository {
  final Dio _dio;

  EventsRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  @override
  Future<List<EventEntity>> getEvents() async {
    final response = await _dio.get('/users/events');
    final list = response.data as List;
    return list
        .map((e) => EventEntity.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<({List<EventEntity> events, bool hasMore})> getPastEvents(
    int page, {
    int size = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/users/events/past',
        queryParameters: {'page': page, 'size': size},
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final list = (data['content'] as List)
          .map(
            (e) => EventEntity.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      final isLast = data['last'] as bool? ?? true;
      return (events: list, hasMore: !isLast);
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Não foi possível carregar eventos passados.',
        ),
      );
    }
  }

  @override
  Future<EventDetailEntity> getEventDetail(String eventId) async {
    final response = await _dio.get('/events/$eventId');
    return EventDetailEntity.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<List<EventParticipant>> getEventParticipants(String eventId) async {
    final response = await _dio.get('/events/$eventId/participants');
    final list = response.data as List;
    return list
        .map(
          (e) => EventParticipant.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  @override
  Future<List<EventSong>> getEventSongs(String eventId) async {
    final response = await _dio.get('/events/$eventId/setlist');
    final list = response.data as List;
    return list
        .map((e) => EventSong.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<SongEntity>> getUserSongs() async {
    try {
      final response = await _dio.get('/users/songs');
      final list = response.data as List;
      return list
          .map(
            (item) =>
                SongEntity.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Não foi possível carregar suas músicas.',
        ),
      );
    }
  }

  @override
  Future<List<SkillEntity>> getProjectSkills(String projectId) async {
    final response = await _dio.get('/music-project/$projectId/skills');
    final list = response.data as List;
    return list
        .map((e) => SkillEntity.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<ProjectMemberEntity>> getProjectMembers(String projectId) async {
    final response = await _dio.get('/music-project/$projectId/members');
    final membersList = response.data as List;
    return membersList
        .map(
          (item) => ProjectMemberEntity.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<ProjectMemberEntity> getProjectMember(
    String projectId,
    String memberId,
  ) async {
    final response = await _dio.get(
      '/music-project/$projectId/members/$memberId',
    );
    return ProjectMemberEntity.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<EventPermissionsEntity> getMyEventPermissions(String eventId) async {
    try {
      final response = await _dio.get('/events/$eventId/me/permissions');
      return EventPermissionsEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Não foi possível carregar suas permissões no evento.',
        ),
      );
    }
  }

  @override
  Future<void> saveEventParticipants(
    String eventId,
    List<EventParticipantInputEntity> participants,
  ) async {
    try {
      await _dio.post(
        '/events/$eventId/participants',
        data: participants
            .map((participant) => participant.toJson())
            .toList(),
      );
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Não foi possível salvar os participantes do evento.',
        ),
      );
    }
  }

  @override
  Future<void> addSongsToEvent(
    String eventId,
    List<EventSongInputEntity> songs,
  ) async {
    try {
      await _dio.post(
        '/events/$eventId/songs',
        data: songs.map((song) => song.toJson()).toList(),
      );
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Não foi possível adicionar as músicas ao evento.',
        ),
      );
    }
  }

  @override
  Future<void> removeSongFromEvent(String eventId, String eventSongId) async {
    try {
      await _dio.delete('/events/$eventId/setlist/$eventSongId');
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(e, fallback: 'Erro ao remover música'),
      );
    }
  }

  @override
  Future<void> updateEvent(String eventId, UpdateEventInputEntity input) async {
    try {
      await _dio.put('/events/$eventId', data: input.toJson());
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Não foi possível atualizar o evento. Tente novamente.',
        ),
      );
    }
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    try {
      await _dio.delete('/events/$eventId');
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Não foi possível excluir o evento.',
        ),
      );
    }
  }

  @override
  Future<void> acceptEventParticipant(String participantId) async {
    try {
      await _dio.patch('/events/participants/$participantId/accept');
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Não foi possível aceitar a participação.',
        ),
      );
    }
  }

  @override
  Future<void> declineEventParticipant(String participantId) async {
    try {
      await _dio.patch('/events/participants/$participantId/decline');
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Não foi possível recusar a participação.',
        ),
      );
    }
  }

  String _extractApiErrorMessage(
    DioException error, {
    String fallback = 'Erro inesperado.',
  }) =>
      extractApiErrorMessage(error, fallback: fallback);
}
