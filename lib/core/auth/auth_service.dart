import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/data/dtos/refresh_response_dto.dart';
import '../storage/token_storage.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  final TokenStorage _tokenStorage = TokenStorage();

  Future<bool> refreshSession(Dio dio) async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await dio.post('/auth/refresh', data: refreshToken);
      final data = Map<String, dynamic>.from(response.data as Map);
      final refresh = RefreshResponseDto.fromJson(data);

      if (refresh.accessToken.isEmpty) return false;

      await _tokenStorage.saveAccessToken(refresh.accessToken);

      if (refresh.refreshToken != null && refresh.refreshToken!.isNotEmpty) {
        await _tokenStorage.saveSession(
          accessToken: refresh.accessToken,
          refreshToken: refresh.refreshToken!,
          expiresAt: refresh.expiresAt,
        );
      } else if (refresh.expiresAt != null && refresh.expiresAt!.isNotEmpty) {
        await _tokenStorage.saveSession(
          accessToken: refresh.accessToken,
          refreshToken: refreshToken,
          expiresAt: refresh.expiresAt,
        );
      }

      return true;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Falha no refresh: ${e.response?.statusCode} ${e.message}');
      }
      return false;
    }
  }

  Future<void> logout(Dio dio) async {
    final refreshToken = await _tokenStorage.getRefreshToken();

    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await dio.post('/auth/logout', data: refreshToken);
      } catch (_) {
        // Mesmo com erro de rede, limpamos a sessão local.
      }
    }

    await _tokenStorage.clearSession();
  }
}
