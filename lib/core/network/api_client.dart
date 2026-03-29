import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_service.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient._();

  static final TokenStorage _tokenStorage = TokenStorage();
  static final AuthService _authService = AuthService.instance;
  static bool _isRefreshing = false;
  static Future<bool>? _refreshFuture;

  static String _resolveBaseUrl() {
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (apiBaseUrl.isNotEmpty) return apiBaseUrl;

    // Android emulator uses 10.0.2.2 to reach host machine localhost.
    // Keep this only for local debug builds; real devices/release should use production.
    if (!kIsWeb &&
        !kReleaseMode &&
        defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }

    return 'https://api.louvor4.com.br';
  }

  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: _resolveBaseUrl(),
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await _tokenStorage.getAccessToken();

              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }

              handler.next(options);
            },
            onError: (error, handler) async {
              final status = error.response?.statusCode;
              final options = error.requestOptions;

              if (status != 401 ||
                  options.extra['retried_after_refresh'] == true ||
                  _isAuthPath(options.path)) {
                handler.next(error);
                return;
              }

              final refreshed = await _refreshSession();
              if (!refreshed) {
                if (kDebugMode) {
                  print('Refresh falhou -> limpando sessão');
                }
                await _tokenStorage.clearSession();
                handler.next(error);
                return;
              }

              final accessToken = await _tokenStorage.getAccessToken();
              if (accessToken == null || accessToken.isEmpty) {
                await _tokenStorage.clearSession();
                handler.next(error);
                return;
              }

              options.headers['Authorization'] = 'Bearer $accessToken';
              options.extra['retried_after_refresh'] = true;

              try {
                final retryResponse = await dio.fetch(options);
                handler.resolve(retryResponse);
              } on DioException catch (retryError) {
                handler.next(retryError);
              }
            },
          ),
        );

  static bool _isAuthPath(String path) {
    final normalized = path.toLowerCase();
    return normalized.contains('/auth/login') ||
        normalized.contains('/auth/refresh') ||
        normalized.contains('/auth/logout');
  }

  static Future<bool> _refreshSession() async {
    if (_isRefreshing) {
      return await (_refreshFuture ?? Future.value(false));
    }

    _isRefreshing = true;
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: _resolveBaseUrl(),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _refreshFuture = _authService.refreshSession(refreshDio);
    try {
      final result = await _refreshFuture!;
      return result;
    } finally {
      _refreshFuture = null;
      _isRefreshing = false;
    }
  }
}
