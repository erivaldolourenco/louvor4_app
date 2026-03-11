import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/project_role.dart';
import '../models/add_project_skill_request_model.dart';
import '../models/project_context_model.dart';
import '../models/project_skill_model.dart';

class ProjectSkillsRemoteDataSource {
  final Dio _dio;

  ProjectSkillsRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  Future<List<ProjectSkillModel>> getProjectSkills(String projectId) async {
    try {
      final response = await _dio.get('/music-project/$projectId/skills');
      final list = response.data as List;
      return list
          .map(
            (item) =>
                ProjectSkillModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_extractApiMessage(e));
    }
  }

  Future<ProjectRole> getMemberRole(String projectId) async {
    try {
      final response = await _dio.get('/music-project/$projectId/member-role');
      final data = response.data;

      if (data is String) {
        return projectRoleFromString(data);
      }

      if (data is Map<String, dynamic>) {
        return projectRoleFromString(data['role']?.toString());
      }

      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        return projectRoleFromString(map['role']?.toString());
      }

      throw Exception('Resposta inválida ao buscar papel no projeto.');
    } on DioException catch (e) {
      throw Exception(_extractApiMessage(e));
    }
  }

  Future<ProjectContextModel> getProjectContext(String projectId) async {
    try {
      final response = await _dio.get('/music-project/$projectId');
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return ProjectContextModel.fromJson(data);
      }

      if (data is Map) {
        return ProjectContextModel.fromJson(Map<String, dynamic>.from(data));
      }

      throw Exception('Resposta inválida ao buscar projeto.');
    } on DioException catch (e) {
      throw Exception(_extractApiMessage(e));
    }
  }

  Future<void> addProjectSkill(
    String projectId,
    AddProjectSkillRequestModel request,
  ) async {
    try {
      await _dio.post('/music-project/$projectId/skills', data: request.toJson());
    } on DioException catch (e) {
      throw Exception(_extractApiMessage(e));
    }
  }

  Future<void> deleteProjectSkill(String skillId) async {
    try {
      await _dio.delete('/skills/$skillId');
    } on DioException catch (e) {
      throw Exception(
        _extractApiMessage(
          e,
          fallback:
              'Não foi possível excluir a função. Verifique se ela está sendo usada em alguma escala.',
        ),
      );
    }
  }

  String _extractApiMessage(
    DioException error, {
    String fallback = 'Não foi possível concluir a operação.',
  }) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['detail'] ?? data['message'] ?? data['error'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message = map['detail'] ?? map['message'] ?? map['error'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    return error.message ?? fallback;
  }
}
