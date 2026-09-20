import 'package:equatable/equatable.dart';

import '../../domain/entities/user_detail_entity.dart';

enum UserStatus { initial, loading, success, failure }

class UserState extends Equatable {
  final UserStatus status;
  final UserDetailEntity? user;
  final String? errorMessage;
  final bool isUploadingImage;

  const UserState({
    this.status = UserStatus.initial,
    this.user,
    this.errorMessage,
    this.isUploadingImage = false,
  });

  UserState copyWith({
    UserStatus? status,
    UserDetailEntity? user,
    String? errorMessage,
    bool? isUploadingImage,
    bool clearErrorMessage = false,
  }) {
    return UserState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, isUploadingImage];
}
