import 'package:equatable/equatable.dart';
import 'user_entity.dart';

class AuthenticatedUserEntity extends Equatable {
  final String token;
  final UserEntity user;

  const AuthenticatedUserEntity({
    required this.token,
    required this.user,
  });

  @override
  List<Object> get props => [token, user];
}