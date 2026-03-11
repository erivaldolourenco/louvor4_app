import 'package:equatable/equatable.dart';

enum CreateProjectEventStatus { idle, validating, submitting, success, error }

class CreateProjectEventState extends Equatable {
  final CreateProjectEventStatus status;
  final String? errorMessage;

  const CreateProjectEventState({
    this.status = CreateProjectEventStatus.idle,
    this.errorMessage,
  });

  bool get isSubmitting => status == CreateProjectEventStatus.submitting;

  CreateProjectEventState copyWith({
    CreateProjectEventStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CreateProjectEventState(
      status: status ?? this.status,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
