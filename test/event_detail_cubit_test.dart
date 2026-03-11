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
import 'package:louvor4_app/features/events/presentation/cubit/event_detail_cubit.dart';
import 'package:louvor4_app/features/events/presentation/cubit/event_detail_state.dart';
import 'package:louvor4_app/features/songs/domain/entities/song_entity.dart';
import 'package:louvor4_app/features/user_profile/data/user_repository.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/user_detail_entity.dart';

class _FakeEventsRepository implements EventsRepository {
  _FakeEventsRepository({
    required this.event,
    required this.initialParticipants,
    required this.refreshedParticipants,
    required this.initialSkills,
    required this.refreshedSkills,
    this.role = 'admin',
    this.projectMembers = const [],
    this.initialSongs = const [],
  });

  final EventDetailEntity event;
  final List<EventParticipant> initialParticipants;
  final List<EventParticipant> refreshedParticipants;
  final List<SkillEntity> initialSkills;
  final List<SkillEntity> refreshedSkills;
  final String role;
  final List<ProjectMemberEntity> projectMembers;
  final List<EventSong> initialSongs;
  int participantsCalls = 0;
  int skillsCalls = 0;
  String? removedSongId;

  @override
  Future<EventDetailEntity> getEventDetail(String eventId) async => event;

  @override
  Future<List<EventParticipant>> getEventParticipants(String eventId) async {
    participantsCalls += 1;
    return participantsCalls == 1 ? initialParticipants : refreshedParticipants;
  }

  @override
  Future<List<EventSong>> getEventSongs(String eventId) async => initialSongs;

  @override
  Future<List<SkillEntity>> getProjectSkills(String projectId) async {
    skillsCalls += 1;
    return skillsCalls == 1 ? initialSkills : refreshedSkills;
  }

  @override
  Future<String> getProjectMemberRole(String projectId) async => role;

  @override
  Future<List<EventEntity>> getEvents() async => throw UnimplementedError();

  @override
  Future<ProjectMemberEntity> getProjectMember(
    String projectId,
    String memberId,
  ) async => throw UnimplementedError();

  @override
  Future<List<ProjectMemberEntity>> getProjectMembers(String projectId) async =>
      projectMembers;

  @override
  Future<void> saveEventParticipants(
    String eventId,
    List<EventParticipantInputEntity> participants,
  ) async => throw UnimplementedError();

  @override
  Future<void> addSongsToEvent(
    String eventId,
    List<EventSongInputEntity> songs,
  ) async => throw UnimplementedError();

  @override
  Future<List<SongEntity>> getUserSongs() async => throw UnimplementedError();

  @override
  Future<void> removeSongFromEvent(String eventId, String eventSongId) async {
    removedSongId = eventSongId;
  }
}

class _FakeUserRepository implements UserRepository {
  @override
  Future<UserDetailEntity> getUserDetail() async {
    return UserDetailEntity(
      id: 'u1',
      firstName: 'Ana',
      lastName: 'Silva',
      email: 'ana@mail.com',
    );
  }

  @override
  Future<String> updateProfileImage({
    required String filePath,
    required String fileName,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  group('EventDetailCubit', () {
    test('recarrega participantes e atualiza skillsMap no refresh', () async {
      final repo = _FakeEventsRepository(
        event: EventDetailEntity(
          id: 'e1',
          projectId: 'p1',
          title: 'Culto',
          date: DateTime(2026, 3, 11),
          time: '19:00',
          projectTitle: 'Louvor',
          participantsCount: 1,
          repertoireCount: 0,
        ),
        initialParticipants: const [
          EventParticipant(
            memberId: 'm1',
            firstName: 'Ana',
            skillId: 's1',
            permissions: {},
          ),
        ],
        refreshedParticipants: const [
          EventParticipant(
            memberId: 'm1',
            firstName: 'Ana',
            skillId: 's2',
            permissions: {},
          ),
        ],
        initialSkills: const [SkillEntity(id: 's1', name: 'Vocal')],
        refreshedSkills: const [SkillEntity(id: 's2', name: 'Teclado')],
      );

      final cubit = EventDetailCubit(repo, _FakeUserRepository());

      await cubit.load('e1');
      expect(cubit.state.status, EventDetailStatus.success);
      expect(cubit.state.skillsMap['s1'], 'Vocal');

      await cubit.refreshParticipants();

      expect(cubit.state.participants.single.skillId, 's2');
      expect(cubit.state.skillsMap['s2'], 'Teclado');
      expect(cubit.state.skillsMap.containsKey('s1'), isFalse);

      await cubit.close();
    });

    test('remove música do repertório sem recarregar a tela inteira', () async {
      final repo = _FakeEventsRepository(
        event: EventDetailEntity(
          id: 'e1',
          projectId: 'p1',
          title: 'Culto',
          date: DateTime(2026, 3, 11),
          time: '19:00',
          projectTitle: 'Louvor',
          participantsCount: 1,
          repertoireCount: 2,
        ),
        initialParticipants: const [],
        refreshedParticipants: const [],
        initialSkills: const [],
        refreshedSkills: const [],
        initialSongs: const [
          EventSong(
            id: 'es1',
            title: 'Música 1',
            artist: 'Artista 1',
            key: 'G',
            bpm: 120,
            youTubeUrl: null,
            addedBy: 'u1',
          ),
          EventSong(
            id: 'es2',
            title: 'Música 2',
            artist: 'Artista 2',
            key: 'C',
            bpm: 100,
            youTubeUrl: null,
            addedBy: 'u1',
          ),
        ],
      );

      final cubit = EventDetailCubit(repo, _FakeUserRepository());

      await cubit.load('e1');
      final removed = await cubit.removeSong('es1');

      expect(removed, isTrue);
      expect(repo.removedSongId, 'es1');
      expect(cubit.state.songs, hasLength(1));
      expect(cubit.state.songs.single.id, 'es2');

      await cubit.close();
    });

    test('libera adicionar músicas para participante com permissão ADD_SONG', () async {
      final repo = _FakeEventsRepository(
        event: EventDetailEntity(
          id: 'e1',
          projectId: 'p1',
          title: 'Culto',
          date: DateTime(2026, 3, 11),
          time: '19:00',
          projectTitle: 'Louvor',
          participantsCount: 1,
          repertoireCount: 0,
        ),
        role: 'member',
        projectMembers: const [
          ProjectMemberEntity(
            id: 'm1',
            userId: 'u1',
            firstName: 'Ana',
          ),
        ],
        initialParticipants: const [
          EventParticipant(
            memberId: 'm1',
            firstName: 'Ana',
            skillId: 's1',
            permissions: {EventPermission.ADD_SONG},
          ),
        ],
        refreshedParticipants: const [],
        initialSkills: const [SkillEntity(id: 's1', name: 'Vocal')],
        refreshedSkills: const [],
      );

      final cubit = EventDetailCubit(repo, _FakeUserRepository());

      await cubit.load('e1');

      expect(cubit.state.isProjectAdmin, isFalse);
      expect(cubit.state.canAddSongs, isTrue);

      await cubit.close();
    });

    test('libera adicionar músicas quando participant.memberId vem como userId', () async {
      final repo = _FakeEventsRepository(
        event: EventDetailEntity(
          id: 'e1',
          projectId: 'p1',
          title: 'Culto',
          date: DateTime(2026, 3, 11),
          time: '19:00',
          projectTitle: 'Louvor',
          participantsCount: 1,
          repertoireCount: 0,
        ),
        role: 'member',
        projectMembers: const [
          ProjectMemberEntity(
            id: 'm1',
            userId: 'u1',
            firstName: 'Ana',
          ),
        ],
        initialParticipants: const [
          EventParticipant(
            memberId: 'u1',
            firstName: 'Ana',
            skillId: 's1',
            permissions: {EventPermission.ADD_SONG},
          ),
        ],
        refreshedParticipants: const [],
        initialSkills: const [SkillEntity(id: 's1', name: 'Vocal')],
        refreshedSkills: const [],
      );

      final cubit = EventDetailCubit(repo, _FakeUserRepository());

      await cubit.load('e1');

      expect(cubit.state.canAddSongs, isTrue);

      await cubit.close();
    });
  });
}
