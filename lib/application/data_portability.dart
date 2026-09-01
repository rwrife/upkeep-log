import 'dart:typed_data';

enum TransferStatus { completed, cancelled }

final class TransferResult {
  const TransferResult(this.status, {this.path});
  final TransferStatus status;
  final String? path;
}

/// Explicit user-directed file handoff. Implementations use a share sheet for
/// export and a document picker for import; cancellation is not an error.
abstract interface class DataTransfer {
  Future<TransferResult> exportFile({
    required String suggestedName,
    required String mediaType,
    required Uint8List bytes,
  });

  Future<TransferResult> importBackup();
}

abstract interface class DataPortability {
  Future<Uint8List> createBackup();
  Future<Uint8List> exportCsv({String? homeId, String? assetId});
  Future<RestoreReport> restorePaths(
    String incomingPath, {
    required String preRestoreBackupPath,
  });
  Future<void> deleteHomeData(String homeId);
  Future<void> resetAllData();
  Future<LocalStorageSummary> storageSummary();
}

final class LocalStorageSummary {
  const LocalStorageSummary({
    required this.databaseBytes,
    required this.attachmentBytesByHome,
  });
  final int databaseBytes;
  final Map<String, int> attachmentBytesByHome;
  int get attachmentBytes =>
      attachmentBytesByHome.values.fold(0, (a, b) => a + b);
  int get totalBytes => databaseBytes + attachmentBytes;
}

final class RestoreReport {
  const RestoreReport({
    required this.schemaVersion,
    required this.homeCount,
    required this.attachmentCount,
    required this.preRestoreBackupPath,
    required this.conflictCount,
  });
  final int schemaVersion;
  final int homeCount;
  final int attachmentCount;
  final String preRestoreBackupPath;
  final int conflictCount;
}

final class PortabilityException implements Exception {
  const PortabilityException(this.message);
  final String message;
  @override
  String toString() => message;
}
