import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_message.dart';
import '../../domain/entities/song_category_entity.dart';
import '../song_categories_repository.dart';

class SongCategoriesRepositoryImpl implements SongCategoriesRepository {
  final Dio _dio;

  SongCategoriesRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  @override
  Future<List<SongCategoryEntity>> getSongCategories() async {
    try {
      final response = await _dio.get('/song-categories');
      final list = response.data as List;
      return list
          .map(
            (item) => SongCategoryEntity.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        extractApiErrorMessage(
          e,
          fallback: 'Não foi possível carregar as categorias.',
        ),
      );
    }
  }

  @override
  Future<SongCategoryEntity> createSongCategory(String name) async {
    try {
      final response = await _dio.post(
        '/song-categories',
        data: {'name': name},
      );
      return SongCategoryEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        extractApiErrorMessage(
          e,
          fallback: 'Não foi possível criar a categoria.',
        ),
      );
    }
  }

  @override
  Future<SongCategoryEntity> updateSongCategory(
    String categoryId,
    String name,
  ) async {
    try {
      final response = await _dio.put(
        '/song-categories/$categoryId',
        data: {'name': name},
      );
      return SongCategoryEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        extractApiErrorMessage(
          e,
          fallback: 'Não foi possível atualizar a categoria.',
        ),
      );
    }
  }

  @override
  Future<void> deleteSongCategory(String categoryId) async {
    try {
      await _dio.delete('/song-categories/$categoryId');
    } on DioException catch (e) {
      throw Exception(
        extractApiErrorMessage(
          e,
          fallback: 'Não foi possível excluir a categoria.',
        ),
      );
    }
  }
}
