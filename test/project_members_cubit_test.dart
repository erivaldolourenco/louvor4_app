import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/music_projects/data/music_projects_repository.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/add_project_member_input.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/create_project_event_input.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/music_event_detail_entity.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/music_project_entity.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/project_member_entity.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/project_member_role.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/project_skill_entity.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/update_project_member_input.dart';
import 'package:louvor4_app/features/music_projects/presentation/cubit/project_members_cubit.dart';
import 'package:louvor4_app/features/music_projects/presentation/cubit/project_members_state.dart';

class _FakeMusicProjectsRepository implements MusicProjectsRepository {
  _FakeMusicProjectsRepository({this.members = const [], this.skills = const []});

  List<ProjectMemberEntity> members;
  List<ProjectSkillEntity> skills;
  AddProjectMemberInput? lastAddInput;
  UpdateProjectMemberInput? lastUpdateInput;
  String? removedMemberId;

  @override
  Future<void> addProjectMember(
    String projectId,
    AddProjectMemberInput input,
  ) async {
    lastAddInput = input;
    members = [
      ...members,
      ProjectMemberEntity(
        id: 'new-member',
        userId: 'user-new',
        username: input.username,
        firstName: 'Novo',
        lastName: 'Membro',
        email: '${input.username}@mail.com',
        profileImage: null,
        projectRole: ProjectMemberRole.member,
        skillIds: const [],
      ),
    ];
  }

  @override
  Future<ProjectMemberEntity> getProjectMember(
    String projectId,
    String memberId,
  ) async {
    return members.firstWhere((member) => member.id == memberId);
  }

  @override
  Future<List<ProjectMemberEntity>> getProjectMembers(String projectId) async {
    return members;
  }

  @override
  Future<List<ProjectSkillEntity>> getProjectSkills(String projectId) async {
    return skills;
  }

  @override
  Future<void> removeProjectMember(String projectId, String memberId) async {
    removedMemberId = memberId;
    members = members.where((member) => member.id != memberId).toList();
  }

  @override
  Future<void> updateProjectMember(
    String projectId,
    String memberId,
    UpdateProjectMemberInput input,
  ) async {
    lastUpdateInput = input;
    members = members.map((member) {
      if (member.id != memberId) return member;
      return ProjectMemberEntity(
        id: member.id,
        userId: member.userId,
        username: member.username,
        firstName: member.firstName,
        lastName: member.lastName,
        email: member.email,
        profileImage: member.profileImage,
        projectRole: input.projectRole,
        skillIds: input.skillIds,
      );
    }).toList();
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
  Future<List<MusicProjectEntity>> getUserMusicProjects() async {
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
  group('ProjectMembersCubit', () {
    test('carrega membros e skills ordenando owner antes dos demais', () async {
      final repo = _FakeMusicProjectsRepository(
        members: const [
          ProjectMemberEntity(
            id: 'm2',
            userId: 'u2',
            username: 'ana',
            firstName: 'Ana',
            lastName: 'Silva',
            email: 'ana@mail.com',
            profileImage: null,
            projectRole: ProjectMemberRole.member,
            skillIds: ['s1'],
          ),
          ProjectMemberEntity(
            id: 'm1',
            userId: 'u1',
            username: 'owner',
            firstName: 'Carlos',
            lastName: 'Lima',
            email: 'carlos@mail.com',
            profileImage: null,
            projectRole: ProjectMemberRole.owner,
            skillIds: [],
          ),
        ],
        skills: const [ProjectSkillEntity(id: 's1', name: 'Vocal')],
      );

      final cubit = ProjectMembersCubit(
        repository: repo,
        projectId: 'p1',
        canManageMembers: true,
      );

      await cubit.load();

      expect(cubit.state.status, ProjectMembersStatus.success);
      expect(cubit.state.members.first.projectRole, ProjectMemberRole.owner);
      expect(cubit.state.skills.single.name, 'Vocal');

      await cubit.close();
    });

    test('não permite remover owner', () async {
      const owner = ProjectMemberEntity(
        id: 'm1',
        userId: 'u1',
        username: 'owner',
        firstName: 'Carlos',
        lastName: 'Lima',
        email: 'carlos@mail.com',
        profileImage: null,
        projectRole: ProjectMemberRole.owner,
        skillIds: [],
      );

      final repo = _FakeMusicProjectsRepository(members: const [owner]);
      final cubit = ProjectMembersCubit(
        repository: repo,
        projectId: 'p1',
        canManageMembers: true,
      );

      final removed = await cubit.removeMember(owner);

      expect(removed, isFalse);
      expect(repo.removedMemberId, isNull);
      expect(cubit.state.actionErrorMessage, contains('owner'));

      await cubit.close();
    });

    test('atualiza membro e recarrega a lista após salvar', () async {
      const member = ProjectMemberEntity(
        id: 'm2',
        userId: 'u2',
        username: 'ana',
        firstName: 'Ana',
        lastName: 'Silva',
        email: 'ana@mail.com',
        profileImage: null,
        projectRole: ProjectMemberRole.member,
        skillIds: ['s1'],
      );

      final repo = _FakeMusicProjectsRepository(
        members: const [member],
        skills: const [
          ProjectSkillEntity(id: 's1', name: 'Vocal'),
          ProjectSkillEntity(id: 's2', name: 'Teclado'),
        ],
      );

      final cubit = ProjectMembersCubit(
        repository: repo,
        projectId: 'p1',
        canManageMembers: true,
      );

      await cubit.load();
      final updated = await cubit.updateMember(
        member: member,
        projectRole: ProjectMemberRole.admin,
        skillIds: const ['s2'],
      );

      expect(updated, isTrue);
      expect(repo.lastUpdateInput?.projectRole, ProjectMemberRole.admin);
      expect(cubit.state.members.single.projectRole, ProjectMemberRole.admin);
      expect(cubit.state.members.single.skillIds, ['s2']);

      await cubit.close();
    });
  });
}
