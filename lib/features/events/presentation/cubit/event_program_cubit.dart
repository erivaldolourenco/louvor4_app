import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/event_program_repository.dart';
import '../../domain/entities/program_item_entity.dart';
import '../../domain/entities/program_item_input_entity.dart';
import 'event_program_state.dart';

class EventProgramCubit extends Cubit<EventProgramState> {
  final EventProgramRepository _repo;
  final String eventId;

  EventProgramCubit(this._repo, {required this.eventId})
      : super(const EventProgramState());

  Future<void> loadProgram() async {
    if (state.status == EventProgramStatus.loading) return;
    emit(state.copyWith(status: EventProgramStatus.loading));
    try {
      final items = await _repo.getProgram(eventId);
      emit(state.copyWith(status: EventProgramStatus.success, items: items));
    } catch (e) {
      emit(state.copyWith(
        status: EventProgramStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<bool> createTextItem(CreateTextProgramItemInputEntity input) async {
    emit(EventProgramState(status: state.status, items: state.items, isActioning: true));
    try {
      await _repo.createTextItem(eventId, input);
      final items = await _repo.getProgram(eventId);
      emit(EventProgramState(status: EventProgramStatus.success, items: items));
      return true;
    } catch (e) {
      emit(EventProgramState(
        status: state.status,
        items: state.items,
        actionError: e.toString().replaceFirst('Exception: ', ''),
      ));
      return false;
    }
  }

  Future<bool> updateTextItem(String itemId, UpdateTextProgramItemInputEntity input) async {
    emit(EventProgramState(status: state.status, items: state.items, isActioning: true));
    try {
      await _repo.updateTextItem(eventId, itemId, input);
      final items = await _repo.getProgram(eventId);
      emit(EventProgramState(status: EventProgramStatus.success, items: items));
      return true;
    } catch (e) {
      emit(EventProgramState(
        status: state.status,
        items: state.items,
        actionError: e.toString().replaceFirst('Exception: ', ''),
      ));
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    emit(EventProgramState(status: state.status, items: state.items, isActioning: true));
    try {
      await _repo.deleteItem(eventId, itemId);
      final newList = state.items.where((i) => i.id != itemId).toList();
      emit(EventProgramState(status: EventProgramStatus.success, items: newList));
      return true;
    } catch (e) {
      emit(EventProgramState(
        status: state.status,
        items: state.items,
        actionError: e.toString().replaceFirst('Exception: ', ''),
      ));
      return false;
    }
  }

  Future<bool> reorder(List<String> orderedIds) async {
    final originalItems = state.items;
    final reordered = orderedIds
        .asMap()
        .entries
        .map((entry) {
          final item = originalItems.firstWhere((i) => i.id == entry.value);
          if (item is MusicProgramItemEntity) {
            return MusicProgramItemEntity(
              id: item.id,
              position: entry.key,
              songId: item.songId,
              songTitle: item.songTitle,
              songArtist: item.songArtist,
              songYouTubeUrl: item.songYouTubeUrl,
            );
          } else if (item is MedleyProgramItemEntity) {
            return MedleyProgramItemEntity(
              id: item.id,
              position: entry.key,
              medleyId: item.medleyId,
              medleyName: item.medleyName,
              songs: item.songs,
            );
          } else {
            final t = item as TextProgramItemEntity;
            return TextProgramItemEntity(
              id: t.id,
              position: entry.key,
              title: t.title,
              description: t.description,
            );
          }
        })
        .toList();

    emit(EventProgramState(status: state.status, items: reordered, isActioning: true));
    try {
      await _repo.reorder(eventId, orderedIds);
      emit(EventProgramState(status: EventProgramStatus.success, items: reordered));
      return true;
    } catch (e) {
      emit(EventProgramState(
        status: state.status,
        items: originalItems,
        actionError: e.toString().replaceFirst('Exception: ', ''),
      ));
      return false;
    }
  }
}
