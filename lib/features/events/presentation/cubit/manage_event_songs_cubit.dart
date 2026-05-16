import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/medleys/data/medley_repository.dart';
import '../../data/events_repository.dart';
import '../../domain/entities/event_song_input_entity.dart';
import 'manage_event_songs_state.dart';

class ManageEventSongsCubit extends Cubit<ManageEventSongsState> {
  final EventsRepository _eventsRepo;
  final MedleyRepository _medleyRepo;

  ManageEventSongsCubit(this._eventsRepo, this._medleyRepo)
    : super(const ManageEventSongsState());

  Future<void> load() async {
    emit(
      state.copyWith(
        status: ManageEventSongsStatus.loadingSongs,
        clearErrorMessage: true,
      ),
    );

    try {
      final songs = await _eventsRepo.getUserSongs();
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

  Future<void> loadMedleys() async {
    if (state.isLoadingMedleys) return;
    emit(state.copyWith(isLoadingMedleys: true, clearErrorMessage: true));
    try {
      final medleys = await _medleyRepo.getUserMedleys();
      emit(state.copyWith(isLoadingMedleys: false, medleys: medleys));
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingMedleys: false,
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

  void toggleMedley(String medleyId) {
    final selected = Set<String>.from(state.selectedMedleyIds);
    if (selected.contains(medleyId)) {
      selected.remove(medleyId);
    } else {
      selected.add(medleyId);
    }
    emit(state.copyWith(selectedMedleyIds: selected, clearErrorMessage: true));
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
      await _eventsRepo.addSongsToEvent(
        eventId,
        state.selectedSongIds
            .map((id) => EventSongInputEntity(itemId: id))
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

  Future<bool> submitMedleys(String eventId) async {
    if (state.selectedMedleyIds.isEmpty) {
      emit(
        state.copyWith(
          status: ManageEventSongsStatus.error,
          errorMessage: 'Selecione ao menos um medley.',
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
      await _eventsRepo.addSongsToEvent(
        eventId,
        state.selectedMedleyIds
            .map((id) => EventSongInputEntity(
                  itemId: id,
                  type: EventSongInputType.medley,
                ))
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
