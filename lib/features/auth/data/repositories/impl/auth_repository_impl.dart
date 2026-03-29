import 'package:dio/dio.dart';
import 'package:louvor4_app/features/auth/domain/entities/authenticated_user_entity.dart';
import 'package:louvor4_app/features/auth/domain/exceptions/auth_request_exception.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../dtos/login_response_dto.dart';
import '../../../domain/entities/create_user_input_entity.dart';
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
      final response = await _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final login = LoginResponseDto.fromJson(data);

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
      final message = _extractApiErrorMessage(e);

      if (status == 401 || status == 403) {
        throw const AuthRequestException(
          message: 'Usuário ou senha inválidos',
          statusCode: 401,
        );
      }

      throw AuthRequestException(message: message, statusCode: status);
    }
  }

  @override
  Future<void> register(CreateUserInputEntity input) async {
    try {
      await _dio.post('/users/create', data: input.toJson());
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = _extractApiErrorMessage(e);
      throw AuthRequestException(message: message, statusCode: status);
    }
  }

  String _extractApiErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message =
          data['detail'] ?? data['message'] ?? data['error'] ?? data['title'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return e.message ?? e.error?.toString() ?? 'Erro ao conectar na API.';
  }
}
