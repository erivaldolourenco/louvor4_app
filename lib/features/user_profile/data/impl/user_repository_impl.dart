import 'package:dio/dio.dart';
import 'package:louvor4_app/features/user_profile/data/user_repository.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/update_user_input_entity.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/user_detail_entity.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_message.dart';

class UserRepositoryImpl implements UserRepository {
  final Dio _dio;
  UserRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  @override
  Future<UserDetailEntity> getUserDetail() async {
    try {
      final response = await _dio.get('/users/detail');
      return UserDetailEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Não foi possível carregar os detalhes do perfil.',
        ),
      );
    }
  }

  @override
  Future<UserDetailEntity> updateUserProfile(
    UpdateUserInputEntity input,
  ) async {
    try {
      final response = await _dio.put('/users/update', data: input.toJson());
      return UserDetailEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Não foi possível atualizar seu perfil.',
        ),
      );
    }
  }

  @override
  Future<String> updateProfileImage({
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'profileImage': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });

    final response = await _dio.put(
      '/users/update/profile-image',
      data: formData,
    );

    return response.data.toString();
  }

  String _extractApiErrorMessage(
    DioException error, {
    required String fallback,
  }) =>
      extractApiErrorMessage(error, fallback: fallback);
}
