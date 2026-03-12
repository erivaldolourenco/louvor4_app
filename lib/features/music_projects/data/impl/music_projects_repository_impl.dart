import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/add_project_member_input.dart';
import '../../domain/entities/create_project_event_input.dart';
import '../../domain/entities/music_event_detail_entity.dart';
import '../../domain/entities/music_project_entity.dart';
import '../../domain/entities/project_member_entity.dart';
import '../../domain/entities/project_skill_entity.dart';
import '../../domain/entities/update_music_project_input.dart';
import '../../domain/entities/update_project_member_input.dart';
import '../music_projects_repository.dart';

class MusicProjectsRepositoryImpl implements MusicProjectsRepository {
  final Dio _dio;

  MusicProjectsRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  @override
  Future<List<MusicProjectEntity>> getUserMusicProjects() async {
    try {
      final response = await _dio.get('/users/music-projects');
      final list = response.data as List;
      return list
          .map(
            (item) => MusicProjectEntity.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<MusicProjectEntity> getProjectById(String id) async {
    try {
      final response = await _dio.get('/music-project/$id');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return MusicProjectEntity.fromJson(data);
      }
      if (data is Map) {
        return MusicProjectEntity.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Resposta inválida ao buscar projeto.');
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<List<MusicEventDetailEntity>> getProjectEvents(
    String projectId,
  ) async {
    try {
      final response = await _dio.get('/music-project/$projectId/events');
      final list = response.data as List;

      return list
          .map(
            (item) => MusicEventDetailEntity.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<String> getMemberRole(String projectId) async {
    try {
      final response = await _dio.get('/music-project/$projectId/member-role');
      final data = response.data;

      if (data is String) {
        return data.toUpperCase();
      }

      if (data is Map<String, dynamic>) {
        return (data['role'] ?? '').toString().toUpperCase();
      }

      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        return (map['role'] ?? '').toString().toUpperCase();
      }

      throw Exception('Resposta inválida ao buscar permissão do projeto.');
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<List<ProjectMemberEntity>> getProjectMembers(String projectId) async {
    try {
      final response = await _dio.get('/music-project/$projectId/members');
      final list = response.data as List;
      return list
          .map(
            (item) => ProjectMemberEntity.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<ProjectMemberEntity> getProjectMember(
    String projectId,
    String memberId,
  ) async {
    try {
      final response = await _dio.get(
        '/music-project/$projectId/members/$memberId',
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ProjectMemberEntity.fromJson(data);
      }
      if (data is Map) {
        return ProjectMemberEntity.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Resposta inválida ao buscar membro do projeto.');
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<void> addProjectMember(
    String projectId,
    AddProjectMemberInput input,
  ) async {
    try {
      await _dio.post(
        '/music-project/$projectId/members',
        data: input.toJson(),
      );
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<void> updateProjectMember(
    String projectId,
    String memberId,
    UpdateProjectMemberInput input,
  ) async {
    try {
      await _dio.put(
        '/music-project/$projectId/members/$memberId',
        data: input.toJson(),
      );
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<void> removeProjectMember(String projectId, String memberId) async {
    try {
      await _dio.delete('/music-project/$projectId/members/$memberId');
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<List<ProjectSkillEntity>> getProjectSkills(String projectId) async {
    try {
      final response = await _dio.get('/music-project/$projectId/skills');
      final list = response.data as List;
      return list
          .map(
            (item) => ProjectSkillEntity.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<void> createProjectEvent(
    String projectId,
    CreateProjectEventInput input,
  ) async {
    try {
      await _dio.post('/music-project/$projectId/events', data: input.toJson());
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Não foi possível adicionar o evento. Tente novamente.',
        ),
      );
    }
  }

  @override
  Future<MusicProjectEntity> updateProject(
    String projectId,
    UpdateMusicProjectInput input,
  ) async {
    try {
      final response = await _dio.put(
        '/music-project/$projectId',
        data: input.toJson(),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return MusicProjectEntity.fromJson(data);
      }
      if (data is Map) {
        return MusicProjectEntity.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Resposta inválida ao atualizar projeto.');
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Não foi possível atualizar o projeto.',
        ),
      );
    }
  }

  @override
  Future<void> updateProjectProfileImage({
    required String projectId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'profileImage': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      await _dio.put('/music-project/$projectId/profile-image', data: formData);
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Não foi possível atualizar a imagem do projeto.',
        ),
      );
    }
  }

  String _extractApiErrorMessage(
    DioException e, {
    String fallback = 'Erro inesperado',
  }) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      return (data['detail'] ?? data['message'] ?? data['details'] ?? fallback)
          .toString();
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      return (map['detail'] ?? map['message'] ?? map['details'] ?? fallback)
          .toString();
    }

    return e.message ?? fallback;
  }
}
