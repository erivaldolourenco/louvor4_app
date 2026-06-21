import '../domain/entities/create_medley_input_entity.dart';
import '../domain/entities/medley_entity.dart';

abstract class MedleyRepository {
  Future<List<MedleyEntity>> getUserMedleys();

  Future<MedleyEntity> createMedley(CreateMedleyInputEntity input);

  Future<MedleyEntity> updateMedley(String id, CreateMedleyInputEntity input);

  Future<void> deleteMedley(String id);

  Future<void> uploadReferenceAudio(String id, String filePath);
}
