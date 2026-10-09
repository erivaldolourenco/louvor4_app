import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_message.dart';
import '../../domain/entities/my_responsibility_entity.dart';
import '../../domain/entities/responsibility_entity.dart';
import '../responsibilities_repository.dart';

class ResponsibilitiesRepositoryImpl implements ResponsibilitiesRepository {
  final Dio _dio;

  ResponsibilitiesRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  String _base(String projectId) =>
      '/music-project/$projectId/responsibilities';

  @override
  Future<List<ResponsibilityEntity>> getResponsibilities(
    String projectId,
  ) async {
    try {
      final response = await _dio.get(_base(projectId));
      return (response.data as List)
          .map(
            (item) => ResponsibilityEntity.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        extractApiErrorMessage(
          e,
          fallback: 'Não foi possível carregar o mural.',
        ),
      );
    }
  }

  @override
  Future<ResponsibilityEntity> createResponsibility(
    String projectId, {
    required String name,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        _base(projectId),
        data: {'name': name, 'description': description},
      );
      return ResponsibilityEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        extractApiErrorMessage(
          e,
          fallback: 'Não foi possível criar a responsabilidade.',
        ),
      );
    }
  }

  @override
  Future<ResponsibilityEntity> updateResponsibility(
    String projectId,
    String responsibilityId, {
    required String name,
    String? description,
  }) async {
    try {
      final response = await _dio.put(
        '${_base(projectId)}/$responsibilityId',
        data: {'name': name, 'description': description},
      );
      return ResponsibilityEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        extractApiErrorMessage(
          e,
          fallback: 'Não foi possível atualizar a responsabilidade.',
        ),
      );
    }
  }

  @override
  Future<void> deleteResponsibility(
    String projectId,
    String responsibilityId,
  ) async {
    try {
      await _dio.delete('${_base(projectId)}/$responsibilityId');
    } on DioException catch (e) {
      throw Exception(
        extractApiErrorMessage(
          e,
          fallback: 'Não foi possível excluir a responsabilidade.',
        ),
      );
    }
  }

  @override
  Future<List<ResponsibilityAssignmentEntity>> getHistory(
    String projectId,
    String responsibilityId,
  ) async {
    try {
      final response = await _dio.get(
        '${_base(projectId)}/$responsibilityId/assignments',
      );
      return (response.data as List)
          .map(
            (item) => ResponsibilityAssignmentEntity.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        extractApiErrorMessage(
          e,
          fallback: 'Não foi possível carregar o histórico.',
        ),
      );
    }
  }

  @override
  Future<ResponsibilityAssignmentEntity> assignMember(
    String projectId,
    String responsibilityId, {
    required String memberId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.post(
        '${_base(projectId)}/$responsibilityId/assignments',
        data: _assignmentBody(memberId, startDate, endDate),
      );
      return ResponsibilityAssignmentEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        extractApiErrorMessage(
          e,
          fallback: 'Não foi possível definir o responsável.',
        ),
      );
    }
  }

  @override
  Future<ResponsibilityAssignmentEntity> updateAssignment(
    String projectId,
    String responsibilityId,
    String assignmentId, {
    required String memberId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.put(
        '${_base(projectId)}/$responsibilityId/assignments/$assignmentId',
        data: _assignmentBody(memberId, startDate, endDate),
      );
      return ResponsibilityAssignmentEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        extractApiErrorMessage(
          e,
          fallback: 'Não foi possível atualizar o período.',
        ),
      );
    }
  }

  @override
  Future<void> deleteAssignment(
    String projectId,
    String responsibilityId,
    String assignmentId,
  ) async {
    try {
      await _dio.delete(
        '${_base(projectId)}/$responsibilityId/assignments/$assignmentId',
      );
    } on DioException catch (e) {
      throw Exception(
        extractApiErrorMessage(
          e,
          fallback: 'Não foi possível excluir o período.',
        ),
      );
    }
  }

  @override
  Future<List<MyResponsibilityEntity>> getMyResponsibilities() async {
    try {
      final response = await _dio.get('/users/responsibilities');
      return (response.data as List)
          .map(
            (item) => MyResponsibilityEntity.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        extractApiErrorMessage(
          e,
          fallback: 'Não foi possível carregar suas responsabilidades.',
        ),
      );
    }
  }

  Map<String, dynamic> _assignmentBody(
    String memberId,
    DateTime startDate,
    DateTime endDate,
  ) => {
    'memberId': memberId,
    'startDate': formatApiDate(startDate),
    'endDate': formatApiDate(endDate),
  };
}
