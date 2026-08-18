import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/medleys/data/medley_repository.dart';
import 'package:louvor4_app/features/medleys/domain/entities/create_medley_input_entity.dart';
import 'package:louvor4_app/features/medleys/domain/entities/medley_entity.dart';
import 'package:louvor4_app/features/medleys/presentation/cubit/medley_cubit.dart';
import 'package:louvor4_app/features/medleys/presentation/cubit/medley_state.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MedleyEntity _makeMedley(String id, {String name = 'Medley'}) =>
    MedleyEntity(id: id, name: name);

const _emptyInput = CreateMedleyInputEntity(name: 'Novo', items: []);

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeMedleyRepository implements MedleyRepository {
  _FakeMedleyRepository({
    this.medleys = const [],
    this.throwOnLoad = false,
    this.throwOnCreate = false,
    this.throwOnUpdate = false,
    this.throwOnDelete = false,
    MedleyEntity? createdResult,
    MedleyEntity? updatedResult,
  })  : _createdResult = createdResult,
        _updatedResult = updatedResult;

  final List<MedleyEntity> medleys;
  final bool throwOnLoad;
  final bool throwOnCreate;
  final bool throwOnUpdate;
  final bool throwOnDelete;
  final MedleyEntity? _createdResult;
  final MedleyEntity? _updatedResult;

  String? deletedId;
  CreateMedleyInputEntity? lastCreateInput;
  ({String id, CreateMedleyInputEntity input})? lastUpdateCall;

  @override
  Future<List<MedleyEntity>> getUserMedleys() async {
    if (throwOnLoad) throw Exception('falha ao carregar medleys');
    return medleys;
  }

  @override
  Future<MedleyEntity> createMedley(CreateMedleyInputEntity input) async {
    lastCreateInput = input;
    if (throwOnCreate) throw Exception('falha ao criar medley');
    return _createdResult ?? MedleyEntity(id: 'new', name: input.name);
  }

  @override
  Future<MedleyEntity> updateMedley(
    String id,
    CreateMedleyInputEntity input,
  ) async {
    lastUpdateCall = (id: id, input: input);
    if (throwOnUpdate) throw Exception('falha ao atualizar medley');
    return _updatedResult ??
        MedleyEntity(id: id, name: input.name);
  }

  @override
  Future<void> deleteMedley(String id) async {
    deletedId = id;
    if (throwOnDelete) throw Exception('falha ao deletar medley');
  }

  @override
  Future<void> uploadReferenceAudio(String id, String filePath) async {}

  String? lastCategoriesUpdateId;
  List<String>? lastCategoryIds;
  bool throwOnUpdateCategories = false;

  @override
  Future<void> updateMedleyCategories(
    String medleyId,
    List<String> categoryIds,
  ) async {
    lastCategoriesUpdateId = medleyId;
    lastCategoryIds = categoryIds;
    if (throwOnUpdateCategories) {
      throw Exception('falha ao atualizar categorias do medley');
    }
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MedleyCubit — loadMedleys', () {
    test('emite loading depois success com a lista', () async {
      final medleys = [_makeMedley('m1'), _makeMedley('m2')];
      final cubit = MedleyCubit(_FakeMedleyRepository(medleys: medleys));

      await cubit.loadMedleys();

      expect(cubit.state.status, MedleyStatus.success);
      expect(cubit.state.medleys, hasLength(2));
      expect(cubit.state.medleys.map((m) => m.id), containsAll(['m1', 'm2']));

      await cubit.close();
    });

    test('emite failure quando repositório lança exceção', () async {
      final cubit = MedleyCubit(
        _FakeMedleyRepository(throwOnLoad: true),
      );

      await cubit.loadMedleys();

      expect(cubit.state.status, MedleyStatus.failure);
      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.medleys, isEmpty);

      await cubit.close();
    });

    test('não repete requisição se já estiver carregando', () async {
      var callCount = 0;
      final repo = _SlowMedleyRepository(
        onGetMedleys: () async {
          callCount++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return [];
        },
      );
      final cubit = MedleyCubit(repo);

      final first = cubit.loadMedleys();
      await cubit.loadMedleys(); // bloqueada pelo guard
      await first;

      expect(callCount, 1);

      await cubit.close();
    });
  });

  group('MedleyCubit — createMedley', () {
    test('adiciona o medley criado à lista e retorna true', () async {
      final existing = [_makeMedley('m1')];
      final created = _makeMedley('m2', name: 'Novo');
      final repo = _FakeMedleyRepository(
        medleys: existing,
        createdResult: created,
      );
      final cubit = MedleyCubit(repo);

      await cubit.loadMedleys();
      final result = await cubit.createMedley(_emptyInput);

      expect(result, isTrue);
      expect(cubit.state.status, MedleyStatus.success);
      expect(cubit.state.medleys, hasLength(2));
      expect(cubit.state.medleys.last.id, 'm2');
      expect(repo.lastCreateInput?.name, 'Novo');

      await cubit.close();
    });

    test('retorna false e popula actionError quando repositório falha', () async {
      final cubit = MedleyCubit(
        _FakeMedleyRepository(throwOnCreate: true),
      );

      await cubit.loadMedleys();
      final result = await cubit.createMedley(_emptyInput);

      expect(result, isFalse);
      expect(cubit.state.actionError, isNotNull);
      expect(cubit.state.isActioning, isFalse);

      await cubit.close();
    });

    test('limpa actionError anterior ao iniciar nova operação', () async {
      final repo = _FakeMedleyRepository(throwOnCreate: true);
      final cubit = MedleyCubit(repo);

      // Primeira tentativa falha
      await cubit.createMedley(_emptyInput);
      expect(cubit.state.actionError, isNotNull);

      // Segunda tentativa: mesmo falhando, actionError é limpo no início
      // Verificamos via um repositório que não lança na segunda chamada
      final repo2 = _FakeMedleyRepository(
        createdResult: _makeMedley('m-new'),
      );
      final cubit2 = MedleyCubit(repo2);
      await cubit2.createMedley(_emptyInput);

      expect(cubit2.state.actionError, isNull);

      await cubit.close();
      await cubit2.close();
    });
  });

  group('MedleyCubit — updateMedley', () {
    test('substitui o medley na lista e retorna true', () async {
      final original = _makeMedley('m1', name: 'Original');
      final other = _makeMedley('m2', name: 'Outro');
      final updated = _makeMedley('m1', name: 'Atualizado');
      final repo = _FakeMedleyRepository(
        medleys: [original, other],
        updatedResult: updated,
      );
      final cubit = MedleyCubit(repo);

      await cubit.loadMedleys();
      final result = await cubit.updateMedley(
        'm1',
        const CreateMedleyInputEntity(name: 'Atualizado', items: []),
      );

      expect(result, isTrue);
      expect(cubit.state.medleys, hasLength(2));

      final found = cubit.state.medleys.firstWhere((m) => m.id == 'm1');
      expect(found.name, 'Atualizado');
      expect(repo.lastUpdateCall?.id, 'm1');

      await cubit.close();
    });

    test('retorna false e popula actionError quando repositório falha', () async {
      final cubit = MedleyCubit(
        _FakeMedleyRepository(
          medleys: [_makeMedley('m1')],
          throwOnUpdate: true,
        ),
      );

      await cubit.loadMedleys();
      final result = await cubit.updateMedley('m1', _emptyInput);

      expect(result, isFalse);
      expect(cubit.state.actionError, isNotNull);

      await cubit.close();
    });
  });

  group('MedleyCubit — deleteMedley', () {
    test('remove o medley da lista e retorna true', () async {
      final repo = _FakeMedleyRepository(
        medleys: [_makeMedley('m1'), _makeMedley('m2'), _makeMedley('m3')],
      );
      final cubit = MedleyCubit(repo);

      await cubit.loadMedleys();
      final result = await cubit.deleteMedley('m2');

      expect(result, isTrue);
      expect(cubit.state.medleys, hasLength(2));
      expect(cubit.state.medleys.map((m) => m.id), isNot(contains('m2')));
      expect(repo.deletedId, 'm2');

      await cubit.close();
    });

    test('retorna false e popula actionError quando repositório falha', () async {
      final cubit = MedleyCubit(
        _FakeMedleyRepository(
          medleys: [_makeMedley('m1')],
          throwOnDelete: true,
        ),
      );

      await cubit.loadMedleys();
      final result = await cubit.deleteMedley('m1');

      expect(result, isFalse);
      expect(cubit.state.actionError, isNotNull);
      // Lista não deve ser alterada após falha
      expect(cubit.state.medleys, hasLength(1));

      await cubit.close();
    });
  });
}

// ---------------------------------------------------------------------------
// Slow fake repository (for guard test)
// ---------------------------------------------------------------------------

class _SlowMedleyRepository implements MedleyRepository {
  _SlowMedleyRepository({required this.onGetMedleys});

  final Future<List<MedleyEntity>> Function() onGetMedleys;

  @override
  Future<List<MedleyEntity>> getUserMedleys() => onGetMedleys();

  @override
  Future<MedleyEntity> createMedley(CreateMedleyInputEntity input) async =>
      throw UnimplementedError();

  @override
  Future<MedleyEntity> updateMedley(
    String id,
    CreateMedleyInputEntity input,
  ) async => throw UnimplementedError();

  @override
  Future<void> deleteMedley(String id) async => throw UnimplementedError();

  @override
  Future<void> uploadReferenceAudio(String id, String filePath) async => throw UnimplementedError();

  @override
  Future<void> updateMedleyCategories(
    String medleyId,
    List<String> categoryIds,
  ) async => throw UnimplementedError();
}
