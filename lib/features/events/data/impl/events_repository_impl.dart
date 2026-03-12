import 'package:dio/dio.dart';
import 'package:louvor4_app/features/events/domain/entities/skill_entity.dart';
import 'package:louvor4_app/features/songs/domain/entities/song_entity.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/event_detail_entity.dart';
import '../../domain/entities/event_participant_input_entity.dart';
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
    final response = await _dio.get('/events/$eventId/songs');
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
  Future<String> getProjectMemberRole(String projectId) async {
    final response = await _dio.get('/music-project/$projectId/member-role');
    final data = response.data;

    if (data is String) {
      return data.toUpperCase();
    }

    if (data is Map<String, dynamic>) {
      return (data['role'] ?? '').toString().toUpperCase();
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      return (map['role'] ?? '').toString().toUpperCase();
    }

    throw Exception('Resposta inválida ao buscar permissão do projeto.');
  }

  @override
  Future<void> saveEventParticipants(
    String eventId,
    List<EventParticipantInputEntity> participants,
  ) async {
    await _dio.post(
      '/events/$eventId/participants',
      data: participants.map((participant) => participant.toJson()).toList(),
    );
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
      await _dio.delete('/events/$eventId/songs/$eventSongId');
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

  String _extractApiErrorMessage(
    DioException error, {
    String fallback = 'Erro inesperado.',
  }) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['detail'] ?? data['message'] ?? data['details'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message = map['detail'] ?? map['message'] ?? map['details'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    return error.message ?? fallback;
  }
}
