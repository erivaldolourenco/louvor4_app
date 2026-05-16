import 'package:equatable/equatable.dart';

import '../../domain/entities/medley_entity.dart';

enum MedleyStatus { initial, loading, success, failure }

class MedleyState extends Equatable {
  final MedleyStatus status;
  final List<MedleyEntity> medleys;
  final String? errorMessage;
  final bool isActioning;
  final String? actionError;

  const MedleyState({
    this.status = MedleyStatus.initial,
    this.medleys = const [],
    this.errorMessage,
    this.isActioning = false,
    this.actionError,
  });

  MedleyState copyWith({
    MedleyStatus? status,
    List<MedleyEntity>? medleys,
    String? errorMessage,
    bool? isActioning,
    String? actionError,
  }) {
    return MedleyState(
      status: status ?? this.status,
      medleys: medleys ?? this.medleys,
      errorMessage: errorMessage ?? this.errorMessage,
      isActioning: isActioning ?? this.isActioning,
      actionError: actionError ?? this.actionError,
    );
  }

  @override
  List<Object?> get props => [
    status,
    medleys,
    errorMessage,
    isActioning,
    actionError,
  ];
}
