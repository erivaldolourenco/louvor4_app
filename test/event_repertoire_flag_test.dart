import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/events/domain/entities/event_detail_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/event_entity.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/music_event_detail_entity.dart';

void main() {
  group('EventEntity — hasRepertoire', () {
    test('lê hasRepertoire true do json', () {
      final event = EventEntity.fromJson(_eventJson(hasRepertoire: true));
      expect(event.hasRepertoire, isTrue);
    });

    test('lê hasRepertoire false do json (projeto de mídia)', () {
      final event = EventEntity.fromJson(_eventJson(hasRepertoire: false));
      expect(event.hasRepertoire, isFalse);
    });

    test('assume true quando o campo não vem no json (compatibilidade)', () {
      final json = _eventJson(hasRepertoire: true)..remove('hasRepertoire');
      final event = EventEntity.fromJson(json);
      expect(event.hasRepertoire, isTrue);
    });

    test('faz round-trip via toJson', () {
      final event = EventEntity.fromJson(_eventJson(hasRepertoire: false));
      final restored = EventEntity.fromJson(event.toJson());
      expect(restored.hasRepertoire, isFalse);
    });
  });

  group('EventDetailEntity — hasRepertoire', () {
    test('lê hasRepertoire false do json (projeto de mídia)', () {
      final event = EventDetailEntity.fromJson(
        _eventJson(hasRepertoire: false),
      );
      expect(event.hasRepertoire, isFalse);
    });

    test('assume true quando o campo não vem no json (compatibilidade)', () {
      final json = _eventJson(hasRepertoire: true)..remove('hasRepertoire');
      final event = EventDetailEntity.fromJson(json);
      expect(event.hasRepertoire, isTrue);
    });
  });

  group('MusicEventDetailEntity — hasRepertoire', () {
    test('lê hasRepertoire false do json (projeto de mídia)', () {
      final event = MusicEventDetailEntity.fromJson(
        _eventJson(hasRepertoire: false),
      );
      expect(event.hasRepertoire, isFalse);
    });
  });
}

Map<String, dynamic> _eventJson({required bool hasRepertoire}) => {
  'id': 'e1',
  'projectId': 'p1',
  'date': '2026-01-01',
  'time': '19:00',
  'title': 'Culto',
  'projectTitle': 'Equipe de Mídia',
  'location': 'Igreja',
  'participantsCount': 3,
  'repertoireCount': 0,
  'participantsProfileImages': <String>[],
  'hasRepertoire': hasRepertoire,
};
