import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/events_repository.dart';
import '../../domain/entities/event_song_input_entity.dart';
import 'manage_event_songs_state.dart';

class ManageEventSongsCubit extends Cubit<ManageEventSongsState> {
  final EventsRepository _repository;

  ManageEventSongsCubit(this._repository)
    : super(const ManageEventSongsState());

  Future<void> load() async {
    emit(
      state.copyWith(
        status: ManageEventSongsStatus.loadingSongs,
        clearErrorMessage: true,
      ),
    );

    try {
      final songs = await _repository.getUserSongs();
      emit(
        state.copyWith(
          status: ManageEventSongsStatus.loaded,
          songs: songs,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ManageEventSongsStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  void toggleSong(String songId) {
    final selected = Set<String>.from(state.selectedSongIds);
    if (selected.contains(songId)) {
      selected.remove(songId);
    } else {
      selected.add(songId);
    }

    emit(state.copyWith(selectedSongIds: selected, clearErrorMessage: true));
  }

  Future<bool> submit(String eventId) async {
    if (state.selectedSongIds.isEmpty) {
      emit(
        state.copyWith(
          status: ManageEventSongsStatus.error,
          errorMessage: 'Selecione ao menos uma música.',
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        status: ManageEventSongsStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    try {
      await _repository.addSongsToEvent(
        eventId,
        state.selectedSongIds
            .map((songId) => EventSongInputEntity(songId: songId))
            .toList(),
      );
      emit(
        state.copyWith(
          status: ManageEventSongsStatus.success,
          clearErrorMessage: true,
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          status: ManageEventSongsStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }
}
