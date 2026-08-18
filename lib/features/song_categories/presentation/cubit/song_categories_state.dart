import 'package:equatable/equatable.dart';

import '../../domain/entities/song_category_entity.dart';

enum SongCategoriesStatus { initial, loading, success, failure }

enum SongCategoriesSubmission { idle, saving, deleting }

class SongCategoriesState extends Equatable {
  final SongCategoriesStatus status;
  final SongCategoriesSubmission submission;
  final List<SongCategoryEntity> categories;
  final String? errorMessage;
  final String? actionErrorMessage;
  final String? activeCategoryId;

  const SongCategoriesState({
    this.status = SongCategoriesStatus.initial,
    this.submission = SongCategoriesSubmission.idle,
    this.categories = const [],
    this.errorMessage,
    this.actionErrorMessage,
    this.activeCategoryId,
  });

  bool get isInitialLoading =>
      status == SongCategoriesStatus.loading && categories.isEmpty;

  bool get isEmpty =>
      status == SongCategoriesStatus.success && categories.isEmpty;

  bool isDeletingCategory(String categoryId) {
    return submission == SongCategoriesSubmission.deleting &&
        activeCategoryId == categoryId;
  }

  SongCategoriesState copyWith({
    SongCategoriesStatus? status,
    SongCategoriesSubmission? submission,
    List<SongCategoryEntity>? categories,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionErrorMessage,
    bool clearActionErrorMessage = false,
    String? activeCategoryId,
    bool clearActiveCategoryId = false,
  }) {
    return SongCategoriesState(
      status: status ?? this.status,
      submission: submission ?? this.submission,
      categories: categories ?? this.categories,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      actionErrorMessage: clearActionErrorMessage
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
      activeCategoryId: clearActiveCategoryId
          ? null
          : (activeCategoryId ?? this.activeCategoryId),
    );
  }

  @override
  List<Object?> get props => [
    status,
    submission,
    categories,
    errorMessage,
    actionErrorMessage,
    activeCategoryId,
  ];
}
