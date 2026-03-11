import '../domain/entities/song_entity.dart';

abstract class SongsRepository {
  Future<List<SongEntity>> getUserSongs();

  Future<SongEntity> createSong(SongEntity song);

  Future<SongEntity> getSongById(String id);

  Future<SongEntity> updateSong(SongEntity song);
}
