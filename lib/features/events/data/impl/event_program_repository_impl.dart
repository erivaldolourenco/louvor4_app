import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/program_item_entity.dart';
import '../../domain/entities/program_item_input_entity.dart';
import '../event_program_repository.dart';

class EventProgramRepositoryImpl implements EventProgramRepository {
  final Dio _dio;

  EventProgramRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  @override
  Future<List<ProgramItemEntity>> getProgram(String eventId) async {
    try {
      final response = await _dio.get('/events/$eventId/program');
      final rawData = response.data;
      final list = rawData is List ? rawData : <dynamic>[];
      final items = list
          .whereType<Map>()
          .map((e) => ProgramItemEntity.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      items.sort((a, b) => a.position.compareTo(b.position));
      return items;
    } on DioException catch (e) {
      throw Exception(_extractError(e, fallback: 'Não foi possível carregar a programação.'));
    }
  }

  @override
  Future<ProgramItemEntity> createTextItem(
    String eventId,
    CreateTextProgramItemInputEntity input,
  ) async {
    try {
      final response = await _dio.post(
        '/events/$eventId/program/text',
        data: input.toJson(),
      );
      final data = response.data;
      if (data is Map) {
        return ProgramItemEntity.fromJson(Map<String, dynamic>.from(data));
      }
      return TextProgramItemEntity(id: '', position: -1, title: input.title);
    } on DioException catch (e) {
      throw Exception(_extractError(e, fallback: 'Não foi possível criar o item.'));
    }
  }

  @override
  Future<ProgramItemEntity> updateTextItem(
    String eventId,
    String itemId,
    UpdateTextProgramItemInputEntity input,
  ) async {
    try {
      final response = await _dio.put(
        '/events/$eventId/program/$itemId',
        data: input.toJson(),
      );
      final data = response.data;
      if (data is Map) {
        return ProgramItemEntity.fromJson(Map<String, dynamic>.from(data));
      }
      return TextProgramItemEntity(id: itemId, position: -1, title: input.title);
    } on DioException catch (e) {
      throw Exception(_extractError(e, fallback: 'Não foi possível atualizar o item.'));
    }
  }

  @override
  Future<void> deleteItem(String eventId, String itemId) async {
    try {
      await _dio.delete('/events/$eventId/program/$itemId');
    } on DioException catch (e) {
      throw Exception(_extractError(e, fallback: 'Não foi possível remover o item.'));
    }
  }

  @override
  Future<void> reorder(String eventId, List<String> orderedIds) async {
    try {
      await _dio.patch(
        '/events/$eventId/program/reorder',
        data: {'orderedIds': orderedIds},
      );
    } on DioException catch (e) {
      throw Exception(_extractError(e, fallback: 'Não foi possível reordenar a programação.'));
    }
  }

  String _extractError(DioException error, {String fallback = 'Erro inesperado.'}) {
    final data = error.response?.data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message = map['detail'] ?? map['message'] ?? map['details'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    return fallback;
  }
}
