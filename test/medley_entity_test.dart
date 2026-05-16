import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/medleys/domain/entities/create_medley_input_entity.dart';
import 'package:louvor4_app/features/medleys/domain/entities/medley_entity.dart';
import 'package:louvor4_app/features/medleys/domain/entities/medley_item_entity.dart';

void main() {
  // -------------------------------------------------------------------------
  // MedleyItemEntity.fromJson
  // -------------------------------------------------------------------------

  group('MedleyItemEntity.fromJson', () {
    test('lê campos flat (songId, songTitle, songArtist, key)', () {
      final item = MedleyItemEntity.fromJson({
        'id': 'item1',
        'songId': 's1',
        'songTitle': 'Oceans',
        'songArtist': 'Hillsong',
        'key': 'G',
        'sequence': 1,
      });

      expect(item.id, 'item1');
      expect(item.songId, 's1');
      expect(item.songTitle, 'Oceans');
      expect(item.songArtist, 'Hillsong');
      expect(item.key, 'G');
      expect(item.sequence, 1);
      expect(item.notes, isNull);
    });

    test('lê dados de música aninhados sob "song"', () {
      final item = MedleyItemEntity.fromJson({
        'id': 'item2',
        'sequence': 2,
        'key': 'C',
        'song': {
          'id': 's2',
          'title': 'Way Maker',
          'artist': 'Leeland',
          'youTubeUrl': 'https://yt.com/watch?v=abc',
        },
      });

      expect(item.songId, 's2');
      expect(item.songTitle, 'Way Maker');
      expect(item.songArtist, 'Leeland');
      expect(item.youTubeUrl, 'https://yt.com/watch?v=abc');
      expect(item.sequence, 2);
    });

    test('lê dados de música aninhados sob "Song" (maiúsculo)', () {
      final item = MedleyItemEntity.fromJson({
        'id': 'item3',
        'sequence': 0,
        'key': 'Am',
        'Song': {'id': 's3', 'title': 'Goodness of God', 'artist': 'Bethel'},
      });

      expect(item.songId, 's3');
      expect(item.songTitle, 'Goodness of God');
      expect(item.songArtist, 'Bethel');
    });

    test('prefere campo flat sobre aninhado quando ambos existem', () {
      final item = MedleyItemEntity.fromJson({
        'songId': 'flat-id',
        'songTitle': 'Flat Title',
        'sequence': 0,
        'song': {'id': 'nested-id', 'title': 'Nested Title'},
      });

      expect(item.songId, 'flat-id');
      expect(item.songTitle, 'Flat Title');
    });

    test('normaliza notes: string vazia → null', () {
      final item = MedleyItemEntity.fromJson({
        'sequence': 0,
        'notes': '   ',
      });

      expect(item.notes, isNull);
    });

    test('preserva notes com conteúdo', () {
      final item = MedleyItemEntity.fromJson({
        'sequence': 0,
        'notes': 'Intro lento',
      });

      expect(item.notes, 'Intro lento');
    });

    test('usa 0 como sequence padrão quando ausente', () {
      final item = MedleyItemEntity.fromJson({'songId': 's1'});
      expect(item.sequence, 0);
    });
  });

  // -------------------------------------------------------------------------
  // MedleyEntity.fromJson
  // -------------------------------------------------------------------------

  group('MedleyEntity.fromJson', () {
    test('parseia campos básicos', () {
      final medley = MedleyEntity.fromJson({
        'id': 'm1',
        'name': 'Abertura',
        'description': 'Músicas de abertura',
        'items': [],
      });

      expect(medley.id, 'm1');
      expect(medley.name, 'Abertura');
      expect(medley.description, 'Músicas de abertura');
      expect(medley.items, isEmpty);
    });

    test('normaliza description vazia → null', () {
      final medley = MedleyEntity.fromJson({
        'id': 'm1',
        'name': 'Abertura',
        'description': '',
        'items': [],
      });

      expect(medley.description, isNull);
    });

    test('normaliza notes vazia → null', () {
      final medley = MedleyEntity.fromJson({
        'id': 'm1',
        'name': 'Abertura',
        'notes': '   ',
        'items': [],
      });

      expect(medley.notes, isNull);
    });

    test('ordena itens por sequence independente da ordem da API', () {
      final medley = MedleyEntity.fromJson({
        'id': 'm1',
        'name': 'Medley',
        'items': [
          {'songId': 's3', 'sequence': 3},
          {'songId': 's1', 'sequence': 1},
          {'songId': 's2', 'sequence': 2},
        ],
      });

      expect(medley.items.map((i) => i.sequence), [1, 2, 3]);
      expect(medley.items.map((i) => i.songId), ['s1', 's2', 's3']);
    });

    test('retorna lista vazia quando items é null', () {
      final medley = MedleyEntity.fromJson({'id': 'm1', 'name': 'Teste'});

      expect(medley.items, isEmpty);
    });

    test('usa string vazia como name padrão quando ausente', () {
      final medley = MedleyEntity.fromJson({'id': 'm1'});
      expect(medley.name, '');
    });
  });

  // -------------------------------------------------------------------------
  // CreateMedleyItemInputEntity.toJson
  // -------------------------------------------------------------------------

  group('CreateMedleyItemInputEntity.toJson', () {
    test('inclui todos os campos obrigatórios', () {
      final json = const CreateMedleyItemInputEntity(
        songId: 's1',
        key: 'G',
        sequence: 0,
      ).toJson();

      expect(json['songId'], 's1');
      expect(json['key'], 'G');
      expect(json['sequence'], 0);
      expect(json.containsKey('notes'), isFalse);
    });

    test('inclui notes quando preenchido', () {
      final json = const CreateMedleyItemInputEntity(
        songId: 's1',
        key: 'Am',
        sequence: 1,
        notes: 'Tocar suave',
      ).toJson();

      expect(json['notes'], 'Tocar suave');
    });

    test('omite notes quando null', () {
      final json = const CreateMedleyItemInputEntity(
        songId: 's1',
        key: 'C',
        sequence: 0,
        notes: null,
      ).toJson();

      expect(json.containsKey('notes'), isFalse);
    });

    test('omite notes quando string vazia', () {
      final json = const CreateMedleyItemInputEntity(
        songId: 's1',
        key: 'C',
        sequence: 0,
        notes: '',
      ).toJson();

      expect(json.containsKey('notes'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // CreateMedleyInputEntity.toJson
  // -------------------------------------------------------------------------

  group('CreateMedleyInputEntity.toJson', () {
    test('inclui name e items, omite description quando null', () {
      final json = const CreateMedleyInputEntity(
        name: 'Medley de Louvor',
        items: [],
      ).toJson();

      expect(json['name'], 'Medley de Louvor');
      expect(json['items'], isEmpty);
      expect(json.containsKey('description'), isFalse);
    });

    test('inclui description quando preenchida', () {
      final json = const CreateMedleyInputEntity(
        name: 'Abertura',
        description: 'Músicas de abertura do culto',
        items: [],
      ).toJson();

      expect(json['description'], 'Músicas de abertura do culto');
    });

    test('omite description quando string vazia', () {
      final json = const CreateMedleyInputEntity(
        name: 'Abertura',
        description: '',
        items: [],
      ).toJson();

      expect(json.containsKey('description'), isFalse);
    });

    test('serializa itens corretamente em ordem', () {
      final json = const CreateMedleyInputEntity(
        name: 'Medley',
        items: [
          CreateMedleyItemInputEntity(songId: 's1', key: 'G', sequence: 0),
          CreateMedleyItemInputEntity(
            songId: 's2',
            key: 'Am',
            sequence: 1,
            notes: 'BPM 90',
          ),
        ],
      ).toJson();

      final items = json['items'] as List;
      expect(items, hasLength(2));
      expect(items[0]['songId'], 's1');
      expect(items[0]['sequence'], 0);
      expect(items[1]['songId'], 's2');
      expect(items[1]['notes'], 'BPM 90');
    });
  });
}
