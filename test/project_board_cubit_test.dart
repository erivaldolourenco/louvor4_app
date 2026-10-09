import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/project_board/data/responsibilities_repository.dart';
import 'package:louvor4_app/features/project_board/domain/entities/my_responsibility_entity.dart';
import 'package:louvor4_app/features/project_board/domain/entities/responsibility_entity.dart';
import 'package:louvor4_app/features/project_board/presentation/cubit/project_board_cubit.dart';

class _FakeResponsibilitiesRepository implements ResponsibilitiesRepository {
  final List<String> calls = [];

  @override
  Future<List<ResponsibilityEntity>> getResponsibilities(
    String projectId,
  ) async {
    calls.add('list');
    return const [];
  }

  @override
  Future<ResponsibilityEntity> createResponsibility(
    String projectId, {
    required String name,
    String? description,
  }) async {
    calls.add('create:$name:$description');
    return ResponsibilityEntity(
      id: 'new',
      name: name,
      description: description,
    );
  }

  @override
  Future<ResponsibilityEntity> updateResponsibility(
    String projectId,
    String responsibilityId, {
    required String name,
    String? description,
  }) async {
    calls.add('update:$responsibilityId:$name');
    return ResponsibilityEntity(id: responsibilityId, name: name);
  }

  @override
  Future<void> deleteResponsibility(
    String projectId,
    String responsibilityId,
  ) async {
    calls.add('delete:$responsibilityId');
  }

  @override
  Future<List<ResponsibilityAssignmentEntity>> getHistory(
    String projectId,
    String responsibilityId,
  ) async => const [];

  @override
  Future<ResponsibilityAssignmentEntity> assignMember(
    String projectId,
    String responsibilityId, {
    required String memberId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    calls.add('assign:$responsibilityId:$memberId:${formatApiDate(startDate)}');
    return _period('a-new', memberId, startDate, endDate);
  }

  @override
  Future<ResponsibilityAssignmentEntity> updateAssignment(
    String projectId,
    String responsibilityId,
    String assignmentId, {
    required String memberId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    calls.add('updateAssignment:$assignmentId:${formatApiDate(endDate)}');
    return _period(assignmentId, memberId, startDate, endDate);
  }

  @override
  Future<void> deleteAssignment(
    String projectId,
    String responsibilityId,
    String assignmentId,
  ) async {}

  @override
  Future<List<MyResponsibilityEntity>> getMyResponsibilities() async =>
      const [];
}

ResponsibilityAssignmentEntity _period(
  String id,
  String memberId,
  DateTime start,
  DateTime end,
) => ResponsibilityAssignmentEntity(
  id: id,
  memberId: memberId,
  userId: 'u-$memberId',
  firstName: memberId,
  lastName: '',
  startDate: start,
  endDate: end,
);

void main() {
  final oct1 = DateTime(2026, 10, 1);
  final oct31 = DateTime(2026, 10, 31);

  late _FakeResponsibilitiesRepository repo;
  late ProjectBoardCubit cubit;

  final existing = ResponsibilityEntity(
    id: 'r1',
    name: 'Direção musical',
    description: 'Conduz os ensaios',
    current: _period('a1', 'joao', oct1, oct31),
  );

  setUp(() {
    repo = _FakeResponsibilitiesRepository();
    cubit = ProjectBoardCubit(repo, projectId: 'p1');
  });

  test(
    'criar salva nome aparado e descrição vazia como nula e retorna a nova',
    () async {
      final saved = await cubit.save(name: '  Som ', description: '   ');

      expect(saved?.id, 'new');
      expect(repo.calls, ['create:Som:null', 'list']);
    },
  );

  test('editar só o nome atualiza a responsabilidade', () async {
    final saved = await cubit.save(
      existing: existing,
      name: 'Direção',
      description: 'Conduz os ensaios',
    );

    expect(saved?.name, 'Direção');
    expect(repo.calls, ['update:r1:Direção', 'list']);
  });

  test('sem mudanças não chama a API', () async {
    final saved = await cubit.save(
      existing: existing,
      name: ' Direção musical ',
      description: 'Conduz os ensaios',
    );

    expect(saved, same(existing));
    expect(repo.calls, isEmpty);
  });

  test('excluir remove da lista', () async {
    final ok = await cubit.delete(existing);

    expect(ok, isTrue);
    expect(repo.calls, ['delete:r1']);
  });
}
