import '../../domain/entities/authenticated_user_entity.dart';
import '../../domain/entities/create_user_input_entity.dart';
import '../../domain/entities/forgot_password_channels_entity.dart';

abstract class AuthRepository {
  Future<AuthenticatedUserEntity> login(String username, String password);

  Future<void> register(CreateUserInputEntity input);

  Future<ForgotPasswordChannelsEntity> getAvailableChannels(String email);

  Future<void> forgotPassword({required String email, required String channel});

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}
