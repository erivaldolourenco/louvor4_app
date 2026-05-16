import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/events/domain/entities/program_item_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/program_item_input_entity.dart';

void main() {
  // -------------------------------------------------------------------------
  // ProgramItemEntity.fromJson
  // -------------------------------------------------------------------------

  group('ProgramItemEntity.fromJson — tipo MUSIC', () {
    test('retorna MusicProgramItemEntity com campos corretos', () {
      final item = ProgramItemEntity.fromJson({
        'id': 'item1',
        'type': 'MUSIC',
        'position': 2,
        'music': {'id': 's1', 'title': 'Oceans', 'artist': 'Hillsong'},
      });

      expect(item, isA<MusicProgramItemEntity>());
      final music = item as MusicProgramItemEntity;
      expect(music.id, 'item1');
      expect(music.type, ProgramItemType.music);
      expect(music.position, 2);
      expect(music.songId, 's1');
      expect(music.songTitle, 'Oceans');
      expect(music.songArtist, 'Hillsong');
    });

    test('aceita tipo "music" em minúsculas', () {
      final item = ProgramItemEntity.fromJson({
        'id': 'item2',
        'type': 'music',
        'position': 0,
        'music': {'id': 's1', 'title': 'T', 'artist': 'A'},
      });

      expect(item, isA<MusicProgramItemEntity>());
    });

    test('usa strings vazias para campos de música ausentes', () {
      final item = ProgramItemEntity.fromJson({
        'id': 'item3',
        'type': 'MUSIC',
        'position': 0,
        'music': {},
      }) as MusicProgramItemEntity;

      expect(item.songId, '');
      expect(item.songTitle, '');
      expect(item.songArtist, '');
    });
  });

  group('ProgramItemEntity.fromJson — tipo TEXT', () {
    test('retorna TextProgramItemEntity com título e descrição', () {
      final item = ProgramItemEntity.fromJson({
        'id': 'item4',
        'type': 'TEXT',
        'position': 1,
        'title': 'Avisos',
        'description': 'Comunicados do mês',
      });

      expect(item, isA<TextProgramItemEntity>());
      final text = item as TextProgramItemEntity;
      expect(text.id, 'item4');
      expect(text.type, ProgramItemType.text);
      expect(text.position, 1);
      expect(text.title, 'Avisos');
      expect(text.description, 'Comunicados do mês');
    });

    test('description é null quando ausente no JSON', () {
      final item = ProgramItemEntity.fromJson({
        'id': 'item5',
        'type': 'TEXT',
        'position': 0,
        'title': 'Oração',
      }) as TextProgramItemEntity;

      expect(item.description, isNull);
    });

    test('usa string vazia como title padrão quando ausente', () {
      final item = ProgramItemEntity.fromJson({
        'id': 'item6',
        'type': 'TEXT',
        'position': 0,
      }) as TextProgramItemEntity;

      expect(item.title, '');
    });

    test('trata tipo desconhecido como TEXT', () {
      final item = ProgramItemEntity.fromJson({
        'id': 'item7',
        'type': 'UNKNOWN',
        'position': 0,
        'title': 'Algo',
      });

      expect(item, isA<TextProgramItemEntity>());
    });
  });

  group('ProgramItemEntity.fromJson — campos comuns', () {
    test('usa 0 como position padrão quando ausente', () {
      final item = ProgramItemEntity.fromJson({
        'id': 'item8',
        'type': 'TEXT',
        'title': 'Sem posição',
      });

      expect(item.position, 0);
    });
  });

  // -------------------------------------------------------------------------
  // CreateTextProgramItemInputEntity.toJson
  // -------------------------------------------------------------------------

  group('CreateTextProgramItemInputEntity.toJson', () {
    test('inclui title e omite description quando null', () {
      final json = const CreateTextProgramItemInputEntity(
        title: 'Oração',
      ).toJson();

      expect(json['title'], 'Oração');
      expect(json.containsKey('description'), isFalse);
    });

    test('inclui description quando preenchida', () {
      final json = const CreateTextProgramItemInputEntity(
        title: 'Oração',
        description: 'Momento de intercessão',
      ).toJson();

      expect(json['description'], 'Momento de intercessão');
    });

    test('omite description quando string vazia', () {
      final json = const CreateTextProgramItemInputEntity(
        title: 'Oração',
        description: '',
      ).toJson();

      expect(json.containsKey('description'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // UpdateTextProgramItemInputEntity.toJson
  // -------------------------------------------------------------------------

  group('UpdateTextProgramItemInputEntity.toJson', () {
    test('inclui title e omite description quando null', () {
      final json = const UpdateTextProgramItemInputEntity(
        title: 'Título editado',
      ).toJson();

      expect(json['title'], 'Título editado');
      expect(json.containsKey('description'), isFalse);
    });

    test('inclui description quando preenchida', () {
      final json = const UpdateTextProgramItemInputEntity(
        title: 'Título',
        description: 'Descrição editada',
      ).toJson();

      expect(json['description'], 'Descrição editada');
    });

    test('omite description quando string vazia', () {
      final json = const UpdateTextProgramItemInputEntity(
        title: 'Título',
        description: '',
      ).toJson();

      expect(json.containsKey('description'), isFalse);
    });
  });
}
