import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/music_project_entity.dart';

import '../../data/user_unavailability_repository.dart';
import '../../domain/entities/create_user_unavailability_input_entity.dart';
import '../../domain/entities/user_unavailability_entity.dart';
import 'user_unavailability_state.dart';

class UserUnavailabilityCubit extends Cubit<UserUnavailabilityState> {
  final UserUnavailabilityRepository _repository;

  UserUnavailabilityCubit(this._repository)
    : super(const UserUnavailabilityState());

  Future<void> load() async {
    emit(
      state.copyWith(
        status: UserUnavailabilityStatus.loading,
        clearErrorMessage: true,
        clearActionErrorMessage: true,
      ),
    );

    try {
      final results = await Future.wait([
        _repository.getUserMusicProjects(),
        _repository.getUserUnavailabilities(),
      ]);

      final projects = results[0] as List<MusicProjectEntity>;
      final items = _sortItems(results[1] as List<UserUnavailabilityEntity>);

      emit(
        state.copyWith(
          status: items.isEmpty
              ? UserUnavailabilityStatus.empty
              : UserUnavailabilityStatus.success,
          projects: _sortProjects(projects),
          items: items,
          clearErrorMessage: true,
          clearActionErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: UserUnavailabilityStatus.error,
          errorMessage: _extractMessage(error),
        ),
      );
    }
  }

  Future<bool> create(CreateUserUnavailabilityInputEntity input) async {
    emit(
      state.copyWith(
        submission: UserUnavailabilitySubmission.creating,
        clearActionErrorMessage: true,
      ),
    );

    try {
      final created = await _repository.createUserUnavailability(input);
      final updatedItems = _sortItems([created, ...state.items]);

      emit(
        state.copyWith(
          submission: UserUnavailabilitySubmission.idle,
          status: updatedItems.isEmpty
              ? UserUnavailabilityStatus.empty
              : UserUnavailabilityStatus.success,
          items: updatedItems,
          clearActionErrorMessage: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          submission: UserUnavailabilitySubmission.idle,
          actionErrorMessage: _extractMessage(error),
        ),
      );
      return false;
    }
  }

  Future<bool> delete(UserUnavailabilityEntity item) async {
    emit(
      state.copyWith(
        submission: UserUnavailabilitySubmission.deleting,
        activeUnavailabilityId: item.id,
        clearActionErrorMessage: true,
      ),
    );

    try {
      await _repository.deleteUserUnavailability(item.id);
      final updatedItems = state.items
          .where((current) => current.id != item.id)
          .toList(growable: false);

      emit(
        state.copyWith(
          submission: UserUnavailabilitySubmission.idle,
          status: updatedItems.isEmpty
              ? UserUnavailabilityStatus.empty
              : UserUnavailabilityStatus.success,
          items: updatedItems,
          clearActionErrorMessage: true,
          clearActiveUnavailabilityId: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          submission: UserUnavailabilitySubmission.idle,
          actionErrorMessage: _extractMessage(error),
          clearActiveUnavailabilityId: true,
        ),
      );
      return false;
    }
  }

  List<MusicProjectEntity> _sortProjects(List<MusicProjectEntity> projects) {
    final sorted = [...projects];
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  List<UserUnavailabilityEntity> _sortItems(
    List<UserUnavailabilityEntity> items,
  ) {
    final sorted = [...items];
    sorted.sort((a, b) => b.startDate.compareTo(a.startDate));
    return sorted;
  }

  String _extractMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
