import '../domain/entities/external_music_entity.dart';

abstract class ExternalMusicRepository {
  Future<List<ExternalMusicEntity>> search({
    required String term,
    required ExternalMusicProvider provider,
    int limit = 10,
  });

  /// Resolve a URL do provedor que faltava (via ISRC) para o resultado
  /// escolhido pelo usuário. Se não houver correspondência, a API devolve o
  /// mesmo objeto sem alteração.
  Future<ExternalMusicEntity> select(ExternalMusicEntity result);
}
