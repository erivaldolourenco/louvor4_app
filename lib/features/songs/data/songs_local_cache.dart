import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/entities/song_entity.dart';

/// Cache local do repertório do usuário, usada para exibir a lista de
/// músicas sem internet.
class SongsLocalCache {
  static const _fileName = 'user_songs_cache.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<SongEntity>> readSongs() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const [];

      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List;
      return list
          .map(
            (e) => SongEntity.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveSongs(List<SongEntity> songs) async {
    try {
      final file = await _file();
      final raw = jsonEncode(songs.map((s) => s.toCacheJson()).toList());
      await file.writeAsString(raw);
    } catch (_) {
      // Falha ao salvar o cache não deve interromper o carregamento.
    }
  }

  Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
