import 'package:dio/dio.dart';
import 'package:louvor4_app/core/network/api_client.dart';
import 'package:louvor4_app/core/network/api_error_message.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/music_project_entity.dart';

import '../../domain/entities/create_user_unavailability_input_entity.dart';
import '../../domain/entities/user_unavailability_entity.dart';
import '../user_unavailability_repository.dart';

class UserUnavailabilityRepositoryImpl implements UserUnavailabilityRepository {
  final Dio _dio;

  UserUnavailabilityRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.dio;

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
    } on DioException catch (error) {
      throw Exception(
        _extractApiErrorMessage(
          error,
          fallback: 'Não foi possível carregar seus projetos.',
        ),
      );
    }
  }

  @override
  Future<List<UserUnavailabilityEntity>> getUserUnavailabilities() async {
    try {
      final response = await _dio.get('/users/unavailabilities');
      final list = response.data as List;

      return list
          .map(
            (item) => UserUnavailabilityEntity.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw Exception(
        _extractApiErrorMessage(
          error,
          fallback: 'Não foi possível carregar suas indisponibilidades.',
        ),
      );
    }
  }

  @override
  Future<UserUnavailabilityEntity> createUserUnavailability(
    CreateUserUnavailabilityInputEntity input,
  ) async {
    try {
      final response = await _dio.post(
        '/users/unavailabilities',
        data: input.toJson(),
      );

      return UserUnavailabilityEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw Exception(
        _extractApiErrorMessage(
          error,
          fallback: 'Não foi possível salvar a indisponibilidade.',
        ),
      );
    }
  }

  @override
  Future<void> deleteUserUnavailability(String unavailabilityId) async {
    try {
      await _dio.delete('/users/unavailabilities/$unavailabilityId');
    } on DioException catch (error) {
      throw Exception(
        _extractApiErrorMessage(
          error,
          fallback: 'Não foi possível excluir a indisponibilidade.',
        ),
      );
    }
  }

  String _extractApiErrorMessage(
    DioException error, {
    required String fallback,
  }) {
    if (error.response == null) return extractApiErrorMessage(error, fallback: fallback);

    final data = error.response!.data;

    if (data is Map<String, dynamic>) {
      final nestedError = data['error'];
      if (nestedError is Map<String, dynamic>) {
        final detail = nestedError['detail'];
        if (detail != null && detail.toString().trim().isNotEmpty) {
          return detail.toString();
        }
      }

      final detail = data['detail'] ?? data['message'];
      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString();
      }
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final nestedError = map['error'];
      if (nestedError is Map) {
        final nestedMap = Map<String, dynamic>.from(nestedError);
        final detail = nestedMap['detail'];
        if (detail != null && detail.toString().trim().isNotEmpty) {
          return detail.toString();
        }
      }

      final detail = map['detail'] ?? map['message'];
      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString();
      }
    }

    return error.message ?? fallback;
  }
}
