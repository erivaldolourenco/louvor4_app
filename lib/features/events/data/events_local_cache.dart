import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/entities/event_entity.dart';

/// Cache local dos próximos eventos do usuário, usada para exibir a agenda
/// sem internet. Eventos passados não são cacheados.
class EventsLocalCache {
  static const _fileName = 'upcoming_events_cache.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<EventEntity>> readUpcomingEvents() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const [];

      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List;
      return list
          .map(
            (e) => EventEntity.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveUpcomingEvents(List<EventEntity> events) async {
    try {
      final file = await _file();
      final raw = jsonEncode(events.map((e) => e.toJson()).toList());
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
