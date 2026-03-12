import 'package:equatable/equatable.dart';

enum EditEventStatus { initial, editing, submitting, success, error }

class EditEventState extends Equatable {
  final EditEventStatus status;
  final String? errorMessage;

  const EditEventState({
    this.status = EditEventStatus.initial,
    this.errorMessage,
  });

  bool get isSubmitting => status == EditEventStatus.submitting;

  EditEventState copyWith({
    EditEventStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return EditEventState(
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
