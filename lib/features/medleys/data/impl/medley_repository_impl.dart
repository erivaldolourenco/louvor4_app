import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/create_medley_input_entity.dart';
import '../../domain/entities/medley_entity.dart';
import '../medley_repository.dart';

class MedleyRepositoryImpl implements MedleyRepository {
  final Dio _dio;

  MedleyRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  @override
  Future<List<MedleyEntity>> getUserMedleys() async {
    try {
      final response = await _dio.get('/users/medleys');
      final list = response.data as List;
      return list
          .map(
            (e) => MedleyEntity.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Não foi possível carregar seus medleys.',
        ),
      );
    }
  }

  @override
  Future<MedleyEntity> createMedley(CreateMedleyInputEntity input) async {
    try {
      final response = await _dio.post(
        '/medleys/create',
        data: input.toJson(),
      );
      return MedleyEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(e, fallback: 'Não foi possível criar o medley.'),
      );
    }
  }

  @override
  Future<MedleyEntity> updateMedley(
    String id,
    CreateMedleyInputEntity input,
  ) async {
    try {
      final response = await _dio.put(
        '/medleys/$id/update',
        data: input.toJson(),
      );
      return MedleyEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Não foi possível atualizar o medley.',
        ),
      );
    }
  }

  @override
  Future<void> deleteMedley(String id) async {
    try {
      await _dio.delete('/medleys/$id/delete');
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Não foi possível remover o medley.',
        ),
      );
    }
  }

  String _extractApiErrorMessage(
    DioException error, {
    String fallback = 'Erro inesperado.',
  }) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['detail'] ?? data['message'] ?? data['error'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message = map['detail'] ?? map['message'] ?? map['error'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    return error.message ?? fallback;
  }
}
