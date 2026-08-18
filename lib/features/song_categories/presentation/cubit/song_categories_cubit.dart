import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/song_categories_repository.dart';
import '../../domain/entities/song_category_entity.dart';
import 'song_categories_state.dart';

class SongCategoriesCubit extends Cubit<SongCategoriesState> {
  static const int maxNameLength = 50;

  final SongCategoriesRepository _repository;

  SongCategoriesCubit(this._repository) : super(const SongCategoriesState());

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(
        state.copyWith(
          status: SongCategoriesStatus.loading,
          clearErrorMessage: true,
          clearActionErrorMessage: true,
        ),
      );
    }

    try {
      final categories = await _repository.getSongCategories();
      emit(
        state.copyWith(
          status: SongCategoriesStatus.success,
          categories: _sortCategories(categories),
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SongCategoriesStatus.failure,
          errorMessage: _extractMessage(e),
        ),
      );
    }
  }

  Future<bool> createCategory(String name) async {
    final validationError = _validateName(name);
    if (validationError != null) {
      emit(state.copyWith(actionErrorMessage: validationError));
      return false;
    }

    emit(
      state.copyWith(
        submission: SongCategoriesSubmission.saving,
        clearActionErrorMessage: true,
      ),
    );

    try {
      await _repository.createSongCategory(name.trim());
      await _reloadCategories();
      emit(
        state.copyWith(
          submission: SongCategoriesSubmission.idle,
          clearActionErrorMessage: true,
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          submission: SongCategoriesSubmission.idle,
          actionErrorMessage: _extractMessage(e),
        ),
      );
      return false;
    }
  }

  Future<bool> updateCategory(SongCategoryEntity category, String name) async {
    final validationError = _validateName(name);
    if (validationError != null) {
      emit(state.copyWith(actionErrorMessage: validationError));
      return false;
    }

    emit(
      state.copyWith(
        submission: SongCategoriesSubmission.saving,
        clearActionErrorMessage: true,
      ),
    );

    try {
      await _repository.updateSongCategory(category.id, name.trim());
      await _reloadCategories();
      emit(
        state.copyWith(
          submission: SongCategoriesSubmission.idle,
          clearActionErrorMessage: true,
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          submission: SongCategoriesSubmission.idle,
          actionErrorMessage: _extractMessage(e),
        ),
      );
      return false;
    }
  }

  Future<bool> deleteCategory(SongCategoryEntity category) async {
    emit(
      state.copyWith(
        submission: SongCategoriesSubmission.deleting,
        activeCategoryId: category.id,
        clearActionErrorMessage: true,
      ),
    );

    try {
      await _repository.deleteSongCategory(category.id);
      emit(
        state.copyWith(
          submission: SongCategoriesSubmission.idle,
          clearActiveCategoryId: true,
          categories: state.categories
              .where((item) => item.id != category.id)
              .toList(),
          clearActionErrorMessage: true,
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          submission: SongCategoriesSubmission.idle,
          clearActiveCategoryId: true,
          actionErrorMessage: _extractMessage(e),
        ),
      );
      return false;
    }
  }

  Future<void> _reloadCategories() async {
    final categories = await _repository.getSongCategories();
    emit(
      state.copyWith(
        status: SongCategoriesStatus.success,
        categories: _sortCategories(categories),
      ),
    );
  }

  String? _validateName(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      return 'Informe o nome da categoria.';
    }
    if (normalized.length > maxNameLength) {
      return 'Use no máximo $maxNameLength caracteres.';
    }
    return null;
  }

  List<SongCategoryEntity> _sortCategories(List<SongCategoryEntity> categories) {
    final sorted = [...categories];
    sorted.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return sorted;
  }

  String _extractMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
