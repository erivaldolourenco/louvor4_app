import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/project_skills/data/repositories/project_skills_repository.dart';
import 'package:louvor4_app/features/project_skills/domain/entities/project_context_entity.dart';
import 'package:louvor4_app/features/project_skills/domain/entities/project_role.dart';
import 'package:louvor4_app/features/project_skills/domain/entities/project_skill_entity.dart';
import 'package:louvor4_app/features/project_skills/presentation/state/project_skills_cubit.dart';
import 'package:louvor4_app/features/project_skills/presentation/state/project_skills_state.dart';

class _FakeProjectSkillsRepository implements ProjectSkillsRepository {
  _FakeProjectSkillsRepository({
    this.role = ProjectRole.admin,
    this.projectName = 'Projeto Teste',
    this.skills = const [],
  });

  ProjectRole role;
  String projectName;
  List<ProjectSkillEntity> skills;
  String? lastCreatedName;
  String? deletedSkillId;

  @override
  Future<void> addProjectSkill(String projectId, String name) async {
    lastCreatedName = name;
    skills = [
      ...skills,
      ProjectSkillEntity(id: 'new-skill', name: name),
    ];
  }

  @override
  Future<void> deleteProjectSkill(String skillId) async {
    deletedSkillId = skillId;
    skills = skills.where((skill) => skill.id != skillId).toList();
  }

  @override
  Future<ProjectContextEntity> getProjectContext(String projectId) async {
    return ProjectContextEntity(
      id: projectId,
      name: projectName,
      profileImage: null,
    );
  }

  @override
  Future<ProjectRole> getMemberRole(String projectId) async => role;

  @override
  Future<List<ProjectSkillEntity>> getProjectSkills(String projectId) async {
    return skills;
  }
}

void main() {
  group('ProjectSkillsCubit', () {
    test('carrega contexto e skills com sucesso', () async {
      final repo = _FakeProjectSkillsRepository(
        role: ProjectRole.owner,
        projectName: 'Louvor Central',
        skills: const [
          ProjectSkillEntity(id: '2', name: 'Vocal'),
          ProjectSkillEntity(id: '1', name: 'Guitarra'),
        ],
      );

      final cubit = ProjectSkillsCubit(
        repository: repo,
        projectId: 'p1',
      );

      await cubit.load();

      expect(cubit.state.status, ProjectSkillsStatus.success);
      expect(cubit.state.canManageSkills, isTrue);
      expect(cubit.state.projectName, 'Louvor Central');
      expect(cubit.state.skills.first.name, 'Guitarra');

      await cubit.close();
    });

    test('cria skill e recarrega a lista', () async {
      final repo = _FakeProjectSkillsRepository(
        skills: const [ProjectSkillEntity(id: '1', name: 'Vocal')],
      );
      final cubit = ProjectSkillsCubit(
        repository: repo,
        projectId: 'p1',
        initialRole: ProjectRole.admin,
        initialProjectName: 'Projeto',
      );

      await cubit.load();
      final created = await cubit.createSkill('Bateria');

      expect(created, isTrue);
      expect(repo.lastCreatedName, 'Bateria');
      expect(cubit.state.skills.map((skill) => skill.name), contains('Bateria'));

      await cubit.close();
    });

    test('member não pode criar ou excluir skills', () async {
      final repo = _FakeProjectSkillsRepository(
        role: ProjectRole.member,
        skills: const [ProjectSkillEntity(id: '1', name: 'Vocal')],
      );
      final cubit = ProjectSkillsCubit(
        repository: repo,
        projectId: 'p1',
      );

      await cubit.load();
      final created = await cubit.createSkill('Teclado');
      final deleted = await cubit.deleteSkill(
        const ProjectSkillEntity(id: '1', name: 'Vocal'),
      );

      expect(created, isFalse);
      expect(deleted, isFalse);
      expect(repo.lastCreatedName, isNull);
      expect(repo.deletedSkillId, isNull);

      await cubit.close();
    });
  });
}
