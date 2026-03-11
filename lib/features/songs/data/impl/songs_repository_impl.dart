import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/song_entity.dart';
import '../songs_repository.dart';

class SongsRepositoryImpl implements SongsRepository {
  final Dio _dio;

  SongsRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  @override
  Future<List<SongEntity>> getUserSongs() async {
    final response = await _dio.get('/users/songs');
    final list = response.data as List;
    return list
        .map(
          (item) => SongEntity.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<SongEntity> createSong(SongEntity song) async {
    try {
      final response = await _dio.post('/songs/create', data: song.toJson());
      return SongEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<SongEntity> getSongById(String id) async {
    try {
      final response = await _dio.get('/songs/$id');
      return SongEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<SongEntity> updateSong(SongEntity song) async {
    try {
      final response = await _dio.put('/songs/update', data: song.toJson());
      return SongEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  String _extractApiErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    return 'Não foi possível concluir a operação (${e.response?.statusCode ?? 'sem status'}).';
  }
}
