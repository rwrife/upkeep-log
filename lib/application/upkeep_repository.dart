import 'package:upkeep_log/domain/domain.dart';

/// Application port for durable local upkeep records.
abstract interface class UpkeepRepository {
  Future<List<HomeProfile>> homes();
  Future<List<Room>> rooms();
  Future<List<Asset>> assets();
  Future<List<TaskTemplate>> tasks();
  Future<List<TaskOccurrence>> occurrences();
  Future<List<Completion>> completions();
  Future<void> saveHome(HomeProfile value);
  Future<HomeProfile?> homeById(String id);
  Future<void> saveRoom(Room value);
  Future<Room?> roomById(String id);
  Future<void> saveAsset(Asset value);
  Future<Asset?> assetById(String id);
  Future<void> saveTask(TaskTemplate value);
  Future<TaskTemplate?> taskById(String id);
  Future<void> saveOccurrence(TaskOccurrence value);
  Future<void> saveTaskWithOccurrence(
    TaskTemplate task,
    TaskOccurrence occurrence,
  );
  Future<TaskOccurrence?> occurrenceById(String id);
  Future<void> saveCompletion(Completion value);
  Future<void> completeOccurrence(
    Completion completion, {
    TaskOccurrence? nextOccurrence,
  });
  Future<void> appendCompletionRevision(Completion value);
  Future<List<Completion>> completionHistory(String completionId);
  Future<Completion?> latestCompletion(String completionId);
  Future<void> saveAttachment(AttachmentMetadata value);
  Future<List<AttachmentMetadata>> attachmentsForCompletion(
    String completionId,
  );
  Future<void> deleteRoom(String id);
  Future<void> deleteTask(String id);
  Future<void> deleteHome(String id);
}
