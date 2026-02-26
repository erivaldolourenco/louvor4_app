import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.0.101:8080',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage().getToken();

        if (kDebugMode) {
          print('TOKEN LIDO: ${token?.substring(0, 10)}...');
        }

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        handler.next(options);
      },

      onError: (error, handler) async {
        final status = error.response?.statusCode;

        if (status == 401) {
          if (kDebugMode) {
            print('Token expirado -> limpando storage');
          }

          await TokenStorage().clearToken();
          // depois vamos redirecionar pro login
        }

        handler.next(error);
      },
    ),
  );
}