import '../domain/entities/program_item_entity.dart';
import '../domain/entities/program_item_input_entity.dart';

abstract class EventProgramRepository {
  Future<List<ProgramItemEntity>> getProgram(String eventId);

  Future<ProgramItemEntity> createTextItem(
    String eventId,
    CreateTextProgramItemInputEntity input,
  );

  Future<ProgramItemEntity> updateTextItem(
    String eventId,
    String itemId,
    UpdateTextProgramItemInputEntity input,
  );

  Future<void> deleteItem(String eventId, String itemId);

  Future<void> reorder(String eventId, List<String> orderedIds);
}
