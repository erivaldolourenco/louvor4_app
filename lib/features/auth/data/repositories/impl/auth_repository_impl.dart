import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:louvor4_app/features/auth/domain/entities/authenticated_user_entity.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../dtos/login_response_dto.dart';
import '../../../domain/entities/user_entity.dart';
import '../auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;

  AuthRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  @override
  Future<AuthenticatedUserEntity> login(
    String username,
    String password,
  ) async {
    try {
      print(_dio.options.baseUrl);
      final response = await _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      print(response);

      final data = response.data as Map<String, dynamic>;
      final login = LoginResponseDto.fromJson(data);

      if (kDebugMode) {
        print(data);
      }

      if (login.accessToken.isEmpty || login.refreshToken.isEmpty) {
        throw Exception('Resposta de autenticação inválida');
      }

      await TokenStorage().saveSession(
        accessToken: login.accessToken,
        refreshToken: login.refreshToken,
        expiresAt: login.expiresAt,
      );
      final userJson = login.user;

      final user = UserEntity(
        id: userJson['id'].toString(),
        firstName: (userJson['firstName'] ?? '').toString(),
        lastName: (userJson['lastName'] ?? '').toString(),
        email: (userJson['email'] ?? '').toString(),
      );

      return AuthenticatedUserEntity(
        accessToken: login.accessToken,
        refreshToken: login.refreshToken,
        expiresAt: login.expiresAt,
        user: user,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final networkReason = e.message ?? e.error?.toString() ?? e.type.name;

      if (status == 401 || status == 403) {
        throw Exception('Usuário ou senha inválidos');
      }

      throw Exception(
        'Erro ao conectar na API (${status ?? 'sem status'}): $networkReason',
      );
    }
  }
}
