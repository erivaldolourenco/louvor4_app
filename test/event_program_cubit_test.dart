import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/events/data/event_program_repository.dart';
import 'package:louvor4_app/features/events/domain/entities/program_item_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/program_item_input_entity.dart';
import 'package:louvor4_app/features/events/presentation/cubit/event_program_cubit.dart';
import 'package:louvor4_app/features/events/presentation/cubit/event_program_state.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

TextProgramItemEntity _text(String id, int position, {String title = 'Item'}) =>
    TextProgramItemEntity(id: id, position: position, title: title);

MusicProgramItemEntity _music(String id, int position) =>
    MusicProgramItemEntity(
      id: id,
      position: position,
      songId: 's1',
      songTitle: 'Oceans',
      songArtist: 'Hillsong',
    );

const _createInput = CreateTextProgramItemInputEntity(title: 'Novo item');
const _updateInput = UpdateTextProgramItemInputEntity(title: 'Atualizado');

EventProgramCubit _cubit(_FakeRepo repo) =>
    EventProgramCubit(repo, eventId: 'e1');

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeRepo implements EventProgramRepository {
  _FakeRepo({
    this.items = const [],
    this.throwOnLoad = false,
    this.throwOnCreate = false,
    this.throwOnUpdate = false,
    this.throwOnDelete = false,
    this.throwOnReorder = false,
    ProgramItemEntity? createResult,
    ProgramItemEntity? updateResult,
  })  : _createResult = createResult,
        _updateResult = updateResult;

  final List<ProgramItemEntity> items;
  final bool throwOnLoad;
  final bool throwOnCreate;
  final bool throwOnUpdate;
  final bool throwOnDelete;
  final bool throwOnReorder;
  final ProgramItemEntity? _createResult;
  final ProgramItemEntity? _updateResult;

  String? deletedId;
  List<String>? lastReorderIds;

  @override
  Future<List<ProgramItemEntity>> getProgram(String eventId) async {
    if (throwOnLoad) throw Exception('erro ao carregar');
    return items;
  }

  @override
  Future<ProgramItemEntity> createTextItem(
    String eventId,
    CreateTextProgramItemInputEntity input,
  ) async {
    if (throwOnCreate) throw Exception('erro ao criar');
    return _createResult ??
        TextProgramItemEntity(id: 'new', position: 99, title: input.title);
  }

  @override
  Future<ProgramItemEntity> updateTextItem(
    String eventId,
    String itemId,
    UpdateTextProgramItemInputEntity input,
  ) async {
    if (throwOnUpdate) throw Exception('erro ao atualizar');
    return _updateResult ??
        TextProgramItemEntity(id: itemId, position: 0, title: input.title);
  }

  @override
  Future<void> deleteItem(String eventId, String itemId) async {
    deletedId = itemId;
    if (throwOnDelete) throw Exception('erro ao deletar');
  }

  @override
  Future<void> reorder(String eventId, List<String> orderedIds) async {
    lastReorderIds = orderedIds;
    if (throwOnReorder) throw Exception('erro ao reordenar');
  }
}

// Slow fake for guard tests
class _SlowRepo implements EventProgramRepository {
  _SlowRepo({required this.onGetProgram});
  final Future<List<ProgramItemEntity>> Function() onGetProgram;

  @override
  Future<List<ProgramItemEntity>> getProgram(String eventId) => onGetProgram();

  @override
  Future<ProgramItemEntity> createTextItem(String e, CreateTextProgramItemInputEntity i) async =>
      throw UnimplementedError();

  @override
  Future<ProgramItemEntity> updateTextItem(String e, String id, UpdateTextProgramItemInputEntity i) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteItem(String e, String id) async => throw UnimplementedError();

  @override
  Future<void> reorder(String e, List<String> ids) async => throw UnimplementedError();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('EventProgramCubit — loadProgram', () {
    test('emite success com todos os itens retornados pelo repositório', () async {
      // The repo impl sorts by position; the cubit preserves whatever order it receives.
      final repo = _FakeRepo(items: [
        _music('m0', 0),
        _text('t1', 1, title: 'A'),
        _text('t2', 2, title: 'B'),
      ]);
      final cubit = _cubit(repo);

      await cubit.loadProgram();

      expect(cubit.state.status, EventProgramStatus.success);
      expect(cubit.state.items, hasLength(3));
      expect(cubit.state.items.map((i) => i.id), ['m0', 't1', 't2']);

      await cubit.close();
    });

    test('emite success com lista vazia quando não há itens', () async {
      final cubit = _cubit(_FakeRepo());

      await cubit.loadProgram();

      expect(cubit.state.status, EventProgramStatus.success);
      expect(cubit.state.items, isEmpty);

      await cubit.close();
    });

    test('emite failure quando repositório lança exceção', () async {
      final cubit = _cubit(_FakeRepo(throwOnLoad: true));

      await cubit.loadProgram();

      expect(cubit.state.status, EventProgramStatus.failure);
      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.items, isEmpty);

      await cubit.close();
    });

    test('não faz requisição duplicada se já estiver carregando', () async {
      var calls = 0;
      final repo = _SlowRepo(onGetProgram: () async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return [];
      });
      final cubit = EventProgramCubit(repo, eventId: 'e1');

      final first = cubit.loadProgram();
      await cubit.loadProgram(); // bloqueada pelo guard
      await first;

      expect(calls, 1);

      await cubit.close();
    });
  });

  group('EventProgramCubit — createTextItem', () {
    test('adiciona item à lista, ordena por position e retorna true', () async {
      final existing = _text('t1', 5, title: 'Existente');
      final created = _text('new', 0, title: 'Novo item');
      final repo = _FakeRepo(items: [existing], createResult: created);
      final cubit = _cubit(repo);

      await cubit.loadProgram();
      final success = await cubit.createTextItem(_createInput);

      expect(success, isTrue);
      expect(cubit.state.status, EventProgramStatus.success);
      expect(cubit.state.items, hasLength(2));
      // created has position 0, so it should be first
      expect(cubit.state.items.first.id, 'new');

      await cubit.close();
    });

    test('retorna false e popula actionError quando repositório falha', () async {
      final cubit = _cubit(_FakeRepo(throwOnCreate: true));

      await cubit.loadProgram();
      final success = await cubit.createTextItem(_createInput);

      expect(success, isFalse);
      expect(cubit.state.actionError, isNotNull);
      expect(cubit.state.isActioning, isFalse);

      await cubit.close();
    });
  });

  group('EventProgramCubit — updateTextItem', () {
    test('substitui o item na lista e retorna true', () async {
      final repo = _FakeRepo(
        items: [_text('t1', 0, title: 'Original'), _text('t2', 1, title: 'Outro')],
        updateResult: _text('t1', 0, title: 'Atualizado'),
      );
      final cubit = _cubit(repo);

      await cubit.loadProgram();
      final success = await cubit.updateTextItem('t1', _updateInput);

      expect(success, isTrue);
      expect(cubit.state.items, hasLength(2));
      final found =
          cubit.state.items.firstWhere((i) => i.id == 't1') as TextProgramItemEntity;
      expect(found.title, 'Atualizado');
      // other item unchanged
      final other =
          cubit.state.items.firstWhere((i) => i.id == 't2') as TextProgramItemEntity;
      expect(other.title, 'Outro');

      await cubit.close();
    });

    test('retorna false e popula actionError quando repositório falha', () async {
      final cubit = _cubit(
        _FakeRepo(items: [_text('t1', 0)], throwOnUpdate: true),
      );

      await cubit.loadProgram();
      final success = await cubit.updateTextItem('t1', _updateInput);

      expect(success, isFalse);
      expect(cubit.state.actionError, isNotNull);
      // original item still in list
      expect(cubit.state.items, hasLength(1));

      await cubit.close();
    });
  });

  group('EventProgramCubit — deleteItem', () {
    test('remove o item da lista e retorna true', () async {
      final repo = _FakeRepo(items: [
        _text('t1', 0),
        _text('t2', 1),
        _music('m1', 2),
      ]);
      final cubit = _cubit(repo);

      await cubit.loadProgram();
      final success = await cubit.deleteItem('t2');

      expect(success, isTrue);
      expect(cubit.state.items, hasLength(2));
      expect(cubit.state.items.map((i) => i.id), isNot(contains('t2')));
      expect(repo.deletedId, 't2');

      await cubit.close();
    });

    test('retorna false, mantém lista inalterada e popula actionError', () async {
      final cubit = _cubit(
        _FakeRepo(
          items: [_text('t1', 0), _text('t2', 1)],
          throwOnDelete: true,
        ),
      );

      await cubit.loadProgram();
      final success = await cubit.deleteItem('t1');

      expect(success, isFalse);
      expect(cubit.state.actionError, isNotNull);
      expect(cubit.state.items, hasLength(2));

      await cubit.close();
    });
  });

  group('EventProgramCubit — reorder', () {
    test('reordena itens otimisticamente e atualiza positions', () async {
      final repo = _FakeRepo(items: [
        _text('a', 0, title: 'A'),
        _text('b', 1, title: 'B'),
        _text('c', 2, title: 'C'),
      ]);
      final cubit = _cubit(repo);

      await cubit.loadProgram();
      final success = await cubit.reorder(['c', 'a', 'b']);

      expect(success, isTrue);
      expect(cubit.state.items.map((i) => i.id), ['c', 'a', 'b']);
      expect(cubit.state.items[0].position, 0);
      expect(cubit.state.items[1].position, 1);
      expect(cubit.state.items[2].position, 2);
      expect(repo.lastReorderIds, ['c', 'a', 'b']);

      await cubit.close();
    });

    test('preserva campos de MusicProgramItemEntity durante reordenação', () async {
      final repo = _FakeRepo(items: [
        _music('m1', 0),
        _text('t1', 1, title: 'Texto'),
      ]);
      final cubit = _cubit(repo);

      await cubit.loadProgram();
      await cubit.reorder(['t1', 'm1']);

      expect(cubit.state.items[0], isA<TextProgramItemEntity>());
      final music = cubit.state.items[1] as MusicProgramItemEntity;
      expect(music.songId, 's1');
      expect(music.songTitle, 'Oceans');

      await cubit.close();
    });

    test('reverte para ordem original quando repositório falha', () async {
      final repo = _FakeRepo(
        items: [
          _text('a', 0, title: 'A'),
          _text('b', 1, title: 'B'),
        ],
        throwOnReorder: true,
      );
      final cubit = _cubit(repo);

      await cubit.loadProgram();
      final originalIds = cubit.state.items.map((i) => i.id).toList();

      final success = await cubit.reorder(['b', 'a']);

      expect(success, isFalse);
      expect(cubit.state.actionError, isNotNull);
      expect(cubit.state.items.map((i) => i.id), originalIds);

      await cubit.close();
    });

    test('retorna false e popula actionError quando repositório falha', () async {
      final cubit = _cubit(
        _FakeRepo(
          items: [_text('a', 0), _text('b', 1)],
          throwOnReorder: true,
        ),
      );

      await cubit.loadProgram();
      final success = await cubit.reorder(['b', 'a']);

      expect(success, isFalse);
      expect(cubit.state.actionError, isNotNull);

      await cubit.close();
    });
  });
}
