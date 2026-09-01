import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:upkeep_log/application/application_mutation_gate.dart';
import 'package:upkeep_log/application/data_portability.dart';
import 'package:upkeep_log/application/portable_data.dart';
import 'package:upkeep_log/application/upkeep_repository.dart';
import 'package:upkeep_log/domain/domain.dart';

const int backupSchemaVersion = 1;
const int csvSchemaVersion = 1;

enum RestoreCrashBoundary {
  beforeLiveMove,
  afterLiveToRollback,
  afterStagedToLive,
  afterDatabaseCommit,
  duringCleanup,
}

final class RestoreCrashSimulation implements Exception {
  const RestoreCrashSimulation();
}

final class BackupLimits {
  const BackupLimits({
    this.maxArchiveBytes = 256 * 1024 * 1024,
    this.maxEntryBytes = 64 * 1024 * 1024,
    this.maxTotalBytes = 512 * 1024 * 1024,
    this.maxEntries = 2048,
  });
  final int maxArchiveBytes;
  final int maxEntryBytes;
  final int maxTotalBytes;
  final int maxEntries;
}

/// Versioned ZIP/JSON and RFC 4180 CSV implementation over app-private files.
final class DataPortabilityService implements DataPortability {
  DataPortabilityService({
    required this.repository,
    required Directory privateRoot,
    DateTime Function()? nowUtc,
    this.limits = const BackupLimits(),
    ApplicationMutationGate? mutationGate,
    Future<void> Function(String source, String target)? movePath,
    Future<void> Function(Directory directory)? deleteTree,
    this.crashBoundary,
  }) : _root = privateRoot.absolute,
       _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
       _mutationGate = mutationGate ?? ApplicationMutationGate(),
       _movePathOverride = movePath,
       _deleteTreeOverride = deleteTree;

  final UpkeepRepository repository;
  final Directory _root;
  final DateTime Function() _nowUtc;
  final BackupLimits limits;
  final ApplicationMutationGate _mutationGate;
  final Future<void> Function(String, String)? _movePathOverride;
  final Future<void> Function(Directory)? _deleteTreeOverride;
  final Future<void> Function(RestoreCrashBoundary)? crashBoundary;

  @override
  Future<LocalStorageSummary> storageSummary() =>
      _mutationGate.run(_storageSummary);

  Future<LocalStorageSummary> _storageSummary() async {
    final PortableData data = await repository.portableData();
    final Map<String, int> byHome = <String, int>{
      for (final HomeProfile home in data.homes) home.id: 0,
    };
    final Directory attachments = Directory('${_root.path}/attachments');
    await _rejectLink(attachments.path);
    if (await attachments.exists()) {
      await for (final FileSystemEntity entity in attachments.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is Link) {
          throw const PortabilityException(
            'Symbolic links are not allowed in private storage.',
          );
        }
        if (entity is! File) continue;
        final List<String> parts = _relativePrivate(entity.absolute.path)
            .split('/');
        final String home = parts.length > 1 ? parts[1] : 'unassigned';
        byHome[home] = (byHome[home] ?? 0) + await entity.length();
      }
    }
    var databaseBytes = 0;
    await for (final FileSystemEntity entity in _root.list(
      followLinks: false,
    )) {
      if (entity is File &&
          entity.path
              .split(Platform.pathSeparator)
              .last
              .startsWith('upkeep-log.sqlite')) {
        databaseBytes += await entity.length();
      }
    }
    return LocalStorageSummary(
      databaseBytes: databaseBytes,
      attachmentBytesByHome: Map<String, int>.unmodifiable(byHome),
    );
  }

  @override
  Future<Uint8List> createBackup() => _mutationGate.run(_createBackup);

  Future<Uint8List> _createBackup() async {
    final PortableData data = await repository.portableData();
    _validatePortableData(data);
    return _encodeBackup(data, _nowUtc().toUtc());
  }

  @override
  Future<Uint8List> exportCsv({String? homeId, String? assetId}) =>
      _mutationGate.run(() => _exportCsv(homeId: homeId, assetId: assetId));

  Future<Uint8List> _exportCsv({String? homeId, String? assetId}) async {
    final PortableData data = await repository.portableData();
    _validatePortableData(data);
    return Uint8List.fromList(utf8.encode(_csv(data, homeId, assetId)));
  }

  @override
  Future<void> deleteHomeData(String homeId) =>
      _mutationGate.run(() => _deleteHomeData(homeId));

  Future<void> _deleteHomeData(String homeId) async {
    _safeComponent(homeId, 'home ID');
    final List<AttachmentMetadata> all =
        (await repository.portableData()).attachments;
    final Directory quarantine = await _root.createTemp(
      '.delete-stage-${_nowUtc().microsecondsSinceEpoch}-',
    );
    final List<(File, File)> moved = <(File, File)>[];
    final Directory homeDirectory = Directory(
      (await _privateFile('attachments/$homeId/.keep')).parent.path,
    );
    await _rejectLink(homeDirectory.path);
    var committed = false;
    var rolledBack = false;
    try {
      for (final AttachmentMetadata item in all.where(
        (e) => _attachmentHome(e.relativePath) == homeId,
      )) {
        final File source = await _privateFile(item.relativePath);
        if (!await source.exists()) continue;
        final File target = File('${quarantine.path}/${item.relativePath}');
        await target.parent.create(recursive: true);
        await _move(source.path, target.path);
        moved.add((source, target));
      }
      if (await homeDirectory.exists()) {
        await for (final FileSystemEntity entity in homeDirectory.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is Link) {
            throw const PortabilityException(
              'Symbolic links are not allowed in private storage.',
            );
          }
          if (entity is! File) continue;
          final String relative = _relativePrivate(entity.absolute.path);
          final File target = File('${quarantine.path}/$relative');
          await target.parent.create(recursive: true);
          await _move(entity.path, target.path);
          moved.add((entity, target));
        }
      }
      await repository.deleteHomeData(homeId);
      committed = true;
    } catch (error, stackTrace) {
      if (!committed) {
        await _rollbackFiles(moved, error);
        rolledBack = true;
      }
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      if (committed || moved.isEmpty || rolledBack) {
        await _bestEffortDelete(quarantine);
      }
      if (committed) await _bestEffortDelete(homeDirectory);
    }
  }

  @override
  Future<void> resetAllData() => _mutationGate.run(_resetAllData);

  Future<void> _resetAllData() async {
    final Directory live = Directory('${_root.path}/attachments');
    await _rejectLink(live.path);
    final Directory stage = await _root.createTemp(
      '.reset-stage-${_nowUtc().microsecondsSinceEpoch}-',
    );
    final Directory quarantine = Directory('${stage.path}/attachments');
    var moved = false;
    var committed = false;
    var rolledBack = false;
    try {
      if (await live.exists()) {
        await _move(live.path, quarantine.path);
        moved = true;
      }
      try {
        await repository.resetAllData();
        committed = true;
      } catch (error, stackTrace) {
        if (moved && await quarantine.exists()) {
          await _move(quarantine.path, live.path);
          rolledBack = true;
        }
        Error.throwWithStackTrace(error, stackTrace);
      }
    } finally {
      if (committed || !moved || rolledBack) await _bestEffortDelete(stage);
    }
  }

  /// Creates and validates [preRestoreBackup], fully validates and stages the
  /// incoming archive, swaps private files, then replaces structured data in a
  /// single repository transaction. Any failure restores private files.
  Future<RestoreReport> restore(
    File incoming, {
    required File preRestoreBackup,
  }) => _mutationGate.run(
    () => _restore(incoming, preRestoreBackup: preRestoreBackup),
  );

  Future<RestoreReport> _restore(
    File incoming, {
    required File preRestoreBackup,
  }) async {
    final Uint8List before = await _createBackup();
    final _DecodedBackup currentBackup = await _decodeBackup(before);
    if (await preRestoreBackup.exists()) {
      final _DecodedBackup offeredBackup = await _decodeBackup(
        await _readBounded(preRestoreBackup, limits.maxArchiveBytes),
      );
      if (!_samePortableData(offeredBackup.data, currentBackup.data)) {
        throw const PortabilityException(
          'The offered pre-restore backup is stale. Export a new recovery '
          'copy and try restore again.',
        );
      }
    } else {
      await _atomicWrite(preRestoreBackup, before);
      await _decodeBackup(
        await _readBounded(preRestoreBackup, limits.maxArchiveBytes),
      );
    }

    if (await incoming.length() > limits.maxArchiveBytes) {
      throw const PortabilityException('Backup archive exceeds size limit.');
    }
    final _DecodedBackup decoded = await _decodeBackup(
      await _readBounded(incoming, limits.maxArchiveBytes),
    );
    final PortableData current = await repository.portableData();
    final Set<String> currentIds = current.homes.map((e) => e.id).toSet();
    final int conflicts = decoded.data.homes
        .where((e) => currentIds.contains(e.id))
        .length;

    final String token = _restoreToken();
    final Directory stage = Directory('${_root.path}/.restore-stage-$token');
    await stage.create();
    final Directory stagedAttachments = Directory('${stage.path}/attachments');
    var preserveStageForRecovery = false;
    try {
      for (final MapEntry<String, Uint8List> item
          in decoded.attachments.entries) {
        final File target = File('${stage.path}/${item.key}');
        await target.parent.create(recursive: true);
        await target.writeAsBytes(item.value, flush: true);
      }
      final Directory live = Directory('${_root.path}/attachments');
      await _rejectLink(live.path);
      final Directory rollback = Directory('${stage.path}/previous');
      await _writeJournal(token);
      await _boundary(RestoreCrashBoundary.beforeLiveMove);
      var movedLive = false;
      var installedStage = false;
      try {
        if (await live.exists()) {
          await _move(live.path, rollback.path);
          movedLive = true;
        }
        await _boundary(RestoreCrashBoundary.afterLiveToRollback);
        if (await stagedAttachments.exists()) {
          await _move(stagedAttachments.path, live.path);
          installedStage = true;
        }
        await _boundary(RestoreCrashBoundary.afterStagedToLive);
        await repository.replacePortableData(decoded.data, restoreToken: token);
        await _boundary(RestoreCrashBoundary.afterDatabaseCommit);
      } on RestoreCrashSimulation {
        preserveStageForRecovery = true;
        rethrow;
      } catch (error, stackTrace) {
        try {
          if (installedStage && await live.exists()) {
            await _move(live.path, '${stage.path}/failed-install');
          }
          if (movedLive && await rollback.exists()) {
            await _move(rollback.path, live.path);
          }
        } catch (rollbackError) {
          preserveStageForRecovery = true;
          throw PortabilityException(
            'Restore failed ($error) and file rollback failed '
            '($rollbackError). Staged files were retained for recovery.',
          );
        }
        await _deleteJournal();
        Error.throwWithStackTrace(error, stackTrace);
      }
      if (await rollback.exists()) await _deleteTree(rollback);
      await _boundary(RestoreCrashBoundary.duringCleanup);
      await _deleteJournal();
      await repository.clearCommittedRestoreToken(token);
      return RestoreReport(
        schemaVersion: backupSchemaVersion,
        homeCount: decoded.data.homes.length,
        attachmentCount: decoded.data.attachments.length,
        preRestoreBackupPath: preRestoreBackup.path,
        conflictCount: conflicts,
      );
    } finally {
      try {
        if (!preserveStageForRecovery && await stage.exists()) {
          await _deleteTree(stage);
        }
      } catch (_) {
        // Never report a committed restore as failed because cleanup failed.
      }
    }
  }

  @override
  Future<RestoreReport> restorePaths(
    String incomingPath, {
    required String preRestoreBackupPath,
  }) =>
      restore(File(incomingPath), preRestoreBackup: File(preRestoreBackupPath));

  /// Reconciles an interrupted restore before application state is exposed.
  Future<void> recoverInterruptedRestore() =>
      _mutationGate.run(_recoverInterruptedRestore);

  Future<void> _recoverInterruptedRestore() async {
    final File journal = _journalFile;
    final String? committed = await repository.committedRestoreToken();
    if (!await journal.exists()) {
      if (committed != null) {
        await repository.clearCommittedRestoreToken(committed);
      }
      return;
    }
    final Map<String, Object?> value;
    try {
      final Object? decoded = jsonDecode(
        utf8.decode(await _readBounded(journal, 4096), allowMalformed: false),
      );
      if (decoded is! Map<String, Object?>) throw const FormatException();
      value = decoded;
    } catch (error) {
      throw PortabilityException(
        'Restore recovery journal is invalid and was preserved: $error',
      );
    }
    final Object? rawToken = value['token'];
    final Object? rawStage = value['stage'];
    if (value['version'] != 1 ||
        rawToken is! String ||
        !_restoreTokenPattern.hasMatch(rawToken) ||
        rawStage != '.restore-stage-$rawToken') {
      throw const PortabilityException(
        'Restore recovery journal contains unsafe paths and was preserved.',
      );
    }
    final Directory stage = Directory('${_root.path}/$rawStage').absolute;
    final String prefix = '${_root.path}${Platform.pathSeparator}';
    if (!stage.path.startsWith(prefix)) {
      throw const PortabilityException(
        'Restore recovery path escaped private storage and was preserved.',
      );
    }
    await _rejectLink(stage.path);
    final Directory live = Directory('${_root.path}/attachments');
    final Directory rollback = Directory('${stage.path}/previous');
    try {
      if (committed == rawToken) {
        if (await rollback.exists()) await _deleteTree(rollback);
      } else if (await rollback.exists()) {
        if (await live.exists()) {
          final Directory failed = Directory('${stage.path}/failed-install');
          if (await failed.exists()) await _deleteTree(failed);
          await _move(live.path, failed.path);
        }
        await _move(rollback.path, live.path);
      }
      if (await stage.exists()) await _deleteTree(stage);
      await _deleteJournal();
      if (committed != null) {
        await repository.clearCommittedRestoreToken(committed);
      }
    } catch (error) {
      throw PortabilityException(
        'Restore recovery failed; journal and artifacts were preserved: $error',
      );
    }
  }

  Future<Uint8List> _encodeBackup(PortableData data, DateTime generated) async {
    final Map<String, Object?> jsonData = _dataToJson(data);
    final Uint8List dataBytes = Uint8List.fromList(
      utf8.encode(jsonEncode(jsonData)),
    );
    _checkExportEntry('data.json', dataBytes.length);
    var totalBytes = dataBytes.length;
    final Archive archive = Archive();
    archive.addFile(ArchiveFile('data.json', dataBytes.length, dataBytes));
    final Map<String, String> hashes = <String, String>{
      'data.json': sha256.convert(dataBytes).toString(),
    };
    for (final AttachmentMetadata metadata in data.attachments) {
      _safePath(metadata.relativePath);
      final File file = await _privateFile(metadata.relativePath);
      if (!await file.exists()) {
        throw PortabilityException(
          'Referenced attachment is missing: ${metadata.relativePath}',
        );
      }
      final int declaredLength = await file.length();
      _checkExportEntry(metadata.relativePath, declaredLength);
      totalBytes += declaredLength;
      if (totalBytes > limits.maxTotalBytes) {
        throw const PortabilityException(
          'Backup source exceeds the total size limit.',
        );
      }
      final Uint8List bytes = await _readBounded(file, declaredLength);
      if (bytes.length != declaredLength) {
        throw PortabilityException(
          'Attachment changed while exporting: ${metadata.relativePath}',
        );
      }
      final String hash = sha256.convert(bytes).toString();
      if (hash != metadata.sha256) {
        throw PortabilityException(
          'Referenced attachment checksum failed: ${metadata.relativePath}',
        );
      }
      archive.addFile(ArchiveFile(metadata.relativePath, bytes.length, bytes));
      hashes[metadata.relativePath] = hash;
    }
    final Map<String, Object?> manifest = <String, Object?>{
      'format': 'upkeep-log-backup',
      'schemaVersion': backupSchemaVersion,
      'generatedAtUtc': generated.toIso8601String(),
      'hashAlgorithm': 'sha256',
      'entries': hashes.entries
          .map((e) => <String, Object?>{'path': e.key, 'sha256': e.value})
          .toList(),
      'counts': <String, int>{
        'homes': data.homes.length,
        'rooms': data.rooms.length,
        'assets': data.assets.length,
        'tasks': data.tasks.length,
        'occurrences': data.occurrences.length,
        'completionRevisions': data.completionRevisions.length,
        'attachments': data.attachments.length,
      },
    };
    final Uint8List manifestBytes = Uint8List.fromList(
      utf8.encode(jsonEncode(manifest)),
    );
    _checkExportEntry('manifest.json', manifestBytes.length);
    totalBytes += manifestBytes.length;
    if (totalBytes > limits.maxTotalBytes) {
      throw const PortabilityException(
        'Backup source exceeds the total size limit.',
      );
    }
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );
    final Uint8List encoded = ZipEncoder().encodeBytes(archive);
    if (encoded.length > limits.maxArchiveBytes) {
      throw const PortabilityException('Backup archive exceeds size limit.');
    }
    return encoded;
  }

  Future<_DecodedBackup> _decodeBackup(Uint8List bytes) async {
    if (bytes.length > limits.maxArchiveBytes) {
      throw const PortabilityException('Backup archive exceeds size limit.');
    }
    // ZipDecoder keeps ordinary payloads lazy, but materializes Unix symlink
    // entries while building ArchiveFile objects. Inspect the central
    // directory first so no declared payload is expanded before all declared
    // entry and aggregate limits have passed.
    try {
      final ZipDirectory directory = ZipDirectory()
        ..read(InputMemoryStream(bytes));
      if (directory.fileHeaders.length > limits.maxEntries) {
        throw const PortabilityException('Backup contains too many entries.');
      }
      var declaredTotal = 0;
      final Set<String> names = <String>{};
      for (final ZipFileHeader header in directory.fileHeaders) {
        _safePath(header.filename);
        if (!names.add(header.filename)) {
          throw PortabilityException(
            'Duplicate archive entry: ${header.filename}',
          );
        }
        final int unixType = (header.externalFileAttributes >> 16) & 0xf000;
        if (header.filename.endsWith('/') ||
            header.filename.endsWith('\\') ||
            unixType == 0xa000 ||
            (unixType != 0 && unixType != 0x8000)) {
          throw PortabilityException(
            'Backup contains a non-file entry: ${header.filename}',
          );
        }
        if (header.uncompressedSize > limits.maxEntryBytes) {
          throw PortabilityException(
            'Archive entry exceeds size limit: ${header.filename}',
          );
        }
        declaredTotal += header.uncompressedSize;
        if (declaredTotal > limits.maxTotalBytes) {
          throw const PortabilityException(
            'Backup expands beyond the total size limit.',
          );
        }
      }
    } on PortabilityException {
      rethrow;
    } catch (_) {
      throw const PortabilityException('Backup is not a valid ZIP archive.');
    }
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: true);
    } catch (_) {
      throw const PortabilityException('Backup is not a valid ZIP archive.');
    }
    if (archive.length > limits.maxEntries) {
      throw const PortabilityException('Backup contains too many entries.');
    }
    final Map<String, ArchiveFile> files = <String, ArchiveFile>{};
    var total = 0;
    for (final ArchiveFile entry in archive) {
      if (!entry.isFile) continue;
      _safePath(entry.name);
      if (files.containsKey(entry.name)) {
        throw PortabilityException('Duplicate archive entry: ${entry.name}');
      }
      if (entry.size > limits.maxEntryBytes) {
        throw PortabilityException(
          'Archive entry exceeds size limit: ${entry.name}',
        );
      }
      total += entry.size;
      if (total > limits.maxTotalBytes) {
        throw const PortabilityException(
          'Backup expands beyond the total size limit.',
        );
      }
      files[entry.name] = entry;
    }
    var actualTotal = 0;
    for (final MapEntry<String, ArchiveFile> item in files.entries) {
      final Uint8List content = item.value.content;
      if (content.length != item.value.size ||
          content.length > limits.maxEntryBytes) {
        throw PortabilityException(
          'Archive entry size is inconsistent: ${item.key}',
        );
      }
      actualTotal += content.length;
      if (actualTotal > limits.maxTotalBytes) {
        throw const PortabilityException(
          'Backup expands beyond the total size limit.',
        );
      }
    }
    final Uint8List manifestBytes = _requiredEntry(
      files,
      'manifest.json',
      limits,
    );
    final Uint8List dataBytes = _requiredEntry(files, 'data.json', limits);
    final Map<String, Object?> manifest = _object(manifestBytes, 'manifest');
    if (manifest['format'] != 'upkeep-log-backup') {
      throw const PortabilityException('Unsupported backup format.');
    }
    final int version = _int(manifest, 'schemaVersion');
    if (version > backupSchemaVersion) {
      throw PortabilityException(
        'Backup schema version $version is newer than supported version $backupSchemaVersion.',
      );
    }
    if (version < 1) {
      throw PortabilityException('Unsupported backup schema version $version.');
    }
    _utc(manifest, 'generatedAtUtc');
    if (manifest['hashAlgorithm'] != 'sha256') {
      throw const PortabilityException('Unsupported backup hash algorithm.');
    }
    final List<Object?> entries = _list(manifest, 'entries');
    final Map<String, String> expected = <String, String>{};
    for (final Object? raw in entries) {
      final Map<String, Object?> item = _map(raw, 'manifest entry');
      final String path = _string(item, 'path');
      _safePath(path);
      if (expected.containsKey(path)) {
        throw PortabilityException('Duplicate manifest entry: $path');
      }
      expected[path] = _hash(item, 'sha256');
    }
    if (expected.keys.toSet().difference(files.keys.toSet()).isNotEmpty ||
        files.keys.toSet().difference(<String>{
          ...expected.keys,
          'manifest.json',
        }).isNotEmpty) {
      throw const PortabilityException(
        'Archive entries do not match the manifest.',
      );
    }
    for (final MapEntry<String, String> item in expected.entries) {
      final String actual = sha256
          .convert(_requiredEntry(files, item.key, limits))
          .toString();
      if (actual != item.value) {
        throw PortabilityException('Checksum failed for ${item.key}.');
      }
    }
    final PortableData data = _dataFromJson(_object(dataBytes, 'data'));
    final Map<String, Object?> counts = _map(manifest['counts'], 'counts');
    final Map<String, int> actualCounts = <String, int>{
      'homes': data.homes.length,
      'rooms': data.rooms.length,
      'assets': data.assets.length,
      'tasks': data.tasks.length,
      'occurrences': data.occurrences.length,
      'completionRevisions': data.completionRevisions.length,
      'attachments': data.attachments.length,
    };
    for (final MapEntry<String, int> item in actualCounts.entries) {
      if (_int(counts, item.key) != item.value) {
        throw PortabilityException('Manifest count mismatch: ${item.key}.');
      }
    }
    final Map<String, Uint8List> attachmentBytes = <String, Uint8List>{};
    final Set<String> referenced = data.attachments
        .map((e) => e.relativePath)
        .toSet();
    if (referenced.length != data.attachments.length) {
      throw const PortabilityException('Attachment paths must be unique.');
    }
    for (final AttachmentMetadata metadata in data.attachments) {
      final Uint8List content = _requiredEntry(
        files,
        metadata.relativePath,
        limits,
      );
      if (sha256.convert(content).toString() != metadata.sha256) {
        throw PortabilityException(
          'Attachment checksum failed: ${metadata.relativePath}',
        );
      }
      attachmentBytes[metadata.relativePath] = content;
    }
    if (expected.keys
        .where((e) => e != 'data.json')
        .toSet()
        .difference(referenced)
        .isNotEmpty) {
      throw const PortabilityException(
        'Backup contains an unreferenced attachment.',
      );
    }
    return _DecodedBackup(data, attachmentBytes);
  }

  void _checkExportEntry(String path, int bytes) {
    if (bytes > limits.maxEntryBytes) {
      throw PortabilityException('Backup source exceeds size limit: $path');
    }
  }

  Future<Uint8List> _readBounded(File file, int maximum) async {
    final BytesBuilder output = BytesBuilder(copy: false);
    await for (final List<int> chunk in file.openRead(0, maximum + 1)) {
      output.add(chunk);
    }
    final Uint8List bytes = output.takeBytes();
    if (bytes.length > maximum) {
      throw const PortabilityException('File exceeds size limit.');
    }
    return bytes;
  }

  Future<File> _privateFile(String relativePath) async {
    _safePath(relativePath);
    await _root.create(recursive: true);
    final String canonicalRoot = await _root.resolveSymbolicLinks();
    final File file = File('${_root.path}/$relativePath').absolute;
    await _rejectLink(file.path);
    if (await file.parent.exists()) {
      final String parent = await file.parent.resolveSymbolicLinks();
      if (!_within(canonicalRoot, parent)) {
        throw PortabilityException(
          'Private path escaped storage: $relativePath',
        );
      }
    }
    return file;
  }

  String _relativePrivate(String absolutePath) {
    final String prefix = '${_root.path}${Platform.pathSeparator}';
    if (!absolutePath.startsWith(prefix)) {
      throw const PortabilityException('Private path escaped storage.');
    }
    return absolutePath
        .substring(prefix.length)
        .replaceAll(Platform.pathSeparator, '/');
  }

  Future<void> _rejectLink(String path) async {
    if (await FileSystemEntity.type(path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const PortabilityException(
        'Symbolic links are not allowed in private storage.',
      );
    }
  }

  Future<void> _move(String source, String target) async {
    if (_movePathOverride != null) return _movePathOverride(source, target);
    await _rejectLink(source);
    final FileSystemEntityType type = await FileSystemEntity.type(
      source,
      followLinks: false,
    );
    if (type == FileSystemEntityType.directory) {
      await Directory(source).rename(target);
    } else if (type == FileSystemEntityType.file) {
      await File(source).rename(target);
    } else {
      throw FileSystemException('Path cannot be moved', source);
    }
  }

  Future<void> _deleteTree(Directory directory) async {
    if (_deleteTreeOverride != null) return _deleteTreeOverride(directory);
    await _rejectLink(directory.path);
    await directory.delete(recursive: true);
  }

  Future<void> _bestEffortDelete(Directory directory) async {
    try {
      if (await directory.exists()) await _deleteTree(directory);
    } catch (_) {
      // Cleanup after a committed operation must not change its result.
    }
  }

  File get _journalFile => File('${_root.path}/.restore-journal.json');

  String _restoreToken() {
    final Random random = Random.secure();
    final String entropy = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${_nowUtc().microsecondsSinceEpoch}-$entropy';
  }

  Future<void> _boundary(RestoreCrashBoundary boundary) async {
    if (crashBoundary != null) await crashBoundary!(boundary);
  }

  Future<void> _writeJournal(String token) => _atomicWrite(
    _journalFile,
    Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'version': 1,
          'token': token,
          'stage': '.restore-stage-$token',
        }),
      ),
    ),
  );

  Future<void> _deleteJournal() async {
    if (await _journalFile.exists()) await _journalFile.delete();
  }

  Future<void> _atomicWrite(File target, Uint8List bytes) async {
    await target.parent.create(recursive: true);
    final File temporary = File('${target.path}.tmp');
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(target.path);
    } catch (_) {
      try {
        if (await temporary.exists()) await temporary.delete();
      } catch (_) {
        // Preserve the original write failure.
      }
      rethrow;
    }
  }

  Future<void> _rollbackFiles(
    List<(File, File)> moved,
    Object originalError,
  ) async {
    try {
      for (final (File source, File target) in moved.reversed) {
        if (!await target.exists()) continue;
        await source.parent.create(recursive: true);
        await _move(target.path, source.path);
      }
    } catch (rollbackError) {
      throw PortabilityException(
        'Operation failed ($originalError) and file rollback failed '
        '($rollbackError). Staged files were retained for recovery.',
      );
    }
  }
}

final RegExp _restoreTokenPattern = RegExp(r'^[0-9]+-[0-9a-f]{32}$');

final class _DecodedBackup {
  const _DecodedBackup(this.data, this.attachments);
  final PortableData data;
  final Map<String, Uint8List> attachments;
}

bool _samePortableData(PortableData left, PortableData right) =>
    jsonEncode(_dataToJson(left)) == jsonEncode(_dataToJson(right));

Map<String, Object?> _dataToJson(PortableData d) => <String, Object?>{
  'homes': d.homes
      .map(
        (e) => <String, Object?>{
          'id': e.id,
          'name': e.name,
          'addressLabel': e.addressLabel,
        },
      )
      .toList(),
  'rooms': d.rooms
      .map(
        (e) => <String, Object?>{
          'id': e.id,
          'homeId': e.homeId,
          'name': e.name,
        },
      )
      .toList(),
  'assets': d.assets
      .map(
        (e) => <String, Object?>{
          'id': e.id,
          'homeId': e.homeId,
          'roomId': e.roomId,
          'name': e.name,
        },
      )
      .toList(),
  'tasks': d.tasks.map((e) {
    final (String, int) recurrence = _encodeRecurrence(e.recurrence);
    return <String, Object?>{
      'id': e.id,
      'homeId': e.homeId,
      'roomId': e.roomId,
      'assetId': e.assetId,
      'name': e.name,
      'startDate': e.startDate.toIso8601String(),
      'recurrenceKind': recurrence.$1,
      'recurrenceInterval': recurrence.$2,
      'recurrenceAnchor': e.recurrence.anchor.name,
      'recurrenceAnchorDay': e.recurrenceAnchorDay,
      'recurrenceAnchorMonth': e.recurrenceAnchorMonth,
      'reminder': e.reminder == null
          ? null
          : <String, Object?>{
              'hour': e.reminder!.hour,
              'minute': e.reminder!.minute,
              'timeZoneId': e.reminder!.timeZoneId,
            },
      'paused': e.paused,
    };
  }).toList(),
  'occurrences': d.occurrences
      .map(
        (e) => <String, Object?>{
          'id': e.id,
          'taskTemplateId': e.taskTemplateId,
          'scheduledDate': e.scheduledDate.toIso8601String(),
          'snoozedUntil': e.snoozedUntil?.toIso8601String(),
          'state': e.state.name,
        },
      )
      .toList(),
  'completionRevisions': d.completionRevisions
      .map(
        (e) => <String, Object?>{
          'id': e.id,
          'occurrenceId': e.occurrenceId,
          'scheduledDate': e.scheduledDate.toIso8601String(),
          'actualDate': e.actualDate.toIso8601String(),
          'notes': e.notes,
          'parts': e.parts,
          'costMinorUnits': e.cost?.minorUnits,
          'costCurrency': e.cost?.currency,
          'revision': e.revision,
          'revisedAtUtc': e.revisedAtUtc.toUtc().toIso8601String(),
        },
      )
      .toList(),
  'attachments': d.attachments
      .map(
        (e) => <String, Object?>{
          'id': e.id,
          'completionId': e.completionId,
          'relativePath': e.relativePath,
          'mediaType': e.mediaType,
          'sha256': e.sha256,
          'caption': e.caption,
        },
      )
      .toList(),
};

PortableData _dataFromJson(Map<String, Object?> root) {
  try {
    final List<HomeProfile> homes = _list(root, 'homes').map((raw) {
      final m = _map(raw, 'home');
      return HomeProfile(
        id: _string(m, 'id'),
        name: _string(m, 'name'),
        addressLabel: _nullableString(m, 'addressLabel'),
      );
    }).toList();
    final List<Room> rooms = _list(root, 'rooms').map((raw) {
      final m = _map(raw, 'room');
      return Room(
        id: _string(m, 'id'),
        homeId: _string(m, 'homeId'),
        name: _string(m, 'name'),
      );
    }).toList();
    final List<Asset> assets = _list(root, 'assets').map((raw) {
      final m = _map(raw, 'asset');
      return Asset(
        id: _string(m, 'id'),
        homeId: _string(m, 'homeId'),
        roomId: _nullableString(m, 'roomId'),
        name: _string(m, 'name'),
      );
    }).toList();
    final List<TaskTemplate> tasks = _list(root, 'tasks').map((raw) {
      final m = _map(raw, 'task');
      final Object? reminderRaw = m['reminder'];
      final Map<String, Object?>? reminder = reminderRaw == null
          ? null
          : _map(reminderRaw, 'reminder');
      return TaskTemplate(
        id: _string(m, 'id'),
        homeId: _string(m, 'homeId'),
        roomId: _nullableString(m, 'roomId'),
        assetId: _nullableString(m, 'assetId'),
        name: _string(m, 'name'),
        startDate: _date(m, 'startDate'),
        recurrence: _decodeRecurrence(
          _string(m, 'recurrenceKind'),
          _int(m, 'recurrenceInterval'),
          _string(m, 'recurrenceAnchor'),
        ),
        recurrenceAnchorDay: _int(m, 'recurrenceAnchorDay'),
        recurrenceAnchorMonth: _int(m, 'recurrenceAnchorMonth'),
        reminder: reminder == null
            ? null
            : ReminderIntent(
                hour: _int(reminder, 'hour'),
                minute: _int(reminder, 'minute'),
                timeZoneId: _string(reminder, 'timeZoneId'),
              ),
        paused: _bool(m, 'paused'),
      );
    }).toList();
    final List<TaskOccurrence> occurrences = _list(root, 'occurrences').map((
      raw,
    ) {
      final m = _map(raw, 'occurrence');
      return TaskOccurrence(
        id: _string(m, 'id'),
        taskTemplateId: _string(m, 'taskTemplateId'),
        scheduledDate: _date(m, 'scheduledDate'),
        snoozedUntil: _nullableDate(m, 'snoozedUntil'),
        state: OccurrenceState.values.byName(_string(m, 'state')),
      );
    }).toList();
    final List<Completion> revisions = _list(root, 'completionRevisions').map((
      raw,
    ) {
      final m = _map(raw, 'completion revision');
      final int? cost = _nullableInt(m, 'costMinorUnits');
      final String? currency = _nullableString(m, 'costCurrency');
      if ((cost == null) != (currency == null)) {
        throw const FormatException('Incomplete cost');
      }
      return Completion(
        id: _string(m, 'id'),
        occurrenceId: _string(m, 'occurrenceId'),
        scheduledDate: _date(m, 'scheduledDate'),
        actualDate: _date(m, 'actualDate'),
        notes: _nullableString(m, 'notes'),
        parts: _nullableString(m, 'parts'),
        cost: cost == null
            ? null
            : Money(minorUnits: cost, currency: currency!),
        revision: _int(m, 'revision'),
        revisedAtUtc: _utc(m, 'revisedAtUtc'),
      );
    }).toList();
    final List<AttachmentMetadata> attachments = _list(root, 'attachments').map(
      (raw) {
        final m = _map(raw, 'attachment');
        return AttachmentMetadata(
          id: _string(m, 'id'),
          completionId: _string(m, 'completionId'),
          relativePath: _string(m, 'relativePath'),
          mediaType: _string(m, 'mediaType'),
          sha256: _hash(m, 'sha256'),
          caption: _nullableString(m, 'caption'),
        );
      },
    ).toList();
    _validateReferences(
      homes,
      rooms,
      assets,
      tasks,
      occurrences,
      revisions,
      attachments,
    );
    return PortableData(
      homes: homes,
      rooms: rooms,
      assets: assets,
      tasks: tasks,
      occurrences: occurrences,
      completionRevisions: revisions,
      attachments: attachments,
    );
  } catch (error) {
    if (error is PortabilityException) rethrow;
    throw PortabilityException('Backup data is invalid: $error');
  }
}

void _validateReferences(
  List<HomeProfile> homes,
  List<Room> rooms,
  List<Asset> assets,
  List<TaskTemplate> tasks,
  List<TaskOccurrence> occurrences,
  List<Completion> revisions,
  List<AttachmentMetadata> attachments,
) {
  Set<String> unique(Iterable<String> ids, String kind) {
    final result = ids.toSet();
    if (result.length != ids.length) {
      throw PortabilityException('Duplicate $kind ID.');
    }
    return result;
  }

  final homeIds = unique(homes.map((e) => e.id), 'home');
  unique(rooms.map((e) => e.id), 'room');
  unique(assets.map((e) => e.id), 'asset');
  final taskIds = unique(tasks.map((e) => e.id), 'task');
  final occurrenceIds = unique(occurrences.map((e) => e.id), 'occurrence');
  final completionIds = revisions.map((e) => e.id).toSet();
  unique(attachments.map((e) => e.id), 'attachment');
  final roomHome = {for (final e in rooms) e.id: e.homeId};
  final assetHome = {for (final e in assets) e.id: e.homeId};
  final taskHome = {for (final e in tasks) e.id: e.homeId};
  final occurrenceById = {for (final e in occurrences) e.id: e};
  if (rooms.any((e) => !homeIds.contains(e.homeId)) ||
      assets.any(
        (e) =>
            !homeIds.contains(e.homeId) ||
            (e.roomId != null && roomHome[e.roomId] != e.homeId),
      ) ||
      tasks.any(
        (e) =>
            !homeIds.contains(e.homeId) ||
            (e.roomId != null && roomHome[e.roomId] != e.homeId) ||
            (e.assetId != null && assetHome[e.assetId] != e.homeId),
      ) ||
      occurrences.any((e) => !taskIds.contains(e.taskTemplateId)) ||
      revisions.any((e) => !occurrenceIds.contains(e.occurrenceId)) ||
      attachments.any((e) => !completionIds.contains(e.completionId))) {
    throw const PortabilityException(
      'Backup contains a missing or cross-home reference.',
    );
  }
  final grouped = <String, List<Completion>>{};
  final completionIdByOccurrence = <String, String>{};
  for (final e in revisions) {
    grouped.putIfAbsent(e.id, () => []).add(e);
    final String? prior = completionIdByOccurrence[e.occurrenceId];
    if (prior != null && prior != e.id) {
      throw const PortabilityException(
        'An occurrence may have only one completion history.',
      );
    }
    completionIdByOccurrence[e.occurrenceId] = e.id;
  }
  for (final MapEntry<String, List<Completion>> group in grouped.entries) {
    final List<Completion> history = group.value;
    if (history.isEmpty) {
      throw const PortabilityException('Completion history may not be empty.');
    }
    history.sort((a, b) => a.revision.compareTo(b.revision));
    final TaskOccurrence occurrence =
        occurrenceById[history.first.occurrenceId]!;
    for (var i = 0; i < history.length; i++) {
      if (history[i].revision != i + 1 ||
          (i > 0 &&
              !history[i].revisedAtUtc.isAfter(history[i - 1].revisedAtUtc)) ||
          history[i].occurrenceId != history.first.occurrenceId ||
          history[i].scheduledDate != history.first.scheduledDate ||
          history[i].scheduledDate != occurrence.scheduledDate) {
        throw const PortabilityException(
          'Completion revision history is inconsistent.',
        );
      }
    }
  }
  for (final AttachmentMetadata attachment in attachments) {
    final Completion completion = revisions.firstWhere(
      (Completion value) => value.id == attachment.completionId,
    );
    final TaskOccurrence occurrence = occurrenceById[completion.occurrenceId]!;
    final String expectedHome = taskHome[occurrence.taskTemplateId]!;
    if (_attachmentHome(attachment.relativePath) != expectedHome) {
      throw const PortabilityException(
        'Attachment path does not belong to its completion home.',
      );
    }
  }
  final completed = revisions.map((e) => e.occurrenceId).toSet();
  if (occurrences.any(
    (e) => (e.state == OccurrenceState.completed) != completed.contains(e.id),
  )) {
    throw const PortabilityException(
      'Occurrence state does not match completion history.',
    );
  }
}

void _validatePortableData(PortableData data) => _validateReferences(
  data.homes,
  data.rooms,
  data.assets,
  data.tasks,
  data.occurrences,
  data.completionRevisions,
  data.attachments,
);

String _csv(PortableData d, String? homeId, String? assetId) {
  const header = <String>[
    'schema_version',
    'home_id',
    'home_name',
    'home_address',
    'room_id',
    'room_name',
    'asset_id',
    'asset_name',
    'task_id',
    'task_name',
    'occurrence_id',
    'scheduled_date',
    'snoozed_until',
    'occurrence_state',
    'completion_id',
    'actual_date',
    'notes',
    'parts',
    'cost_minor_units',
    'cost_currency',
    'revision',
    'revised_at_utc',
  ];
  final homes = {for (final e in d.homes) e.id: e};
  final rooms = {for (final e in d.rooms) e.id: e};
  final assets = {for (final e in d.assets) e.id: e};
  final tasks = {for (final e in d.tasks) e.id: e};
  final occurrences = {for (final e in d.occurrences) e.id: e};
  final rows = <List<String>>[];
  for (final c in d.completionRevisions) {
    final o = occurrences[c.occurrenceId]!;
    final t = tasks[o.taskTemplateId]!;
    if (homeId != null && t.homeId != homeId ||
        assetId != null && t.assetId != assetId) {
      continue;
    }
    final h = homes[t.homeId]!;
    final a = t.assetId == null ? null : assets[t.assetId];
    final r = t.roomId == null
        ? (a?.roomId == null ? null : rooms[a!.roomId])
        : rooms[t.roomId];
    rows.add(<String>[
      '$csvSchemaVersion',
      h.id,
      h.name,
      h.addressLabel ?? '',
      r?.id ?? '',
      r?.name ?? '',
      a?.id ?? '',
      a?.name ?? '',
      t.id,
      t.name,
      o.id,
      o.scheduledDate.toIso8601String(),
      o.snoozedUntil?.toIso8601String() ?? '',
      o.state.name,
      c.id,
      c.actualDate.toIso8601String(),
      c.notes ?? '',
      c.parts ?? '',
      c.cost?.minorUnits.toString() ?? '',
      c.cost?.currency ?? '',
      c.revision.toString(),
      c.revisedAtUtc.toUtc().toIso8601String(),
    ]);
  }
  rows.sort((a, b) {
    for (final i in <int>[0, 1, 6, 8, 11, 14, 20]) {
      final c = a[i].compareTo(b[i]);
      if (c != 0) return c;
    }
    return 0;
  });
  return '${<List<String>>[header, ...rows].map((r) => r.map(_csvField).join(',')).join('\r\n')}\r\n';
}

String _csvField(String value) => RegExp('[,"\\r\\n]').hasMatch(value)
    ? '"${value.replaceAll('"', '""')}"'
    : value;

(String, int) _encodeRecurrence(RecurrencePolicy value) => switch (value) {
  OneTimeRecurrence() => ('oneTime', 1),
  FixedDayRecurrence(:final days) => ('fixedDay', days),
  WeeklyRecurrence(:final intervalWeeks) => ('weekly', intervalWeeks),
  MonthlyRecurrence(:final intervalMonths) => ('monthly', intervalMonths),
  YearlyRecurrence(:final intervalYears) => ('yearly', intervalYears),
};
RecurrencePolicy _decodeRecurrence(String kind, int interval, String anchor) {
  final a = RecurrenceAnchor.values.byName(anchor);
  return switch (kind) {
    'oneTime' => const OneTimeRecurrence(),
    'fixedDay' => FixedDayRecurrence(interval, anchor: a),
    'weekly' => WeeklyRecurrence(intervalWeeks: interval, anchor: a),
    'monthly' => MonthlyRecurrence(intervalMonths: interval, anchor: a),
    'yearly' => YearlyRecurrence(intervalYears: interval, anchor: a),
    _ => throw const FormatException('Unknown recurrence kind'),
  };
}

void _safePath(String path) {
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.startsWith('\\') ||
      RegExp(r'^[A-Za-z]:').hasMatch(path) ||
      path
          .split(RegExp(r'[/\\]'))
          .any((e) => e.isEmpty || e == '.' || e == '..')) {
    throw PortabilityException('Unsafe archive path: $path');
  }
}

Uint8List _requiredEntry(
  Map<String, ArchiveFile> files,
  String name,
  BackupLimits limits,
) {
  final entry = files[name];
  if (entry == null) {
    throw PortabilityException('Required archive entry is missing: $name');
  }
  final Uint8List content = entry.content;
  if (content.length != entry.size || content.length > limits.maxEntryBytes) {
    throw PortabilityException('Archive entry size is inconsistent: $name');
  }
  return content;
}

String _attachmentHome(String path) {
  _safePath(path);
  final List<String> parts = path.split('/');
  if (parts.length != 3 || parts.first != 'attachments') {
    throw PortabilityException(
      'Attachment path must be exactly attachments/<home-id>/<file>: $path',
    );
  }
  _safeComponent(parts[1], 'attachment home ID');
  return parts[1];
}

void _safeComponent(String value, String name) {
  if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(value) ||
      value == '.' ||
      value == '..') {
    throw PortabilityException('Unsafe $name.');
  }
}

bool _within(String root, String value) =>
    value == root || value.startsWith('$root${Platform.pathSeparator}');

Map<String, Object?> _object(Uint8List bytes, String name) {
  try {
    return _map(jsonDecode(utf8.decode(bytes, allowMalformed: false)), name);
  } catch (_) {
    throw PortabilityException('$name is not valid UTF-8 JSON.');
  }
}

Map<String, Object?> _map(Object? value, String name) {
  if (value is! Map<String, Object?>) {
    throw FormatException('$name must be an object');
  }
  return value;
}

List<Object?> _list(Map<String, Object?> m, String key) {
  final v = m[key];
  if (v is! List<Object?>) throw FormatException('$key must be an array');
  return v;
}

String _string(Map<String, Object?> m, String key) {
  final v = m[key];
  if (v is! String || v.isEmpty) {
    throw FormatException('$key must be a non-empty string');
  }
  return v;
}

String? _nullableString(Map<String, Object?> m, String key) {
  final v = m[key];
  if (v != null && v is! String) {
    throw FormatException('$key must be a string or null');
  }
  return v as String?;
}

int _int(Map<String, Object?> m, String key) {
  final v = m[key];
  if (v is! int) throw FormatException('$key must be an integer');
  return v;
}

int? _nullableInt(Map<String, Object?> m, String key) {
  final v = m[key];
  if (v != null && v is! int) {
    throw FormatException('$key must be an integer or null');
  }
  return v as int?;
}

bool _bool(Map<String, Object?> m, String key) {
  final v = m[key];
  if (v is! bool) throw FormatException('$key must be a boolean');
  return v;
}

String _hash(Map<String, Object?> m, String key) {
  final v = _string(m, key);
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(v)) {
    throw FormatException('$key must be SHA-256');
  }
  return v;
}

LocalDate _date(Map<String, Object?> m, String key) {
  final v = _string(m, key);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) {
    throw FormatException('$key must be a date');
  }
  return LocalDate.parse(v);
}

LocalDate? _nullableDate(Map<String, Object?> m, String key) =>
    m[key] == null ? null : _date(m, key);
DateTime _utc(Map<String, Object?> m, String key) {
  final v = _string(m, key);
  final parsed = DateTime.tryParse(v);
  if (parsed == null || !v.endsWith('Z') || !parsed.isUtc) {
    throw FormatException('$key must be a UTC timestamp');
  }
  return parsed;
}
