import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_message.dart';
import '../../domain/entities/external_music_entity.dart';
import '../external_music_repository.dart';

class ExternalMusicRepositoryImpl implements ExternalMusicRepository {
  final Dio _dio;

  ExternalMusicRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  @override
  Future<List<ExternalMusicEntity>> search({
    required String term,
    required ExternalMusicProvider provider,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/external-music/search',
        queryParameters: {
          'q': term,
          'provider': provider.apiValue,
          'limit': limit,
        },
      );
      final list = response.data as List;
      return list
          .map(
            (item) => ExternalMusicEntity.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(extractApiErrorMessage(e));
    }
  }

  @override
  Future<ExternalMusicEntity> select(ExternalMusicEntity result) async {
    try {
      final response = await _dio.post(
        '/external-music/select',
        data: result.toJson(),
      );
      return ExternalMusicEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(extractApiErrorMessage(e));
    }
  }
}
