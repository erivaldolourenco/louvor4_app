import 'package:equatable/equatable.dart';

import '../../domain/entities/user_detail_entity.dart';

enum UserStatus { initial, loading, success, failure }

class UserState extends Equatable {
  final UserStatus status;
  final UserDetailEntity? user;
  final String? errorMessage;

  const UserState({
     this.status = UserStatus.initial,
     this.user,
     this.errorMessage
  });

  UserState copyWith({
    UserStatus? status,
    UserDetailEntity? user,
    String? errorMessage,
  }) {
    return UserState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }


  @override
  List<Object?> get props => [status, user, errorMessage];


}