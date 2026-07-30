import 'package:dio/dio.dart';
import 'package:louvor4_app/features/auth/domain/entities/authenticated_user_entity.dart';
import 'package:louvor4_app/features/auth/domain/entities/forgot_password_channels_entity.dart';
import 'package:louvor4_app/features/auth/domain/exceptions/auth_request_exception.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_error_message.dart';
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

      return AuthenticatedUserEntity(
        accessToken: login.accessToken,
        refreshToken: login.refreshToken,
        expiresAt: login.expiresAt,
        user: _userFromJson(login.user),
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
  Future<AuthenticatedUserEntity> loginWithGoogle(String idToken) async {
    try {
      final response = await _dio.post(
        '/auth/login/google',
        data: {'idToken': idToken},
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

      return AuthenticatedUserEntity(
        accessToken: login.accessToken,
        refreshToken: login.refreshToken,
        expiresAt: login.expiresAt,
        user: _userFromJson(login.user),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = _extractApiErrorMessage(e);
      throw AuthRequestException(message: message, statusCode: status);
    }
  }

  UserEntity _userFromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'].toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      planName: json['planName']?.toString(),
      profileImage: json['profileImage']?.toString(),
      profileImageHash: json['profileImageHash']?.toString(),
    );
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

  @override
  Future<ForgotPasswordChannelsEntity> getAvailableChannels(String identifier) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password/channels',
        data: {'identifier': identifier},
      );
      final data = response.data as Map<String, dynamic>;
      return ForgotPasswordChannelsEntity(
        maskedEmail: data['maskedEmail'] as String,
        maskedPhone: data['maskedPhone'] as String?,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = _extractApiErrorMessage(e);
      throw AuthRequestException(message: message, statusCode: status);
    }
  }

  @override
  Future<void> forgotPassword({required String identifier, required String channel}) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'identifier': identifier, 'channel': channel});
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = _extractApiErrorMessage(e);
      throw AuthRequestException(message: message, statusCode: status);
    }
  }

  @override
  Future<void> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _dio.post('/auth/reset-password', data: {
        'identifier': identifier,
        'code': code,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = _extractApiErrorMessage(e);
      throw AuthRequestException(message: message, statusCode: status);
    }
  }

  String _extractApiErrorMessage(DioException e) {
    if (e.response == null) return extractApiErrorMessage(e);

    final data = e.response!.data;
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
