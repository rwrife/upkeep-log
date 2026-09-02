import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upkeep_log/adapters/database/drift_upkeep_repository.dart';
import 'package:upkeep_log/adapters/database/upkeep_database.dart'
    hide Completion, TaskOccurrence, TaskTemplate;
import 'package:upkeep_log/adapters/private_attachment_store.dart';
import 'package:upkeep_log/application/attachment_service.dart';
import 'package:upkeep_log/domain/domain.dart';

final class _Picker implements AttachmentPicker {
  _Picker(this.value);
  PickedAttachment? value;
  var calls = 0;
  @override
  Future<PickedAttachment?> pick(AttachmentSource source) async {
    calls++;
    return value;
  }
}

final class _InvalidatingPicker implements AttachmentPicker {
  _InvalidatingPicker(this.value, this.invalidate);

  final PickedAttachment value;
  final Future<void> Function() invalidate;

  @override
  Future<PickedAttachment?> pick(AttachmentSource source) async {
    await invalidate();
    return value;
  }
}

final class _PausingCopyStore implements AttachmentStore {
  _PausingCopyStore(this.delegate);

  final AttachmentStore delegate;
  final Completer<void> copied = Completer<void>();
  final Completer<void> resumeCopy = Completer<void>();
  var cleanupCalls = 0;

  @override
  Future<void> discardSelection(PickedAttachment selected) =>
      delegate.discardSelection(selected);

  @override
  Future<StoredAttachment> copyIntoPrivateStorage(
    PickedAttachment selected,
    String relativePath,
  ) async {
    final StoredAttachment result = await delegate.copyIntoPrivateStorage(
      selected,
      relativePath,
    );
    copied.complete();
    await resumeCopy.future;
    return result;
  }

  @override
  Future<int> cleanup(String homeId, Set<String> referencedPaths) async {
    cleanupCalls++;
    return delegate.cleanup(homeId, referencedPaths);
  }

  @override
  Future<void> delete(String relativePath) => delegate.delete(relativePath);

  @override
  Future<AttachmentInspection> inspect(
    String relativePath,
    String expectedSha256,
  ) => delegate.inspect(relativePath, expectedSha256);

  @override
  Future<int> storageUsed(String homeId) => delegate.storageUsed(homeId);
}

void main() {
  late Directory root;
  late UpkeepDatabase database;
  late DriftUpkeepRepository repository;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('upkeep-attachments-');
    database = UpkeepDatabase(NativeDatabase.memory());
    repository = DriftUpkeepRepository(database);
    await repository.saveHome(HomeProfile(id: 'home', name: 'Home'));
    await repository.saveTask(
      TaskTemplate(
        id: 'task',
        homeId: 'home',
        name: 'Service',
        startDate: LocalDate(2026, 1, 1),
        recurrence: const OneTimeRecurrence(),
      ),
    );
    await repository.saveOccurrence(
      TaskOccurrence(
        id: 'occurrence',
        taskTemplateId: 'task',
        scheduledDate: LocalDate(2026, 1, 1),
      ),
    );
    await repository.saveCompletion(
      Completion(
        id: 'completion',
        occurrenceId: 'occurrence',
        scheduledDate: LocalDate(2026, 1, 1),
        actualDate: LocalDate(2026, 1, 1),
        revision: 1,
        revisedAtUtc: DateTime.utc(2026),
      ),
    );
  });

  tearDown(() async {
    await database.close();
    await root.delete(recursive: true);
  });

  test(
    'copy, checksum, corruption, restart metadata, and removal lifecycle',
    () async {
      final File external = File('${root.path}/outside receipt.pdf');
      await external.writeAsString('private receipt');
      final _Picker picker = _Picker(
        PickedAttachment(path: external.path, mediaType: 'application/pdf'),
      );
      final AttachmentService service = AttachmentService(
        repository: repository,
        store: PrivateAttachmentStore(root),
        picker: picker,
        idFactory: (_) => 'attachment',
      );

      final AttachmentMetadata value = (await service.attach(
        homeId: 'home',
        completionId: 'completion',
        source: AttachmentSource.document,
        caption: 'Receipt',
      ))!;
      expect(value.relativePath, 'attachments/home/attachment.pdf');
      expect(value.relativePath, isNot(contains(external.path)));
      expect((await service.inspect(value)).health, AttachmentHealth.available);
      expect(await service.storageUsed('home'), 15);
      expect((await repository.attachments()).single.sha256, value.sha256);

      await File('${root.path}/${value.relativePath}')
          .writeAsString('tampered');
      expect((await service.inspect(value)).health, AttachmentHealth.corrupt);
      await service.removeMetadata(value);
      expect(await repository.attachments(), isEmpty);
      expect(
        await File('${root.path}/${value.relativePath}').exists(),
        isFalse,
      );
    },
  );

  test(
    'cancel or permission denial represented as cancel writes nothing',
    () async {
      final _Picker picker = _Picker(null);
      final AttachmentService service = AttachmentService(
        repository: repository,
        store: PrivateAttachmentStore(root),
        picker: picker,
        idFactory: (_) => 'unused',
      );
      expect(
        await service.attach(
          homeId: 'home',
          completionId: 'completion',
          source: AttachmentSource.camera,
        ),
        isNull,
      );
      expect(picker.calls, 1);
      expect(await repository.attachments(), isEmpty);
    },
  );

  test(
    'simulated low storage removes partial private copy and metadata',
    () async {
      final File selected = File('${root.path}/low-storage-selection.tmp');
      await selected.writeAsBytes(<int>[1, 2, 3, 4]);
      final AttachmentService service = AttachmentService(
        repository: repository,
        store: PrivateAttachmentStore(
          root,
          contentWriter: (File source, RandomAccessFile destination) async {
            await destination.writeFrom(<int>[1, 2]);
            throw FileSystemException(
              'No space left on device',
              destination.path,
              const OSError('No space left on device', 28),
            );
          },
        ),
        picker: _Picker(
          PickedAttachment(
            path: selected.path,
            mediaType: 'application/octet-stream',
            ownedTemporary: true,
          ),
        ),
        idFactory: (_) => 'low-storage',
      );

      await expectLater(
        service.attach(
          homeId: 'home',
          completionId: 'completion',
          source: AttachmentSource.document,
        ),
        throwsA(
          isA<FileSystemException>().having(
            (FileSystemException error) => error.osError?.errorCode,
            'errno',
            28,
          ),
        ),
      );

      expect(await selected.exists(), isFalse);
      expect(await repository.attachments(), isEmpty);
      expect(
        await File('${root.path}/attachments/home/low-storage.tmp').exists(),
        isFalse,
      );
    },
  );

  test('cleanup removes only unreferenced files', () async {
    final Directory directory = Directory('${root.path}/attachments/home');
    await directory.create(recursive: true);
    final File orphan = File('${directory.path}/orphan.bin');
    await orphan.writeAsBytes(<int>[1, 2, 3]);
    final File referenced = File('${directory.path}/kept.bin');
    await referenced.writeAsBytes(<int>[4]);
    await repository.saveAttachment(
      AttachmentMetadata(
        id: 'kept',
        completionId: 'completion',
        relativePath: 'attachments/home/kept.bin',
        mediaType: 'application/octet-stream',
        sha256: 'a' * 64,
      ),
    );
    final AttachmentService service = AttachmentService(
      repository: repository,
      store: PrivateAttachmentStore(root),
      picker: _Picker(null),
      idFactory: (_) => 'unused',
    );
    expect(await service.storageUsed('home'), 4);
    expect(await service.cleanup('home'), 3);
    expect(await orphan.exists(), isFalse);
    expect(await referenced.exists(), isTrue);
    expect(await service.storageUsed('home'), 1);
  });

  test('cleanup waits for an in-flight attachment to be published', () async {
    final File source = File('${root.path}/race.bin');
    await source.writeAsBytes(<int>[1, 2, 3, 4]);
    final _PausingCopyStore store = _PausingCopyStore(
      PrivateAttachmentStore(root),
    );
    final AttachmentService service = AttachmentService(
      repository: repository,
      store: store,
      picker: _Picker(
        PickedAttachment(
          path: source.path,
          mediaType: 'application/octet-stream',
        ),
      ),
      idFactory: (_) => 'racing',
    );

    final Future<AttachmentMetadata?> attaching = service.attach(
      homeId: 'home',
      completionId: 'completion',
      source: AttachmentSource.document,
    );
    await store.copied.future;
    final File privateFile = File('${root.path}/attachments/home/racing.bin');
    expect(await privateFile.exists(), isTrue);

    final Future<int> cleaning = service.cleanup('home');
    await Future<void>.delayed(Duration.zero);
    expect(store.cleanupCalls, 0);
    expect(await privateFile.exists(), isTrue);

    store.resumeCopy.complete();
    final AttachmentMetadata metadata = (await attaching)!;
    expect(await cleaning, 0);
    expect(store.cleanupCalls, 1);
    expect(
      (await service.inspect(metadata)).health,
      AttachmentHealth.available,
    );
  });

  test(
    'owned temporary selections are deleted after success and failure',
    () async {
      final File successful = File('${root.path}/owned-success.tmp');
      await successful.writeAsString('owned');
      final AttachmentService success = AttachmentService(
        repository: repository,
        store: PrivateAttachmentStore(root),
        picker: _Picker(
          PickedAttachment(
            path: successful.path,
            mediaType: 'text/plain',
            ownedTemporary: true,
          ),
        ),
        idFactory: (_) => 'owned',
      );
      await success.attach(
        homeId: 'home',
        completionId: 'completion',
        source: AttachmentSource.document,
      );
      expect(await successful.exists(), isFalse);

      final File failed = File('${root.path}/owned-failure.tmp');
      await failed.writeAsString('owned');
      final Directory blockedDestination = Directory(
        '${root.path}/attachments/home/failure.tmp',
      );
      await blockedDestination.create(recursive: true);
      final AttachmentService failure = AttachmentService(
        repository: repository,
        store: PrivateAttachmentStore(root),
        picker: _Picker(
          PickedAttachment(
            path: failed.path,
            mediaType: 'text/plain',
            ownedTemporary: true,
          ),
        ),
        idFactory: (_) => 'failure',
      );
      await expectLater(
        failure.attach(
          homeId: 'home',
          completionId: 'completion',
          source: AttachmentSource.document,
        ),
        throwsA(anything),
      );
      expect(await failed.exists(), isFalse);

      await blockedDestination.delete();

      final File external = File('${root.path}/external.tmp');
      await external.writeAsString('external');
      final AttachmentService externalService = AttachmentService(
        repository: repository,
        store: PrivateAttachmentStore(root),
        picker: _Picker(
          PickedAttachment(path: external.path, mediaType: 'text/plain'),
        ),
        idFactory: (_) => 'external',
      );
      await externalService.attach(
        homeId: 'home',
        completionId: 'completion',
        source: AttachmentSource.document,
      );
      expect(await external.exists(), isTrue);
    },
  );

  test(
    'ownership invalidation after picker return discards owned temporary',
    () async {
      final File selected = File('${root.path}/invalidated-selection.tmp');
      await selected.writeAsString('platform cache');
      final AttachmentService service = AttachmentService(
        repository: repository,
        store: PrivateAttachmentStore(root),
        picker: _InvalidatingPicker(
          PickedAttachment(
            path: selected.path,
            mediaType: 'application/octet-stream',
            ownedTemporary: true,
          ),
          () => database.customStatement(
            "DELETE FROM task_templates WHERE id = 'task'",
          ),
        ),
        idFactory: (_) => 'must-not-publish',
      );

      await expectLater(
        service.attach(
          homeId: 'home',
          completionId: 'completion',
          source: AttachmentSource.document,
        ),
        throwsStateError,
      );

      expect(await selected.exists(), isFalse);
      expect(await repository.attachments(), isEmpty);
      expect(
        await File('${root.path}/attachments/home/must-not-publish.tmp')
            .exists(),
        isFalse,
      );
    },
  );

  test('private store rejects traversal and destination symlinks', () async {
    final PrivateAttachmentStore store = PrivateAttachmentStore(root);
    await expectLater(store.inspect('../outside', 'a' * 64), throwsStateError);

    final File outside = File('${root.path}/outside-target');
    await outside.writeAsString('do not touch');
    final Directory privateDirectory = Directory(
      '${root.path}/attachments/home',
    );
    await privateDirectory.create(recursive: true);
    final Link link = Link('${privateDirectory.path}/linked');
    await link.create(outside.path);

    await expectLater(
      store.delete('attachments/home/linked'),
      throwsStateError,
    );
    expect(await outside.readAsString(), 'do not touch');
  });

  test('duplicate id failure preserves original bytes and metadata', () async {
    final Directory directory = Directory('${root.path}/attachments/home');
    await directory.create(recursive: true);
    final File original = File('${directory.path}/duplicate.bin');
    final List<int> originalBytes = <int>[1, 3, 3, 7];
    await original.writeAsBytes(originalBytes);
    final AttachmentMetadata originalMetadata = AttachmentMetadata(
      id: 'duplicate',
      completionId: 'completion',
      relativePath: 'attachments/home/duplicate.bin',
      mediaType: 'application/octet-stream',
      sha256: 'a' * 64,
      caption: 'original',
    );
    await repository.saveAttachment(originalMetadata);
    final File replacement = File('${root.path}/replacement.txt');
    await replacement.writeAsBytes(<int>[9, 9, 9]);
    final AttachmentService service = AttachmentService(
      repository: repository,
      store: PrivateAttachmentStore(root),
      picker: _Picker(
        PickedAttachment(
          path: replacement.path,
          mediaType: 'application/octet-stream',
        ),
      ),
      idFactory: (_) => 'duplicate',
    );

    await expectLater(
      service.attach(
        homeId: 'home',
        completionId: 'completion',
        source: AttachmentSource.document,
      ),
      throwsA(anything),
    );

    expect(await original.readAsBytes(), originalBytes);
    final AttachmentMetadata surviving =
        (await repository.attachments()).single;
    expect(surviving.id, originalMetadata.id);
    expect(surviving.completionId, originalMetadata.completionId);
    expect(surviving.relativePath, originalMetadata.relativePath);
    expect(surviving.mediaType, originalMetadata.mediaType);
    expect(surviving.sha256, originalMetadata.sha256);
    expect(surviving.caption, originalMetadata.caption);
    expect(await File('${directory.path}/duplicate.txt').exists(), isFalse);
  });

  test('private store never overwrites a colliding destination', () async {
    final Directory directory = Directory('${root.path}/attachments/home');
    await directory.create(recursive: true);
    final File destination = File('${directory.path}/same.bin');
    await destination.writeAsBytes(<int>[1, 2, 3]);
    final File source = File('${root.path}/new.bin');
    await source.writeAsBytes(<int>[9, 8, 7]);

    await expectLater(
      PrivateAttachmentStore(root).copyIntoPrivateStorage(
        PickedAttachment(
          path: source.path,
          mediaType: 'application/octet-stream',
        ),
        'attachments/home/same.bin',
      ),
      throwsA(isA<FileSystemException>()),
    );

    expect(await destination.readAsBytes(), <int>[1, 2, 3]);
  });

  test(
    'metadata removal uses the persisted path rather than caller data',
    () async {
      final Directory directory = Directory('${root.path}/attachments/home');
      await directory.create(recursive: true);
      final File persistedFile = File('${directory.path}/persisted.bin');
      final File unrelatedFile = File('${directory.path}/unrelated.bin');
      await persistedFile.writeAsBytes(<int>[1]);
      await unrelatedFile.writeAsBytes(<int>[2]);
      await repository.saveAttachment(
        AttachmentMetadata(
          id: 'persisted',
          completionId: 'completion',
          relativePath: 'attachments/home/persisted.bin',
          mediaType: 'application/octet-stream',
          sha256: 'a' * 64,
        ),
      );
      final AttachmentService service = AttachmentService(
        repository: repository,
        store: PrivateAttachmentStore(root),
        picker: _Picker(null),
        idFactory: (_) => 'unused',
      );

      await service.removeMetadata(
        AttachmentMetadata(
          id: 'persisted',
          completionId: 'completion',
          relativePath: 'attachments/home/unrelated.bin',
          mediaType: 'application/octet-stream',
          sha256: 'b' * 64,
        ),
      );

      expect(await repository.attachments(), isEmpty);
      expect(await persistedFile.exists(), isFalse);
      expect(await unrelatedFile.readAsBytes(), <int>[2]);
    },
  );

  test(
    'attachment rejects mismatched or missing completion ownership',
    () async {
      await repository.saveHome(HomeProfile(id: 'other', name: 'Other'));
      final _Picker picker = _Picker(null);
      final AttachmentService service = AttachmentService(
        repository: repository,
        store: PrivateAttachmentStore(root),
        picker: picker,
        idFactory: (_) => 'unused',
      );

      await expectLater(
        service.attach(
          homeId: 'other',
          completionId: 'completion',
          source: AttachmentSource.document,
        ),
        throwsStateError,
      );
      await expectLater(
        service.attach(
          homeId: 'home',
          completionId: 'missing',
          source: AttachmentSource.document,
        ),
        throwsStateError,
      );
      expect(picker.calls, 0);
      expect(await repository.attachments(), isEmpty);
    },
  );
}
