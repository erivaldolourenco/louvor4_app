import 'package:louvor4_app/features/music_projects/domain/entities/music_project_entity.dart';

import '../domain/entities/create_user_unavailability_input_entity.dart';
import '../domain/entities/user_unavailability_entity.dart';

abstract class UserUnavailabilityRepository {
  Future<List<MusicProjectEntity>> getUserMusicProjects();

  Future<List<UserUnavailabilityEntity>> getUserUnavailabilities();

  Future<UserUnavailabilityEntity> createUserUnavailability(
    CreateUserUnavailabilityInputEntity input,
  );

  Future<void> deleteUserUnavailability(String unavailabilityId);
}
