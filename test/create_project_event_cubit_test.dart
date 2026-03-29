import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/music_projects/data/music_projects_repository.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/add_project_member_input.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/create_project_event_input.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/music_event_detail_entity.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/music_project_entity.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/project_member_entity.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/project_skill_entity.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/update_project_member_input.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/create_music_project_input.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/update_music_project_input.dart';
import 'package:louvor4_app/features/music_projects/presentation/cubit/create_project_event_cubit.dart';
import 'package:louvor4_app/features/music_projects/presentation/cubit/create_project_event_state.dart';

class _FakeMusicProjectsRepository implements MusicProjectsRepository {
  _FakeMusicProjectsRepository({this.shouldThrow = false});

  final bool shouldThrow;
  CreateProjectEventInput? lastCreatedEvent;

  @override
  Future<void> createProjectEvent(
    String projectId,
    CreateProjectEventInput input,
  ) async {
    if (shouldThrow) {
      throw Exception('falha ao criar');
    }
    lastCreatedEvent = input;
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
  Future<List<ProjectSkillEntity>> getProjectSkills(String projectId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<MusicProjectEntity>> getUserMusicProjects() async {
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
  Future<MusicProjectEntity> createProject(
      CreateMusicProjectInput input) async {
    throw UnimplementedError();
  }

  @override
  Future<MusicProjectEntity> updateProject(
      String projectId, UpdateMusicProjectInput input) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateProjectProfileImage({
    required String projectId,
    required String filePath,
    required String fileName,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  group('CreateProjectEventCubit', () {
    test('envia criação com sucesso', () async {
      final repo = _FakeMusicProjectsRepository();
      final cubit = CreateProjectEventCubit(repo);

      final success = await cubit.submit(
        projectId: 'p1',
        input: const CreateProjectEventInput(
          title: 'Culto Domingo',
          description: 'Santa Ceia',
          startDate: '2026-03-15',
          startTime: '19:30',
          location: 'Igreja Central',
        ),
      );

      expect(success, isTrue);
      expect(cubit.state.status, CreateProjectEventStatus.success);
      expect(repo.lastCreatedEvent?.title, 'Culto Domingo');

      await cubit.close();
    });

    test('vai para error quando repositório falha', () async {
      final cubit = CreateProjectEventCubit(
        _FakeMusicProjectsRepository(shouldThrow: true),
      );

      final success = await cubit.submit(
        projectId: 'p1',
        input: const CreateProjectEventInput(
          title: 'Culto Domingo',
          description: null,
          startDate: '2026-03-15',
          startTime: '19:30',
          location: 'Igreja Central',
        ),
      );

      expect(success, isFalse);
      expect(cubit.state.status, CreateProjectEventStatus.error);
      expect(cubit.state.errorMessage, contains('falha'));

      await cubit.close();
    });
  });
}
