import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:louvor4_app/features/auth/domain/entities/authenticated_user_entity.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../../domain/entities/user_entity.dart';
import '../auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;

  AuthRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  @override
  Future<AuthenticatedUserEntity> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login', // <-- ajuste se sua rota for diferente
        data: {
          'username': username, // <-- se sua API usa 'email' troque aqui
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (kDebugMode) {
        print(data);
      }

      final token = data['token'] as String;
      await TokenStorage().saveToken(token);
      final userJson = Map<String, dynamic>.from(data['user'] as Map);

      final user = UserEntity(
        id: userJson['id'].toString(),
        firstName: (userJson['firstName'] ?? '').toString(),
        lastName: (userJson['lastName'] ?? '').toString(),
        email: (userJson['email'] ?? '').toString(),
      );

      return AuthenticatedUserEntity(
        token: token,
        user: user,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;

      if (status == 401 || status == 403) {
        throw Exception('Usuário ou senha inválidos');
      }

      // Se sua API retorna mensagem em JSON, dá pra melhorar isso depois
      throw Exception('Erro ao conectar na API (${status ?? 'sem status'})');
    }
  }
}