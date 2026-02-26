import 'package:dio/dio.dart';
import 'package:louvor4_app/features/events/domain/entities/skill_entity.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/event_detail_entity.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/event_participant_entity.dart';
import '../../domain/entities/event_song_entity.dart';
import '../events_repository.dart';

class EventsRepositoryImpl implements EventsRepository {
  final Dio _dio;

  EventsRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  @override
  Future<List<EventEntity>> getEvents() async {
    final response = await _dio.get('/users/events');
    final list = response.data as List;
    return list.map((e) => EventEntity.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<EventDetailEntity> getEventDetail(String eventId) async {
    final response = await _dio.get('/events/$eventId');
    return EventDetailEntity.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<List<EventParticipant>> getEventParticipants(String eventId) async {
    final response = await _dio.get('/events/$eventId/participants');
    final list = response.data as List;
    return list.map((e) => EventParticipant.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<List<EventSong>> getEventSongs(String eventId) async {
    final response = await _dio.get('/events/$eventId/songs');
    final list = response.data as List;
    return list.map((e) => EventSong.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<List<SkillEntity>> getProjectSkills(String projectId) async {
    final response = await _dio.get('/music-project/$projectId/skills');
    final list = response.data as List;
    return list.map((e) => SkillEntity.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}
