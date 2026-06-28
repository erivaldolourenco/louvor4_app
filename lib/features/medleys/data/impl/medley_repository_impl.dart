import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_message.dart';
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

  @override
  Future<void> uploadReferenceAudio(String id, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: File(filePath).uri.pathSegments.last,
        ),
      });
      await _dio.post('/medleys/$id/audio?type=REFERENCE', data: formData);
    } on DioException catch (e) {
      throw Exception(
        _extractApiErrorMessage(
          e,
          fallback: 'Não foi possível enviar o áudio de referência.',
        ),
      );
    }
  }

  String _extractApiErrorMessage(
    DioException error, {
    String fallback = 'Erro inesperado.',
  }) =>
      extractApiErrorMessage(error, fallback: fallback);
}
