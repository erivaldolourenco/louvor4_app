import 'package:louvor4_app/features/user_profile/domain/entities/user_detail_entity.dart';

abstract class UserRepository {
  Future<UserDetailEntity> getUserDetail();
}