import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/song_categories/domain/entities/song_category_entity.dart';
import 'package:louvor4_app/features/songs/domain/entities/song_entity.dart';

void main() {
  group('SongEntity — toCacheJson/fromJson', () {
    test('faz round-trip preservando todos os campos, incluindo categorias', () {
      const song = SongEntity(
        id: 's1',
        artist: 'Artist A',
        title: 'Song A',
        key: 'C#m',
        bpm: '120',
        album: 'Album A',
        youTubeUrl: 'https://youtube.com/watch?v=12345678901',
        spotifyUrl: 'https://open.spotify.com/track/xyz',
        deezerUrl: 'https://deezer.com/track/123',
        coverUrl: 'https://cdn.example.com/cover.jpg',
        notes: 'Tocar bem devagar',
        referenceAudioUrl: 'https://cdn.example.com/ref.mp3',
        vsAudioUrl: 'https://cdn.example.com/vs.mp3',
        categories: [
          SongCategoryEntity(id: 'c1', name: 'Adoração'),
          SongCategoryEntity(id: 'c2', name: 'Natal'),
        ],
      );

      final restored = SongEntity.fromJson(song.toCacheJson());

      expect(restored, song);
    });

    test('preserva id nulo e lista de categorias vazia', () {
      const song = SongEntity(artist: 'Artist B', title: 'Song B', key: 'G');

      final restored = SongEntity.fromJson(song.toCacheJson());

      expect(restored.id, isNull);
      expect(restored.categories, isEmpty);
      expect(restored, song);
    });

    test('toCacheJson não é usado para o payload de criação/atualização', () {
      // toJson() é o payload enviado à API — não deve incluir `categories`,
      // que é gerenciado por um endpoint separado.
      const song = SongEntity(
        id: 's1',
        artist: 'Artist A',
        title: 'Song A',
        key: 'C',
        categories: [SongCategoryEntity(id: 'c1', name: 'Adoração')],
      );

      expect(song.toJson().containsKey('categories'), isFalse);
      expect(song.toCacheJson().containsKey('categories'), isTrue);
    });
  });
}
