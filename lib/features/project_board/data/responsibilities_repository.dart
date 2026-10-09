import '../domain/entities/my_responsibility_entity.dart';
import '../domain/entities/responsibility_entity.dart';

abstract class ResponsibilitiesRepository {
  Future<List<ResponsibilityEntity>> getResponsibilities(String projectId);

  Future<ResponsibilityEntity> createResponsibility(
    String projectId, {
    required String name,
    String? description,
  });

  Future<ResponsibilityEntity> updateResponsibility(
    String projectId,
    String responsibilityId, {
    required String name,
    String? description,
  });

  Future<void> deleteResponsibility(String projectId, String responsibilityId);

  Future<List<ResponsibilityAssignmentEntity>> getHistory(
    String projectId,
    String responsibilityId,
  );

  /// Define um responsável para o período (troca de responsável). A API
  /// encerra o período anterior no dia anterior ao novo início.
  Future<ResponsibilityAssignmentEntity> assignMember(
    String projectId,
    String responsibilityId, {
    required String memberId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Corrige um período existente (membro e/ou datas).
  Future<ResponsibilityAssignmentEntity> updateAssignment(
    String projectId,
    String responsibilityId,
    String assignmentId, {
    required String memberId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<void> deleteAssignment(
    String projectId,
    String responsibilityId,
    String assignmentId,
  );

  /// Responsabilidades vigentes e agendadas do usuário logado, em todos os projetos.
  Future<List<MyResponsibilityEntity>> getMyResponsibilities();
}
