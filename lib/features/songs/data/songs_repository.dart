import '../domain/entities/chord_sheet_entity.dart';
import '../domain/entities/song_entity.dart';

abstract class SongsRepository {
  Future<List<SongEntity>> getUserSongs();

  Future<SongEntity> createSong(SongEntity song);

  Future<SongEntity> getSongById(String id);

  Future<SongEntity> updateSong(SongEntity song);

  Future<void> uploadReferenceAudio(String songId, String filePath);

  Future<void> deleteSong(String id);

  /// Substitui integralmente as categorias associadas à música pelas
  /// informadas em [categoryIds].
  Future<void> updateSongCategories(String songId, List<String> categoryIds);

  Future<String?> getSongLyrics(String songId);

  Future<void> updateSongLyrics(String songId, String lyrics);

  Future<ChordSheetEntity?> getChordSheet(String songId);

  Future<ChordSheetEntity> saveChordSheet(
    String songId,
    ChordSheetEntity chordSheet,
  );

  Future<void> deleteChordSheet(String songId);

  /// Retorna o valor de `editPermission` confirmado pelo backend.
  Future<bool> updateChordSheetEditPermission(
    String songId,
    bool editPermission,
  );
}
