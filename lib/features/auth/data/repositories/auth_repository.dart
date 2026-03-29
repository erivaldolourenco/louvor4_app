import '../../domain/entities/authenticated_user_entity.dart';
import '../../domain/entities/create_user_input_entity.dart';

abstract class AuthRepository {
  Future<AuthenticatedUserEntity> login(String username, String password);

  Future<void> register(CreateUserInputEntity input);
}
