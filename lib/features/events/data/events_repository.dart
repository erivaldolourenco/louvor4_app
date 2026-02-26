import '../domain/entities/event_detail_entity.dart';
import '../domain/entities/event_entity.dart';
import '../domain/entities/event_participant_entity.dart';
import '../domain/entities/event_song_entity.dart';

abstract class EventsRepository {
  Future<List<EventEntity>> getEvents();

  Future<EventDetailEntity> getEventDetail(String eventId);

  Future<List<EventParticipant>> getEventParticipants(String eventId);

  Future<List<EventSong>> getEventSongs(String eventId);
}
