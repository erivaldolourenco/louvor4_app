import '../domain/entities/song_category_entity.dart';

abstract class SongCategoriesRepository {
  Future<List<SongCategoryEntity>> getSongCategories();

  Future<SongCategoryEntity> createSongCategory(String name);

  Future<SongCategoryEntity> updateSongCategory(String categoryId, String name);

  Future<void> deleteSongCategory(String categoryId);
}
