import '../domain/entities/song_entity.dart';

abstract class SongsRepository {
  Future<List<SongEntity>> getUserSongs();

  Future<SongEntity> createSong(SongEntity song);

  Future<SongEntity> getSongById(String id);

  Future<SongEntity> updateSong(SongEntity song);

  Future<void> uploadReferenceAudio(String songId, String filePath);

  Future<void> deleteSong(String id);

  Future<String?> getSongLyrics(String songId);

  Future<void> updateSongLyrics(String songId, String lyrics);
}
