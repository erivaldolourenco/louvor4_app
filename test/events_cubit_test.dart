import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/events/data/events_repository.dart';
import 'package:louvor4_app/features/events/domain/entities/event_detail_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/event_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/event_participant_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/event_participant_input_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/event_song_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/event_song_input_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/project_member_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/skill_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/update_event_input_entity.dart';
import 'package:louvor4_app/features/events/presentation/cubit/events_cubit.dart';
import 'package:louvor4_app/features/events/presentation/cubit/events_state.dart';
import 'package:louvor4_app/features/songs/domain/entities/song_entity.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

EventEntity _makeEvent(String id) => EventEntity(
  id: id,
  date: DateTime(2026, 1, 1),
  time: '19:00',
  title: 'Culto $id',
  projectTitle: 'Projeto',
  participantsCount: 0,
  repertoireCount: 0,
);

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeEventsRepository implements EventsRepository {
  _FakeEventsRepository({
    this.upcomingEvents = const [],
    this.pastEventPages = const {},
    this.throwOnGetEvents = false,
    this.throwOnGetPastEvents = false,
  });

  final List<EventEntity> upcomingEvents;
  /// page number → (events, hasMore)
  final Map<int, ({List<EventEntity> events, bool hasMore})> pastEventPages;
  final bool throwOnGetEvents;
  final bool throwOnGetPastEvents;

  final List<int> pastPagesRequested = [];

  @override
  Future<List<EventEntity>> getEvents() async {
    if (throwOnGetEvents) throw Exception('falha ao carregar eventos');
    return upcomingEvents;
  }

  @override
  Future<({List<EventEntity> events, bool hasMore})> getPastEvents(
    int page, {
    int size = 10,
  }) async {
    pastPagesRequested.add(page);
    if (throwOnGetPastEvents) throw Exception('falha ao carregar eventos passados');
    return pastEventPages[page] ?? (events: const <EventEntity>[], hasMore: false);
  }

  // ---- unused stubs ----

  @override
  Future<EventDetailEntity> getEventDetail(String eventId) async =>
      throw UnimplementedError();

  @override
  Future<List<EventParticipant>> getEventParticipants(String eventId) async =>
      throw UnimplementedError();

  @override
  Future<List<EventSong>> getEventSongs(String eventId) async =>
      throw UnimplementedError();

  @override
  Future<List<SkillEntity>> getProjectSkills(String projectId) async =>
      throw UnimplementedError();

  @override
  Future<String> getProjectMemberRole(String projectId) async =>
      throw UnimplementedError();

  @override
  Future<ProjectMemberEntity> getProjectMember(
    String projectId,
    String memberId,
  ) async => throw UnimplementedError();

  @override
  Future<List<ProjectMemberEntity>> getProjectMembers(String projectId) async =>
      throw UnimplementedError();

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
  Future<void> removeSongFromEvent(String eventId, String eventSongId) async =>
      throw UnimplementedError();

  @override
  Future<void> updateEvent(String eventId, UpdateEventInputEntity input) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteEvent(String eventId) async =>
      throw UnimplementedError();

  @override
  Future<void> acceptEventParticipant(String participantId) async =>
      throw UnimplementedError();

  @override
  Future<void> declineEventParticipant(String participantId) async =>
      throw UnimplementedError();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('EventsCubit — load (próximos)', () {
    test('emite success com a lista de eventos', () async {
      final events = [_makeEvent('e1'), _makeEvent('e2')];
      final cubit = EventsCubit(_FakeEventsRepository(upcomingEvents: events));

      await cubit.load();

      expect(cubit.state.status, EventsStatus.success);
      expect(cubit.state.events, hasLength(2));
      expect(cubit.state.events.map((e) => e.id), containsAll(['e1', 'e2']));

      await cubit.close();
    });

    test('emite failure quando o repositório lança exceção', () async {
      final cubit = EventsCubit(
        _FakeEventsRepository(throwOnGetEvents: true),
      );

      await cubit.load();

      expect(cubit.state.status, EventsStatus.failure);
      expect(cubit.state.events, isEmpty);

      await cubit.close();
    });
  });

  group('EventsCubit — loadPastEvents', () {
    test('carrega a primeira página e emite success', () async {
      final page0 = [_makeEvent('p1'), _makeEvent('p2')];
      final repo = _FakeEventsRepository(
        pastEventPages: {0: (events: page0, hasMore: true)},
      );
      final cubit = EventsCubit(repo);

      await cubit.loadPastEvents();

      expect(cubit.state.pastEventsStatus, PastEventsStatus.success);
      expect(cubit.state.pastEvents, hasLength(2));
      expect(cubit.state.pastEventsPage, 0);
      expect(cubit.state.pastEventsHasMore, isTrue);
      expect(repo.pastPagesRequested, [0]);

      await cubit.close();
    });

    test('emite success com lista vazia quando não há eventos passados', () async {
      final cubit = EventsCubit(_FakeEventsRepository());

      await cubit.loadPastEvents();

      expect(cubit.state.pastEventsStatus, PastEventsStatus.success);
      expect(cubit.state.pastEvents, isEmpty);
      expect(cubit.state.pastEventsHasMore, isFalse);

      await cubit.close();
    });

    test('reseta a lista ao ser chamado novamente', () async {
      final repo = _FakeEventsRepository(
        pastEventPages: {
          0: (events: [_makeEvent('p1')], hasMore: false),
        },
      );
      final cubit = EventsCubit(repo);

      await cubit.loadPastEvents();
      expect(cubit.state.pastEvents, hasLength(1));

      // Segunda chamada deve redefinir a lista
      await cubit.loadPastEvents();
      expect(cubit.state.pastEvents, hasLength(1));
      expect(cubit.state.pastEventsPage, 0);
      expect(repo.pastPagesRequested, [0, 0]);

      await cubit.close();
    });

    test('emite failure quando o repositório lança exceção', () async {
      final cubit = EventsCubit(
        _FakeEventsRepository(throwOnGetPastEvents: true),
      );

      await cubit.loadPastEvents();

      expect(cubit.state.pastEventsStatus, PastEventsStatus.failure);
      expect(cubit.state.pastEvents, isEmpty);

      await cubit.close();
    });

    test('não faz nova requisição se já estiver carregando', () async {
      // Simulamos um repositório lento usando um Completer
      var callCount = 0;
      final repo = _SlowEventsRepository(
        onGetPastEvents: (page) async {
          callCount++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return (events: <EventEntity>[], hasMore: false);
        },
      );
      final cubit = EventsCubit(repo);

      // Dispara duas chamadas sem await na primeira
      final first = cubit.loadPastEvents();
      await cubit.loadPastEvents(); // bloqueada pelo guard
      await first;

      expect(callCount, 1);

      await cubit.close();
    });
  });

  group('EventsCubit — loadMorePastEvents', () {
    test('anexa a próxima página à lista e incrementa pastEventsPage', () async {
      final page0 = [_makeEvent('p1'), _makeEvent('p2')];
      final page1 = [_makeEvent('p3')];
      final repo = _FakeEventsRepository(
        pastEventPages: {
          0: (events: page0, hasMore: true),
          1: (events: page1, hasMore: false),
        },
      );
      final cubit = EventsCubit(repo);

      await cubit.loadPastEvents();
      expect(cubit.state.pastEventsPage, 0);
      expect(cubit.state.pastEvents, hasLength(2));

      await cubit.loadMorePastEvents();

      expect(cubit.state.pastEventsStatus, PastEventsStatus.success);
      expect(cubit.state.pastEvents, hasLength(3));
      expect(cubit.state.pastEventsPage, 1);
      expect(cubit.state.pastEventsHasMore, isFalse);
      expect(repo.pastPagesRequested, [0, 1]);

      await cubit.close();
    });

    test('não faz requisição quando hasMore é false', () async {
      final repo = _FakeEventsRepository(
        pastEventPages: {
          0: (events: [_makeEvent('p1')], hasMore: false),
        },
      );
      final cubit = EventsCubit(repo);

      await cubit.loadPastEvents();
      await cubit.loadMorePastEvents();

      // Apenas a página 0 deve ter sido requisitada
      expect(repo.pastPagesRequested, [0]);
      expect(cubit.state.pastEvents, hasLength(1));

      await cubit.close();
    });

    test('não faz requisição enquanto loadingMore está ativo', () async {
      var callCount = 0;
      final repo = _SlowEventsRepository(
        onGetPastEvents: (page) async {
          callCount++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return (events: <EventEntity>[], hasMore: true);
        },
      );
      final cubit = EventsCubit(repo);

      // Coloca em estado success com hasMore=true via estado manual
      await cubit.loadPastEvents(); // callCount = 1

      callCount = 0;
      final first = cubit.loadMorePastEvents();
      await cubit.loadMorePastEvents(); // deve ser bloqueada
      await first;

      expect(callCount, 1);

      await cubit.close();
    });

    test('emite failure quando o repositório lança exceção no loadMore', () async {
      var firstCall = true;
      final repo = _SlowEventsRepository(
        onGetPastEvents: (page) async {
          if (firstCall) {
            firstCall = false;
            return (events: [_makeEvent('p1')], hasMore: true);
          }
          throw Exception('erro na paginação');
        },
      );
      final cubit = EventsCubit(repo);

      await cubit.loadPastEvents();
      expect(cubit.state.pastEventsStatus, PastEventsStatus.success);

      await cubit.loadMorePastEvents();

      expect(cubit.state.pastEventsStatus, PastEventsStatus.failure);

      await cubit.close();
    });
  });
}

// ---------------------------------------------------------------------------
// Slow fake repository (for guard tests)
// ---------------------------------------------------------------------------

class _SlowEventsRepository implements EventsRepository {
  _SlowEventsRepository({required this.onGetPastEvents});

  final Future<({List<EventEntity> events, bool hasMore})> Function(int page)
  onGetPastEvents;

  @override
  Future<({List<EventEntity> events, bool hasMore})> getPastEvents(
    int page, {
    int size = 10,
  }) => onGetPastEvents(page);

  @override
  Future<List<EventEntity>> getEvents() async => const [];

  @override
  Future<EventDetailEntity> getEventDetail(String eventId) async =>
      throw UnimplementedError();

  @override
  Future<List<EventParticipant>> getEventParticipants(String eventId) async =>
      throw UnimplementedError();

  @override
  Future<List<EventSong>> getEventSongs(String eventId) async =>
      throw UnimplementedError();

  @override
  Future<List<SkillEntity>> getProjectSkills(String projectId) async =>
      throw UnimplementedError();

  @override
  Future<String> getProjectMemberRole(String projectId) async =>
      throw UnimplementedError();

  @override
  Future<ProjectMemberEntity> getProjectMember(
    String projectId,
    String memberId,
  ) async => throw UnimplementedError();

  @override
  Future<List<ProjectMemberEntity>> getProjectMembers(String projectId) async =>
      throw UnimplementedError();

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
  Future<void> removeSongFromEvent(String eventId, String eventSongId) async =>
      throw UnimplementedError();

  @override
  Future<void> updateEvent(String eventId, UpdateEventInputEntity input) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteEvent(String eventId) async =>
      throw UnimplementedError();

  @override
  Future<void> acceptEventParticipant(String participantId) async =>
      throw UnimplementedError();

  @override
  Future<void> declineEventParticipant(String participantId) async =>
      throw UnimplementedError();
}
