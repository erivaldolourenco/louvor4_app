import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/events/data/events_local_cache.dart';
import 'package:louvor4_app/features/events/data/events_repository.dart';
import 'package:louvor4_app/features/events/domain/entities/event_detail_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/event_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/event_participant_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/event_participant_input_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/event_permissions_entity.dart';
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
  Future<EventPermissionsEntity> getMyEventPermissions(String eventId) async =>
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
// Fake cache local
// ---------------------------------------------------------------------------

class _FakeEventsLocalCache extends EventsLocalCache {
  _FakeEventsLocalCache({List<EventEntity> stored = const []})
    : _stored = stored;

  List<EventEntity> _stored;
  final List<List<EventEntity>> saveCalls = [];

  @override
  Future<List<EventEntity>> readUpcomingEvents() async => _stored;

  @override
  Future<void> saveUpcomingEvents(List<EventEntity> events) async {
    saveCalls.add(events);
    _stored = events;
  }

  @override
  Future<void> clear() async {
    _stored = const [];
  }
}

/// Repositório cujo `getEvents` só resolve quando [completeWith] ou
/// [completeWithError] é chamado — usado para inspecionar o estado
/// "otimista" (cache) antes da resposta da rede chegar.
class _ControllableEventsRepository implements EventsRepository {
  final Completer<List<EventEntity>> _completer = Completer();

  void completeWith(List<EventEntity> events) => _completer.complete(events);

  void completeWithError(Object error) => _completer.completeError(error);

  @override
  Future<List<EventEntity>> getEvents() => _completer.future;

  @override
  Future<({List<EventEntity> events, bool hasMore})> getPastEvents(
    int page, {
    int size = 10,
  }) async => (events: const <EventEntity>[], hasMore: false);

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
  Future<EventPermissionsEntity> getMyEventPermissions(String eventId) async =>
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

/// Repositório cujo `getEvents` retorna [events] na primeira chamada e
/// lança exceção nas chamadas seguintes — simula perder a conexão depois
/// de um load bem-sucedido.
class _ToggleEventsRepository implements EventsRepository {
  _ToggleEventsRepository(this.events);

  final List<EventEntity> events;
  int callCount = 0;

  @override
  Future<List<EventEntity>> getEvents() async {
    callCount++;
    if (callCount == 1) return events;
    throw Exception('sem conexão');
  }

  @override
  Future<({List<EventEntity> events, bool hasMore})> getPastEvents(
    int page, {
    int size = 10,
  }) async => (events: const <EventEntity>[], hasMore: false);

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
  Future<EventPermissionsEntity> getMyEventPermissions(String eventId) async =>
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

  group('EventsCubit — cache local (offline)', () {
    test(
      'mostra eventos do cache imediatamente e atualiza com a resposta da rede',
      () async {
        final cachedEvents = [_makeEvent('cached')];
        final freshEvents = [_makeEvent('fresh1'), _makeEvent('fresh2')];
        final cache = _FakeEventsLocalCache(stored: cachedEvents);
        final repo = _ControllableEventsRepository();
        final cubit = EventsCubit(repo, cache: cache);

        final loadFuture = cubit.load();

        // Aguarda o microtask que lê o cache e emite o estado otimista,
        // antes da resposta da rede (que ainda não foi resolvida).
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.status, EventsStatus.success);
        expect(cubit.state.events.map((e) => e.id), ['cached']);
        expect(cubit.state.isOffline, isTrue);

        repo.completeWith(freshEvents);
        await loadFuture;

        expect(cubit.state.events.map((e) => e.id), ['fresh1', 'fresh2']);
        expect(cubit.state.isOffline, isFalse);
        expect(cache.saveCalls, hasLength(1));
        expect(
          cache.saveCalls.single.map((e) => e.id),
          ['fresh1', 'fresh2'],
        );

        await cubit.close();
      },
    );

    test(
      'mantém os eventos já carregados e marca isOffline quando a rede falha depois',
      () async {
        final events = [_makeEvent('e1')];
        final repo = _ToggleEventsRepository(events);
        final cache = _FakeEventsLocalCache();
        final cubit = EventsCubit(repo, cache: cache);

        await cubit.load();
        expect(cubit.state.events, hasLength(1));
        expect(cubit.state.isOffline, isFalse);

        await cubit.load();

        expect(cubit.state.status, EventsStatus.success);
        expect(cubit.state.events, hasLength(1));
        expect(cubit.state.events.single.id, 'e1');
        expect(cubit.state.isOffline, isTrue);

        await cubit.close();
      },
    );

    test('salva os eventos da rede no cache após um load bem-sucedido', () async {
      final events = [_makeEvent('e1'), _makeEvent('e2')];
      final cache = _FakeEventsLocalCache();
      final cubit = EventsCubit(
        _FakeEventsRepository(upcomingEvents: events),
        cache: cache,
      );

      await cubit.load();

      expect(cache.saveCalls, hasLength(1));
      expect(cache.saveCalls.single.map((e) => e.id), ['e1', 'e2']);

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

    test('com force:true reseta a lista e busca de novo', () async {
      final repo = _FakeEventsRepository(
        pastEventPages: {
          0: (events: [_makeEvent('p1')], hasMore: false),
        },
      );
      final cubit = EventsCubit(repo);

      await cubit.loadPastEvents();
      expect(cubit.state.pastEvents, hasLength(1));

      await cubit.loadPastEvents(force: true);
      expect(cubit.state.pastEvents, hasLength(1));
      expect(cubit.state.pastEventsPage, 0);
      expect(repo.pastPagesRequested, [0, 0]);

      await cubit.close();
    });

    test(
      'sem force, não refaz a busca se já carregou com sucesso',
      () async {
        final repo = _FakeEventsRepository(
          pastEventPages: {
            0: (events: [_makeEvent('p1')], hasMore: false),
          },
        );
        final cubit = EventsCubit(repo);

        await cubit.loadPastEvents();
        expect(repo.pastPagesRequested, [0]);

        // Simula a aba "Passados" sendo reativada depois que a tela foi
        // recriada — não deve gerar uma nova chamada de rede.
        await cubit.loadPastEvents();
        await cubit.loadPastEvents();

        expect(repo.pastPagesRequested, [0]);
        expect(cubit.state.pastEvents, hasLength(1));

        await cubit.close();
      },
    );

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
  Future<EventPermissionsEntity> getMyEventPermissions(String eventId) async =>
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
