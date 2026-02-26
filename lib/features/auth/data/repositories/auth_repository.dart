import '../../domain/entities/authenticated_user_entity.dart';

abstract class AuthRepository {
  Future<AuthenticatedUserEntity> login(String username, String password);
}