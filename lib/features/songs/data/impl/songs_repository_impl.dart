import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_message.dart';
import '../../domain/entities/chord_sheet_entity.dart';
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

  @override
  Future<void> uploadReferenceAudio(String songId, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: File(filePath).uri.pathSegments.last,
        ),
      });
      await _dio.post('/songs/$songId/audio?type=REFERENCE', data: formData);
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<void> deleteSong(String id) async {
    try {
      await _dio.delete('/songs/$id/delete');
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<String?> getSongLyrics(String songId) async {
    try {
      final response = await _dio.get('/songs/$songId/lyrics');
      final data = response.data;
      final lyrics = data is Map ? data['lyrics'] : data;
      final normalized = lyrics?.toString().trim();
      return normalized == null || normalized.isEmpty ? null : normalized;
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<void> updateSongLyrics(String songId, String lyrics) async {
    try {
      await _dio.put('/songs/$songId/lyrics', data: {'lyrics': lyrics});
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<ChordSheetEntity?> getChordSheet(String songId) async {
    try {
      final response = await _dio.get('/songs/$songId/chord-sheet');
      return _parseChordSheetResponse(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<ChordSheetEntity> saveChordSheet(
    String songId,
    ChordSheetEntity chordSheet,
  ) async {
    try {
      final response = await _dio.put(
        '/songs/$songId/chord-sheet',
        data: {'chordSheetJson': jsonEncode(chordSheet.toJson())},
      );
      final parsed = _parseChordSheetResponse(response.data);
      if (parsed == null) {
        throw Exception('Resposta inválida ao salvar a cifra.');
      }
      return parsed;
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<void> deleteChordSheet(String songId) async {
    try {
      await _dio.delete('/songs/$songId/chord-sheet');
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  @override
  Future<bool> updateChordSheetEditPermission(
    String songId,
    bool editPermission,
  ) async {
    try {
      final response = await _dio.put(
        '/songs/$songId/chord-sheet/edit-permission',
        data: {'editPermission': editPermission},
      );
      final data = response.data;
      return data is Map && data['editPermission'] == true;
    } on DioException catch (e) {
      throw Exception(_extractApiErrorMessage(e));
    }
  }

  ChordSheetEntity? _parseChordSheetResponse(dynamic data) {
    final raw = data is Map ? data['chordSheetJson'] : null;
    final normalized = raw?.toString().trim();
    if (normalized == null || normalized.isEmpty) return null;
    final decoded = jsonDecode(normalized);
    final entity = ChordSheetEntity.fromJson(
      Map<String, dynamic>.from(decoded as Map),
    );
    final editPermission = data is Map && data['editPermission'] == true;
    return entity.copyWith(editPermission: editPermission);
  }

  String _extractApiErrorMessage(DioException e) => extractApiErrorMessage(e);
}
