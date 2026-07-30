import 'package:equatable/equatable.dart';

enum CreateProjectEventBatchStatus {
  idle,
  validating,
  submitting,
  success,
  error,
}

class CreateProjectEventBatchState extends Equatable {
  final CreateProjectEventBatchStatus status;
  final String? errorMessage;

  const CreateProjectEventBatchState({
    this.status = CreateProjectEventBatchStatus.idle,
    this.errorMessage,
  });

  bool get isSubmitting => status == CreateProjectEventBatchStatus.submitting;

  CreateProjectEventBatchState copyWith({
    CreateProjectEventBatchStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CreateProjectEventBatchState(
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
