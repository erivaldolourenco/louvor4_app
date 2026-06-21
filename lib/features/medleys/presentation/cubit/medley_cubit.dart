import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/medley_repository.dart';
import '../../domain/entities/create_medley_input_entity.dart';
import 'medley_state.dart';

class MedleyCubit extends Cubit<MedleyState> {
  final MedleyRepository _repo;

  MedleyCubit(this._repo) : super(const MedleyState());

  Future<void> loadMedleys() async {
    if (state.status == MedleyStatus.loading) return;
    emit(state.copyWith(status: MedleyStatus.loading));
    try {
      final medleys = await _repo.getUserMedleys();
      emit(state.copyWith(status: MedleyStatus.success, medleys: medleys));
    } catch (e) {
      emit(
        state.copyWith(
          status: MedleyStatus.failure,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<bool> createMedley(CreateMedleyInputEntity input) async {
    // emit fresh state to clear previous actionError
    emit(
      MedleyState(
        status: state.status,
        medleys: state.medleys,
        isActioning: true,
      ),
    );
    try {
      final created = await _repo.createMedley(input);
      emit(
        MedleyState(
          status: MedleyStatus.success,
          medleys: [...state.medleys, created],
        ),
      );
      return true;
    } catch (e) {
      emit(
        MedleyState(
          status: state.status,
          medleys: state.medleys,
          actionError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }

  Future<bool> updateMedley(String id, CreateMedleyInputEntity input) async {
    emit(
      MedleyState(
        status: state.status,
        medleys: state.medleys,
        isActioning: true,
      ),
    );
    try {
      final updated = await _repo.updateMedley(id, input);
      final newList = state.medleys.map((m) => m.id == id ? updated : m).toList();
      emit(MedleyState(status: MedleyStatus.success, medleys: newList));
      return true;
    } catch (e) {
      emit(
        MedleyState(
          status: state.status,
          medleys: state.medleys,
          actionError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }

  Future<bool> deleteMedley(String id) async {
    emit(
      MedleyState(
        status: state.status,
        medleys: state.medleys,
        isActioning: true,
      ),
    );
    try {
      await _repo.deleteMedley(id);
      final newList = state.medleys.where((m) => m.id != id).toList();
      emit(MedleyState(status: MedleyStatus.success, medleys: newList));
      return true;
    } catch (e) {
      emit(
        MedleyState(
          status: state.status,
          medleys: state.medleys,
          actionError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }

  Future<void> uploadReferenceAudio(String id, String filePath) =>
      _repo.uploadReferenceAudio(id, filePath);
}
