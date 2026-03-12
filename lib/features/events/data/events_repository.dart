import 'package:louvor4_app/features/songs/domain/entities/song_entity.dart';

import 'package:louvor4_app/features/events/domain/entities/skill_entity.dart';

import '../domain/entities/event_detail_entity.dart';
import '../domain/entities/event_participant_input_entity.dart';
import '../domain/entities/event_song_input_entity.dart';
import '../domain/entities/event_entity.dart';
import '../domain/entities/event_participant_entity.dart';
import '../domain/entities/event_song_entity.dart';
import '../domain/entities/project_member_entity.dart';
import '../domain/entities/update_event_input_entity.dart';

abstract class EventsRepository {
  Future<List<EventEntity>> getEvents();

  Future<EventDetailEntity> getEventDetail(String eventId);

  Future<List<EventParticipant>> getEventParticipants(String eventId);

  Future<List<EventSong>> getEventSongs(String eventId);

  Future<List<SongEntity>> getUserSongs();

  Future<List<SkillEntity>> getProjectSkills(String projectId);

  Future<List<ProjectMemberEntity>> getProjectMembers(String projectId);

  Future<ProjectMemberEntity> getProjectMember(
    String projectId,
    String memberId,
  );

  Future<String> getProjectMemberRole(String projectId);

  Future<void> saveEventParticipants(
    String eventId,
    List<EventParticipantInputEntity> participants,
  );

  Future<void> addSongsToEvent(
    String eventId,
    List<EventSongInputEntity> songs,
  );

  Future<void> removeSongFromEvent(String eventId, String eventSongId);

  Future<void> updateEvent(String eventId, UpdateEventInputEntity input);
}
