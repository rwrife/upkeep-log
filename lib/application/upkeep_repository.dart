import 'package:upkeep_log/domain/domain.dart';

import 'portable_data.dart';

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
  Future<List<AttachmentMetadata>> attachments();
  Future<void> deleteAttachment(String id);
  Future<void> deleteRoom(String id);
  Future<void> deleteTask(String id);
  Future<void> deleteHome(String id);
  Future<PortableData> portableData();

  /// Replaces all structured state and records [restoreToken] in the same
  /// database transaction.
  Future<void> replacePortableData(PortableData value, {String? restoreToken});

  /// Token proving that the corresponding restore transaction committed.
  Future<String?> committedRestoreToken();

  /// Removes a restore token after its filesystem journal has been cleaned.
  Future<void> clearCommittedRestoreToken(String token);

  /// Deliberate privacy control; unlike [deleteHome], history is removed.
  Future<List<String>> deleteHomeData(String id);

  /// Deliberate privacy control returning attachment paths to remove.
  Future<List<String>> resetAllData();
}
