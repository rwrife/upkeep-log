import 'dart:async';

import 'package:upkeep_log/application/upkeep_repository.dart';
import 'package:upkeep_log/domain/domain.dart';

enum AttachmentSource { camera, photoLibrary, document }

final class PickedAttachment {
  const PickedAttachment({
    required this.path,
    required this.mediaType,
    this.ownedTemporary = false,
  });

  final String path;
  final String mediaType;

  /// Whether the platform created this file solely for this handoff.
  /// Adapters may delete only files carrying this explicit ownership marker.
  final bool ownedTemporary;
}

abstract interface class AttachmentPicker {
  Future<PickedAttachment?> pick(AttachmentSource source);
}

enum AttachmentHealth { available, missing, corrupt }

final class AttachmentInspection {
  const AttachmentInspection(this.health, this.bytes);
  final AttachmentHealth health;
  final int bytes;
}

final class StoredAttachment {
  const StoredAttachment({required this.sha256, required this.bytes});
  final String sha256;
  final int bytes;
}

/// Port for concrete app-private file operations.
abstract interface class AttachmentStore {
  Future<void> discardSelection(PickedAttachment selected);
  Future<StoredAttachment> copyIntoPrivateStorage(
    PickedAttachment selected,
    String relativePath,
  );
  Future<AttachmentInspection> inspect(
    String relativePath,
    String expectedSha256,
  );
  Future<int> storageUsed(String homeId);
  Future<void> delete(String relativePath);
  Future<int> cleanup(String homeId, Set<String> referencedPaths);
}

final class AttachmentService {
  AttachmentService({
    required this.repository,
    required this.store,
    required this.picker,
    required this.idFactory,
  });

  final UpkeepRepository repository;
  final AttachmentStore store;
  final AttachmentPicker picker;
  final String Function(String kind) idFactory;
  final _AsyncGate _mutationGate = _AsyncGate();

  Future<AttachmentMetadata?> attach({
    required String homeId,
    required String completionId,
    required AttachmentSource source,
    String? caption,
  }) async {
    await _validateCompletionHome(completionId, homeId);
    final PickedAttachment? selected = await picker.pick(source);
    if (selected == null) return null;
    try {
      final String id = _safeComponent(
        idFactory('attachment'),
        'attachment id',
      );
      final String home = _safeComponent(homeId, 'home id');
      final String extension = _safeExtension(selected.path);
      final String relative = 'attachments/$home/$id$extension';
      return await _mutationGate.run(() async {
        await _validateCompletionHome(completionId, homeId);
        final StoredAttachment stored = await store.copyIntoPrivateStorage(
          selected,
          relative,
        );
        final AttachmentMetadata metadata = AttachmentMetadata(
          id: id,
          completionId: completionId,
          relativePath: relative,
          mediaType: selected.mediaType,
          sha256: stored.sha256,
          caption: _optional(caption),
        );
        try {
          await repository.saveAttachment(metadata);
          return metadata;
        } catch (_) {
          await _deleteIfUnreferenced(relative);
          rethrow;
        }
      });
    } catch (error, stackTrace) {
      try {
        await store.discardSelection(selected);
      } catch (_) {
        // Cleanup is best effort and must not mask the publication failure.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<AttachmentInspection> inspect(AttachmentMetadata value) =>
      store.inspect(value.relativePath, value.sha256);

  Future<int> storageUsed(String homeId) async {
    return store.storageUsed(_safeComponent(homeId, 'home id'));
  }

  Future<void> removeMetadata(AttachmentMetadata value) async {
    await _mutationGate.run(() async {
      AttachmentMetadata? persisted;
      for (final AttachmentMetadata candidate
          in await repository.attachments()) {
        if (candidate.id == value.id) {
          persisted = candidate;
          break;
        }
      }
      if (persisted == null) return;
      await repository.deleteAttachment(persisted.id);
      await _deleteIfUnreferenced(persisted.relativePath);
    });
  }

  Future<void> _deleteIfUnreferenced(String relativePath) async {
    final bool referenced = (await repository.attachments()).any(
      (AttachmentMetadata other) => other.relativePath == relativePath,
    );
    if (!referenced) await store.delete(relativePath);
  }

  Future<int> cleanup(String homeId) async => _mutationGate.run(() async {
    final String home = _safeComponent(homeId, 'home id');
    final Set<String> referencedPaths = (await repository.attachments())
        .map((AttachmentMetadata value) => value.relativePath)
        .toSet();
    return store.cleanup(home, referencedPaths);
  });

  Future<void> _validateCompletionHome(
    String completionId,
    String homeId,
  ) async {
    final Completion? completion = await repository.latestCompletion(
      completionId,
    );
    final TaskOccurrence? occurrence = completion == null
        ? null
        : await repository.occurrenceById(completion.occurrenceId);
    final TaskTemplate? task = occurrence == null
        ? null
        : await repository.taskById(occurrence.taskTemplateId);
    if (task == null || task.homeId != homeId) {
      throw StateError('Completion does not belong to the supplied home');
    }
  }
}

final class _AsyncGate {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() action) async {
    final Future<void> previous = _tail;
    final Completer<void> released = Completer<void>();
    _tail = released.future;
    await previous;
    try {
      return await action();
    } finally {
      released.complete();
    }
  }
}

String _safeComponent(String value, String name) {
  if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(value) ||
      value == '.' ||
      value == '..') {
    throw StateError('Unsafe $name');
  }
  return value;
}

String _safeExtension(String path) {
  final String name = path.split(RegExp(r'[/\\]')).last;
  final int dot = name.lastIndexOf('.');
  if (dot <= 0 || name.length - dot > 10) return '';
  final String value = name.substring(dot).toLowerCase();
  return RegExp(r'^\.[a-z0-9]+$').hasMatch(value) ? value : '';
}

String? _optional(String? value) {
  final String? result = value?.trim();
  return result == null || result.isEmpty ? null : result;
}
