import 'package:louvor4_app/features/user_profile/domain/entities/user_detail_entity.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/update_user_input_entity.dart';

abstract class UserRepository {
  Future<UserDetailEntity> getUserDetail();

  Future<UserDetailEntity> updateUserProfile(UpdateUserInputEntity input);

  Future<String> updateProfileImage({
    required String filePath,
    required String fileName,
  });
}
