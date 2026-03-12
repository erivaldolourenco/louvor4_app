import 'package:equatable/equatable.dart';

import '../../domain/entities/user_detail_entity.dart';

enum EditProfileStatus {
  initial,
  loadingProfile,
  editing,
  submitting,
  success,
  error,
}

class EditProfileState extends Equatable {
  final EditProfileStatus status;
  final UserDetailEntity? user;
  final String? errorMessage;

  const EditProfileState({
    this.status = EditProfileStatus.initial,
    this.user,
    this.errorMessage,
  });

  bool get isLoadingProfile => status == EditProfileStatus.loadingProfile;
  bool get isSubmitting => status == EditProfileStatus.submitting;

  EditProfileState copyWith({
    EditProfileStatus? status,
    UserDetailEntity? user,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return EditProfileState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}
