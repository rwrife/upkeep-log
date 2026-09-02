import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:upkeep_log/application/attachment_service.dart';

typedef AttachmentContentWriter = Future<void> Function(
  File source,
  RandomAccessFile destination,
);

final class PrivateAttachmentStore implements AttachmentStore {
  PrivateAttachmentStore(
    Directory root, {
    AttachmentContentWriter? contentWriter,
  }) : _root = root.absolute,
       _contentWriter = contentWriter ?? _writeContents;

  final Directory _root;
  final AttachmentContentWriter _contentWriter;

  @override
  Future<void> discardSelection(PickedAttachment selected) async {
    if (!selected.ownedTemporary) return;
    final File source = File(selected.path);
    try {
      if (await source.exists()) await source.delete();
    } on FileSystemException {
      // Platform-owned cache cleanup is best effort.
    }
  }

  @override
  Future<StoredAttachment> copyIntoPrivateStorage(
    PickedAttachment selected,
    String relativePath,
  ) async {
    final File source = File(selected.path);
    File? destination;
    var createdDestination = false;
    try {
      destination = await _resolve(relativePath, createParent: true);
      if (!await source.exists()) {
        throw StateError('Selected file is unavailable');
      }
      await destination.create(exclusive: true);
      createdDestination = true;
      final RandomAccessFile output = await destination.open(
        mode: FileMode.writeOnly,
      );
      try {
        await _contentWriter(source, output);
      } finally {
        await output.close();
      }
      final String checksum = (await sha256.bind(destination.openRead()).first)
          .toString();
      final StoredAttachment stored = StoredAttachment(
        sha256: checksum,
        bytes: await destination.length(),
      );
      await discardSelection(selected);
      return stored;
    } catch (error, stackTrace) {
      if (createdDestination &&
          destination != null &&
          await destination.exists()) {
        try {
          await destination.delete();
        } on FileSystemException {
          // Preserve the copy failure; explicit cleanup can remove the orphan.
        }
      }
      await discardSelection(selected);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  static Future<void> _writeContents(
    File source,
    RandomAccessFile destination,
  ) async {
    await for (final List<int> chunk in source.openRead()) {
      await destination.writeFrom(chunk);
    }
  }

  @override
  Future<AttachmentInspection> inspect(
    String relativePath,
    String expectedSha256,
  ) async {
    final File file = await _resolve(relativePath);
    if (!await file.exists()) {
      return const AttachmentInspection(AttachmentHealth.missing, 0);
    }
    final int bytes = await file.length();
    final String checksum = (await sha256.bind(file.openRead()).first)
        .toString();
    return AttachmentInspection(
      checksum == expectedSha256
          ? AttachmentHealth.available
          : AttachmentHealth.corrupt,
      bytes,
    );
  }

  @override
  Future<int> storageUsed(String homeId) async {
    final Directory directory = Directory(
      (await _resolve('attachments/$homeId/.keep')).parent.path,
    );
    if (!await directory.exists()) return 0;
    var total = 0;
    await for (final FileSystemEntity entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  @override
  Future<void> delete(String relativePath) async {
    final File file = await _resolve(relativePath);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<int> cleanup(String homeId, Set<String> referencedPaths) async {
    final String relativeDirectory = 'attachments/$homeId';
    final Directory directory = Directory(
      (await _resolve('$relativeDirectory/.keep')).parent.path,
    );
    if (!await directory.exists()) return 0;
    var removed = 0;
    await for (final FileSystemEntity entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final String relative = _relative(entity.absolute.path);
      if (!referencedPaths.contains(relative)) {
        removed += await entity.length();
        await entity.delete();
      }
    }
    return removed;
  }

  Future<File> _resolve(
    String relativePath, {
    bool createParent = false,
  }) async {
    _validateRelative(relativePath);
    await _root.create(recursive: true);
    final String canonicalRoot = await _root.resolveSymbolicLinks();
    final File result = File('${_root.path}/$relativePath').absolute;
    if (createParent) await result.parent.create(recursive: true);
    if (await FileSystemEntity.type(result.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw StateError('Attachment path may not be a symbolic link');
    }
    final Directory parent = result.parent;
    if (await parent.exists()) {
      final String canonicalParent = await parent.resolveSymbolicLinks();
      if (!_within(canonicalRoot, canonicalParent)) {
        throw StateError('Attachment path escaped private storage');
      }
    }
    return result;
  }

  String _relative(String absolutePath) {
    final String prefix = '${_root.path}${Platform.pathSeparator}';
    if (!absolutePath.startsWith(prefix)) {
      throw StateError('Attachment path escaped private storage');
    }
    return absolutePath
        .substring(prefix.length)
        .replaceAll(Platform.pathSeparator, '/');
  }

  static bool _within(String root, String value) =>
      value == root || value.startsWith('$root${Platform.pathSeparator}');

  static void _validateRelative(String value) {
    if (value.isEmpty ||
        value.startsWith('/') ||
        value.startsWith('\\') ||
        RegExp(r'^[A-Za-z]:[/\\]').hasMatch(value) ||
        value
            .split(RegExp(r'[/\\]'))
            .any(
              (String part) => part.isEmpty || part == '.' || part == '..',
            )) {
      throw StateError('Attachment path escaped private storage');
    }
  }
}
