import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/music_projects/data/music_projects_repository.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/add_project_member_input.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/create_project_event_input.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/music_event_detail_entity.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/music_project_entity.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/project_member_entity.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/project_skill_entity.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/update_project_member_input.dart';
import 'package:louvor4_app/features/music_projects/presentation/cubit/project_cubit.dart';
import 'package:louvor4_app/features/music_projects/presentation/cubit/project_state.dart';

class _FakeMusicProjectsRepository implements MusicProjectsRepository {
  _FakeMusicProjectsRepository({
    this.projects = const [],
    this.shouldThrow = false,
  });

  final List<MusicProjectEntity> projects;
  final bool shouldThrow;

  @override
  Future<List<MusicProjectEntity>> getUserMusicProjects() async {
    if (shouldThrow) throw Exception('falha');
    return projects;
  }

  @override
  Future<MusicProjectEntity> getProjectById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<List<MusicEventDetailEntity>> getProjectEvents(
    String projectId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<String> getMemberRole(String projectId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> addProjectMember(
    String projectId,
    AddProjectMemberInput input,
  ) async {
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
  Future<List<ProjectMemberEntity>> getProjectMembers(String projectId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ProjectSkillEntity>> getProjectSkills(String projectId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> removeProjectMember(String projectId, String memberId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateProjectMember(
    String projectId,
    String memberId,
    UpdateProjectMemberInput input,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> createProjectEvent(
    String projectId,
    CreateProjectEventInput input,
  ) async {
    throw UnimplementedError();
  }
}

void main() {
  group('ProjectCubit', () {
    test('carrega projetos com sucesso e mantém status success', () async {
      final repo = _FakeMusicProjectsRepository(
        projects: const [
          MusicProjectEntity(
            id: '1',
            name: 'Banda 1',
            type: MusicProjectType.band,
          ),
          MusicProjectEntity(
            id: '2',
            name: 'Ministério 1',
            type: MusicProjectType.ministry,
          ),
        ],
      );

      final cubit = ProjectCubit(repo);
      await cubit.loadProjects();

      expect(cubit.state.status, ProjectStatus.success);
      expect(cubit.state.projects.length, 2);
      expect(cubit.state.activeProject, isNull);

      await cubit.close();
    });

    test('define projeto ativo ao selecionar', () async {
      const project = MusicProjectEntity(
        id: 'p1',
        name: 'Projeto A',
        type: MusicProjectType.singer,
      );

      final cubit = ProjectCubit(
        _FakeMusicProjectsRepository(projects: const [project]),
      );
      await cubit.loadProjects();
      cubit.selectProject(project);

      expect(cubit.state.activeProject, project);

      await cubit.close();
    });

    test('vai para failure quando repositório falha', () async {
      final cubit = ProjectCubit(
        _FakeMusicProjectsRepository(shouldThrow: true),
      );

      await cubit.loadProjects();

      expect(cubit.state.status, ProjectStatus.failure);
      expect(cubit.state.errorMessage, isNotEmpty);

      await cubit.close();
    });
  });
}
