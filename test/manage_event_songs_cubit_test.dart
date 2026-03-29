import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/events/data/events_repository.dart';
import 'package:louvor4_app/features/events/domain/entities/event_detail_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/event_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/event_participant_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/event_participant_input_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/event_song_input_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/event_song_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/project_member_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/skill_entity.dart';
import 'package:louvor4_app/features/events/presentation/cubit/manage_event_songs_cubit.dart';
import 'package:louvor4_app/features/events/presentation/cubit/manage_event_songs_state.dart';
import 'package:louvor4_app/features/songs/domain/entities/song_entity.dart';

class _FakeEventsRepository implements EventsRepository {
  _FakeEventsRepository({this.userSongs = const []});

  final List<SongEntity> userSongs;
  List<EventSongInputEntity> savedSongs = const [];

  @override
  Future<List<SongEntity>> getUserSongs() async => userSongs;

  @override
  Future<void> addSongsToEvent(
    String eventId,
    List<EventSongInputEntity> songs,
  ) async {
    savedSongs = songs;
  }

  @override
  Future<EventDetailEntity> getEventDetail(String eventId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<EventEntity>> getEvents() async {
    throw UnimplementedError();
  }

  @override
  Future<List<EventParticipant>> getEventParticipants(String eventId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<EventSong>> getEventSongs(String eventId) async {
    throw UnimplementedError();
  }

  @override
  Future<ProjectMemberEntity> getProjectMember(
    String projectId,
    String memberId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<String> getProjectMemberRole(String projectId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ProjectMemberEntity>> getProjectMembers(String projectId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<SkillEntity>> getProjectSkills(String projectId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> saveEventParticipants(
    String eventId,
    List<EventParticipantInputEntity> participants,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> removeSongFromEvent(String eventId, String eventSongId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateEvent(String eventId, dynamic input) async {
    throw UnimplementedError();
  }
}

void main() {
  group('ManageEventSongsCubit', () {
    test('carrega músicas do usuário e envia as selecionadas em lote', () async {
      final repo = _FakeEventsRepository(
        userSongs: const [
          SongEntity(
            id: 's1',
            artist: 'Elevation Worship',
            title: 'Graves Into Gardens',
            key: 'G',
            bpm: '128',
            youTubeUrl: 'https://www.youtube.com/watch?v=test1',
          ),
          SongEntity(
            id: 's2',
            artist: 'Hillsong',
            title: 'Oceans',
            key: 'C',
            bpm: '90',
            youTubeUrl: 'https://www.youtube.com/watch?v=test2',
          ),
        ],
      );

      final cubit = ManageEventSongsCubit(repo);

      await cubit.load();
      expect(cubit.state.status, ManageEventSongsStatus.loaded);
      expect(cubit.state.songs, hasLength(2));

      cubit.toggleSong('s1');
      cubit.toggleSong('s2');

      final saved = await cubit.submit('e1');

      expect(saved, isTrue);
      expect(cubit.state.status, ManageEventSongsStatus.success);
      expect(repo.savedSongs.map((song) => song.songId), ['s1', 's2']);

      await cubit.close();
    });
  });
}
