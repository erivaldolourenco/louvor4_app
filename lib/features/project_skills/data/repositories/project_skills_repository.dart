import '../../domain/entities/project_context_entity.dart';
import '../../domain/entities/project_role.dart';
import '../../domain/entities/project_skill_entity.dart';

abstract class ProjectSkillsRepository {
  Future<ProjectRole> getMemberRole(String projectId);

  Future<ProjectContextEntity> getProjectContext(String projectId);

  Future<List<ProjectSkillEntity>> getProjectSkills(String projectId);

  Future<void> addProjectSkill(String projectId, String name);

  Future<void> deleteProjectSkill(String skillId);
}
