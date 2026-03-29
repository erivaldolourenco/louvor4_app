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
import 'package:louvor4_app/features/events/presentation/cubit/manage_event_participants_cubit.dart';
import 'package:louvor4_app/features/events/presentation/cubit/manage_event_participants_state.dart';
import 'package:louvor4_app/features/events/domain/entities/update_event_input_entity.dart';
import 'package:louvor4_app/features/songs/domain/entities/song_entity.dart';

class _FakeEventsRepository implements EventsRepository {
  _FakeEventsRepository({
    this.members = const [],
    this.participants = const [],
    this.skills = const [],
  });

  final List<ProjectMemberEntity> members;
  final List<EventParticipant> participants;
  final List<SkillEntity> skills;
  List<EventParticipantInputEntity> savedParticipants = const [];

  @override
  Future<List<ProjectMemberEntity>> getProjectMembers(String projectId) async {
    return members;
  }

  @override
  Future<ProjectMemberEntity> getProjectMember(
    String projectId,
    String memberId,
  ) async {
    return members.firstWhere((member) => member.id == memberId);
  }

  @override
  Future<List<EventParticipant>> getEventParticipants(String eventId) async {
    return participants;
  }

  @override
  Future<void> saveEventParticipants(
    String eventId,
    List<EventParticipantInputEntity> participants,
  ) async {
    savedParticipants = participants;
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
  Future<String> getProjectMemberRole(String projectId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<SkillEntity>> getProjectSkills(String projectId) async {
    return skills;
  }

  @override
  Future<List<EventSong>> getEventSongs(String eventId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> addSongsToEvent(
    String eventId,
    List<EventSongInputEntity> songs,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<List<SongEntity>> getUserSongs() async {
    throw UnimplementedError();
  }

  @override
  Future<void> removeSongFromEvent(String eventId, String eventSongId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateEvent(String eventId, UpdateEventInputEntity input) async {
    throw UnimplementedError();
  }
}

void main() {
  group('ManageEventParticipantsCubit', () {
    test(
      'pré-seleciona participantes já escalados e mantém skill/permissão',
      () async {
        final repo = _FakeEventsRepository(
          members: const [
            ProjectMemberEntity(
              id: 'm1',
              firstName: 'Ana',
              lastName: 'Silva',
              projectRole: 'Vocal',
              skills: [SkillEntity(id: 's1', name: 'Vocal')],
            ),
            ProjectMemberEntity(
              id: 'm2',
              firstName: 'João',
              lastName: 'Souza',
              projectRole: 'Violão',
              skills: [SkillEntity(id: 's2', name: 'Violão')],
            ),
          ],
          participants: const [
            EventParticipant(
              memberId: 'm2',
              firstName: 'João',
              lastName: 'Souza',
              profileImage: null,
              skillId: 's2',
              permissions: {EventPermission.addSong},
            ),
          ],
          skills: const [
            SkillEntity(id: 's1', name: 'Vocal'),
            SkillEntity(id: 's2', name: 'Violão'),
          ],
        );

        final cubit = ManageEventParticipantsCubit(repo);
        await cubit.load(eventId: 'e1', projectId: 'p1');

        expect(cubit.state.status, ManageEventParticipantsStatus.ready);
        expect(cubit.state.members.first.member.id, 'm2');
        expect(cubit.state.members.first.isSelected, isTrue);
        expect(cubit.state.members.first.selectedSkillId, 's2');
        expect(
          cubit.state.members.first.permissions,
          contains(EventPermission.addSong),
        );

        await cubit.close();
      },
    );

    test('envia apenas membros selecionados com função definida', () async {
      final repo = _FakeEventsRepository(
        members: const [
          ProjectMemberEntity(
            id: 'm1',
            firstName: 'Ana',
            skills: [SkillEntity(id: 's1', name: 'Vocal')],
          ),
          ProjectMemberEntity(id: 'm2', firstName: 'Bruno'),
        ],
        skills: const [SkillEntity(id: 's1', name: 'Vocal')],
      );

      final cubit = ManageEventParticipantsCubit(repo);
      await cubit.load(eventId: 'e1', projectId: 'p1');

      cubit.toggleMember('m1', true);
      cubit.updateSkill('m1', 's1');
      cubit.togglePermission('m1', EventPermission.addSong, true);
      cubit.toggleMember('m2', true);

      final saved = await cubit.submit('e1');

      expect(saved, isTrue);
      expect(repo.savedParticipants, hasLength(1));
      expect(repo.savedParticipants.single.memberId, 'm1');
      expect(repo.savedParticipants.single.skillId, 's1');
      expect(repo.savedParticipants.single.permissions, ['ADD_SONG']);

      await cubit.close();
    });
  });
}
