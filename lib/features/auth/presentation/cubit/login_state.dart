import 'package:equatable/equatable.dart';
import '../../domain/entities/authenticated_user_entity.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  final String username;
  final String password;
  final LoginStatus status;
  final String? errorMessage;
  final AuthenticatedUserEntity? auth;

  const LoginState({
    this.username = '',
    this.password = '',
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.auth,
  });

  LoginState copyWith({
    String? username,
    String? password,
    LoginStatus? status,
    String? errorMessage,
    AuthenticatedUserEntity? auth,
  }) {
    return LoginState(
      username: username ?? this.username,
      password: password ?? this.password,
      status: status ?? this.status,
      errorMessage: errorMessage,
      auth: auth ?? this.auth,
    );
  }

  @override
  List<Object?> get props => [username, password, status, errorMessage, auth];
}