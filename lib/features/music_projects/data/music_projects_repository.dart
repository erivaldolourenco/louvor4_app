import '../domain/entities/create_project_event_input.dart';
import '../domain/entities/add_project_member_input.dart';
import '../domain/entities/project_member_entity.dart';
import '../domain/entities/project_skill_entity.dart';
import '../domain/entities/update_project_member_input.dart';
import '../domain/entities/music_event_detail_entity.dart';
import '../domain/entities/music_project_entity.dart';

abstract class MusicProjectsRepository {
  Future<List<MusicProjectEntity>> getUserMusicProjects();

  Future<MusicProjectEntity> getProjectById(String id);

  Future<List<MusicEventDetailEntity>> getProjectEvents(String projectId);

  Future<String> getMemberRole(String projectId);

  Future<List<ProjectMemberEntity>> getProjectMembers(String projectId);

  Future<ProjectMemberEntity> getProjectMember(String projectId, String memberId);

  Future<void> addProjectMember(String projectId, AddProjectMemberInput input);

  Future<void> updateProjectMember(
    String projectId,
    String memberId,
    UpdateProjectMemberInput input,
  );

  Future<void> removeProjectMember(String projectId, String memberId);

  Future<List<ProjectSkillEntity>> getProjectSkills(String projectId);

  Future<void> createProjectEvent(
    String projectId,
    CreateProjectEventInput input,
  );
}
