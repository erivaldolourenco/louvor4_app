import '../../domain/entities/project_context_entity.dart';
import '../../domain/entities/project_role.dart';
import '../../domain/entities/project_skill_entity.dart';
import '../datasources/project_skills_remote_datasource.dart';
import '../models/add_project_skill_request_model.dart';
import 'project_skills_repository.dart';

class ProjectSkillsRepositoryImpl implements ProjectSkillsRepository {
  final ProjectSkillsRemoteDataSource _remoteDataSource;

  ProjectSkillsRepositoryImpl({ProjectSkillsRemoteDataSource? remoteDataSource})
    : _remoteDataSource =
          remoteDataSource ?? ProjectSkillsRemoteDataSource();

  @override
  Future<void> addProjectSkill(String projectId, String name) {
    return _remoteDataSource.addProjectSkill(
      projectId,
      AddProjectSkillRequestModel(name: name),
    );
  }

  @override
  Future<void> deleteProjectSkill(String skillId) {
    return _remoteDataSource.deleteProjectSkill(skillId);
  }

  @override
  Future<ProjectRole> getMemberRole(String projectId) {
    return _remoteDataSource.getMemberRole(projectId);
  }

  @override
  Future<ProjectContextEntity> getProjectContext(String projectId) {
    return _remoteDataSource.getProjectContext(projectId);
  }

  @override
  Future<List<ProjectSkillEntity>> getProjectSkills(String projectId) {
    return _remoteDataSource.getProjectSkills(projectId);
  }
}
