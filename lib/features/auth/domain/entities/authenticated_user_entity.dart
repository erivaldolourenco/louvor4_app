import 'package:equatable/equatable.dart';
import 'user_entity.dart';

class AuthenticatedUserEntity extends Equatable {
  final String accessToken;
  final String refreshToken;
  final String? expiresAt;
  final UserEntity user;

  const AuthenticatedUserEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.expiresAt,
  });

  // Backward-compatible alias.
  String get token => accessToken;

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt, user];
}
