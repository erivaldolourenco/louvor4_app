import 'package:equatable/equatable.dart';

import '../../domain/entities/program_item_entity.dart';

enum EventProgramStatus { initial, loading, success, failure }

class EventProgramState extends Equatable {
  final EventProgramStatus status;
  final List<ProgramItemEntity> items;
  final String? errorMessage;
  final bool isActioning;
  final String? actionError;

  const EventProgramState({
    this.status = EventProgramStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.isActioning = false,
    this.actionError,
  });

  EventProgramState copyWith({
    EventProgramStatus? status,
    List<ProgramItemEntity>? items,
    String? errorMessage,
    bool? isActioning,
    String? actionError,
  }) {
    return EventProgramState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
      isActioning: isActioning ?? this.isActioning,
      actionError: actionError ?? this.actionError,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage, isActioning, actionError];
}
