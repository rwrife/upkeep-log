import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upkeep_log/adapters/data_portability_service.dart';
import 'package:upkeep_log/adapters/database/drift_upkeep_repository.dart';
import 'package:upkeep_log/adapters/database/upkeep_database.dart'
    hide Asset, Completion, Room, TaskOccurrence, TaskTemplate;
import 'package:upkeep_log/application/application_mutation_gate.dart';
import 'package:upkeep_log/application/data_portability.dart';
import 'package:upkeep_log/domain/domain.dart';

void main() {
  late Directory temp;
  late UpkeepDatabase sourceDb;
  late DriftUpkeepRepository source;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('upkeep-portability-');
    sourceDb = UpkeepDatabase(NativeDatabase.memory());
    source = DriftUpkeepRepository(sourceDb);
    await _seed(source, temp);
  });

  tearDown(() async {
    await sourceDb.close();
    await temp.delete(recursive: true);
  });

  test(
    'backup restores every revision and attachment into a fresh database',
    () async {
      final service = DataPortabilityService(
        repository: source,
        privateRoot: temp,
        nowUtc: () => DateTime.utc(2026, 8, 31),
      );
      final incoming = File('${temp.path}/incoming.zip')
        ..writeAsBytesSync(await service.createBackup());
      final targetRoot = await Directory('${temp.path}/target').create();
      final targetDb = UpkeepDatabase(NativeDatabase.memory());
      final target = DriftUpkeepRepository(targetDb);
      final targetService = DataPortabilityService(
        repository: target,
        privateRoot: targetRoot,
        nowUtc: () => DateTime.utc(2026, 9, 1),
      );
      final report = await targetService.restore(
        incoming,
        preRestoreBackup: File('${temp.path}/before.zip'),
      );

      final restored = await target.portableData();
      expect(report.homeCount, 1);
      expect(restored.completionRevisions.map((e) => e.revision), <int>[1, 2]);
      expect(restored.tasks.single.reminder!.timeZoneId, 'Europe/London');
      expect(restored.occurrences.single.snoozedUntil.toString(), '2026-02-02');
      expect(
        File('${targetRoot.path}/attachments/home/a.txt').readAsStringSync(),
        'photo bytes',
      );
      await targetDb.close();
    },
  );

  test('restore rejects completion and attachment ownership corruption before moving live data', () async {
    final DataPortabilityService service = DataPortabilityService(
      repository: source,
      privateRoot: temp,
    );
    final Uint8List good = await service.createBackup();
    final List<void Function(Map<String, Object?>)> attacks =
        <void Function(Map<String, Object?>)>[
          (Map<String, Object?> data) {
            final List<Object?> revisions =
                data['completionRevisions']! as List<Object?>;
            final Map<String, Object?> duplicate = Map<String, Object?>.from(
              revisions.first! as Map,
            );
            duplicate['id'] = 'second-completion';
            revisions.add(duplicate);
          },
          (Map<String, Object?> data) {
            final List<Object?> revisions =
                data['completionRevisions']! as List<Object?>;
            for (final Object? raw in revisions) {
              (raw! as Map<String, Object?>)['scheduledDate'] = '2026-02-02';
            }
          },
          (Map<String, Object?> data) {
            final List<Object?> attachments =
                data['attachments']! as List<Object?>;
            (attachments.single! as Map<String, Object?>)['relativePath'] =
                'attachments/other/a.txt';
          },
        ];
    for (var index = 0; index < attacks.length; index++) {
      final File incoming = File('${temp.path}/adversarial-$index.zip')
        ..writeAsBytesSync(_rewriteData(good, attacks[index]));
      await expectLater(
        service.restore(
          incoming,
          preRestoreBackup: File('${temp.path}/adversarial-pre-$index.zip'),
        ),
        throwsA(isA<PortabilityException>()),
      );
      expect((await source.homes()).single.name, 'House');
      expect(
        File('${temp.path}/attachments/home/a.txt').readAsStringSync(),
        'photo bytes',
      );
    }
  });

  test('delete rolls all staged files back when a later move fails', () async {
    final File second = File('${temp.path}/attachments/home/b.txt')
      ..writeAsStringSync('other bytes');
    await source.saveAttachment(
      AttachmentMetadata(
        id: 'attachment-2',
        completionId: 'completion',
        relativePath: 'attachments/home/b.txt',
        mediaType: 'text/plain',
        sha256: sha256.convert(second.readAsBytesSync()).toString(),
      ),
    );
    var moves = 0;
    final DataPortabilityService service = DataPortabilityService(
      repository: source,
      privateRoot: temp,
      movePath: (String from, String to) async {
        moves++;
        if (moves == 2) {
          throw const FileSystemException('forced second move failure');
        }
        await File(from).rename(to);
      },
    );
    await expectLater(
      service.deleteHomeData('home'),
      throwsA(isA<FileSystemException>()),
    );
    expect((await source.homes()).single.id, 'home');
    expect(
      File('${temp.path}/attachments/home/a.txt').readAsStringSync(),
      'photo bytes',
    );
    expect(second.readAsStringSync(), 'other bytes');
  });

  test('declared entry and total limits reject restore while export bounds sources', () async {
    final Uint8List good = await DataPortabilityService(
      repository: source,
      privateRoot: temp,
    ).createBackup();
    final Archive decoded = ZipDecoder().decodeBytes(good);
    final int largest = decoded.map((entry) => entry.size).reduce(max);
    final int expanded = decoded.fold(0, (sum, entry) => sum + entry.size);
    final Archive oversizedEntryArchive = ZipDecoder().decodeBytes(good)
      ..addFile(
        ArchiveFile('oversized.bin', largest + 1, Uint8List(largest + 1)),
      );
    final File oversizedEntry = File('${temp.path}/entry-limited.zip')
      ..writeAsBytesSync(ZipEncoder().encodeBytes(oversizedEntryArchive));
    final DataPortabilityService entryLimited = DataPortabilityService(
      repository: source,
      privateRoot: temp,
      limits: BackupLimits(maxEntryBytes: largest),
    );
    await expectLater(
      entryLimited.restore(
        oversizedEntry,
        preRestoreBackup: File('${temp.path}/entry-pre.zip'),
      ),
      throwsA(isA<PortabilityException>()),
    );
    final Archive oversizedTotalArchive = ZipDecoder().decodeBytes(good)
      ..addFile(ArchiveFile('extra.bin', 32, Uint8List(32)));
    final File oversizedTotal = File('${temp.path}/total-limited.zip')
      ..writeAsBytesSync(ZipEncoder().encodeBytes(oversizedTotalArchive));
    final DataPortabilityService totalLimited = DataPortabilityService(
      repository: source,
      privateRoot: temp,
      limits: BackupLimits(
        maxEntryBytes: largest + 100,
        maxTotalBytes: expanded,
      ),
    );
    await expectLater(
      totalLimited.restore(
        oversizedTotal,
        preRestoreBackup: File('${temp.path}/total-pre.zip'),
      ),
      throwsA(isA<PortabilityException>()),
    );
    final File inconsistent = File('${temp.path}/inconsistent-size.zip')
      ..writeAsBytesSync(_understateFirstCentralEntry(good));
    await expectLater(
      DataPortabilityService(repository: source, privateRoot: temp).restore(
        inconsistent,
        preRestoreBackup: File('${temp.path}/inconsistent-pre.zip'),
      ),
      throwsA(isA<PortabilityException>()),
    );
    final DataPortabilityService exportLimited = DataPortabilityService(
      repository: source,
      privateRoot: temp,
      limits: const BackupLimits(maxEntryBytes: 5),
    );
    await expectLater(
      exportLimited.createBackup(),
      throwsA(isA<PortabilityException>()),
    );
    expect(
      File('${temp.path}/attachments/home/a.txt').readAsStringSync(),
      'photo bytes',
    );
  });

  test('shared gate serializes snapshots and fixed clocks still create unique stages', () async {
    final ApplicationMutationGate gate = ApplicationMutationGate();
    final Completer<void> entered = Completer<void>();
    final Completer<void> release = Completer<void>();
    unawaited(
      gate.run(() async {
        entered.complete();
        await release.future;
      }),
    );
    await entered.future;
    final DataPortabilityService service = DataPortabilityService(
      repository: source,
      privateRoot: temp,
      mutationGate: gate,
      nowUtc: () => DateTime.utc(2026),
    );
    var finished = false;
    final Future<Uint8List> backup = service.createBackup();
    unawaited(backup.then((_) => finished = true));
    await Future<void>.delayed(Duration.zero);
    expect(finished, isFalse);
    release.complete();
    await backup;
    await service.deleteHomeData('missing');
    await service.deleteHomeData('missing');
    expect(
      temp.listSync().where((e) => e.path.contains('.delete-stage-')),
      isEmpty,
    );
  });

  test('committed delete ignores staging cleanup failure and storage summary is numeric', () async {
    final DataPortabilityService measured = DataPortabilityService(
      repository: source,
      privateRoot: temp,
    );
    final LocalStorageSummary summary = await measured.storageSummary();
    expect(summary.attachmentBytesByHome, <String, int>{'home': 11});
    expect(summary.totalBytes, greaterThanOrEqualTo(11));

    final DataPortabilityService service = DataPortabilityService(
      repository: source,
      privateRoot: temp,
      deleteTree: (Directory _) async {
        throw const FileSystemException('forced cleanup failure');
      },
    );
    await service.deleteHomeData('home');
    expect(await source.homes(), isEmpty);
    expect(File('${temp.path}/attachments/home/a.txt').existsSync(), isFalse);
  });

  test('destructive operations reject symlink attachment paths before database deletion', () async {
    if (Platform.isWindows) return;
    final File outside = File('${temp.path}/outside.txt')
      ..writeAsStringSync('outside');
    final File live = File('${temp.path}/attachments/home/a.txt');
    await live.delete();
    await Link(live.path).create(outside.path);
    final DataPortabilityService service = DataPortabilityService(
      repository: source,
      privateRoot: temp,
    );
    await expectLater(
      service.deleteHomeData('home'),
      throwsA(isA<PortabilityException>()),
    );
    expect((await source.homes()).single.id, 'home');
    expect(outside.readAsStringSync(), 'outside');
  });

  test(
    'CSV is deterministic RFC 4180 UTF-8 with dates and correction metadata',
    () async {
      final csv = utf8.decode(
        await DataPortabilityService(
          repository: source,
          privateRoot: temp,
        ).exportCsv(),
      );
      expect(csv.endsWith('\r\n'), isTrue);
      expect(csv, contains('scheduled_date'));
      expect(
        csv,
        contains('cost_minor_units,cost_currency,revision,revised_at_utc'),
      );
      expect(csv, contains('"line 1, ""quoted""\r\nline 2"'));
      expect(RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(csv), isTrue);
    },
  );

  test(
    'corruption, traversal, future schema, and limits preserve current data',
    () async {
      final service = DataPortabilityService(
        repository: source,
        privateRoot: temp,
        limits: const BackupLimits(maxEntryBytes: 1024 * 1024),
      );
      final good = await service.createBackup();
      final cases = <List<int>>[
        good.sublist(0, good.length - 8),
        _rewrite(
          good,
          (archive) => archive.addFile(ArchiveFile.string('../escape', 'bad')),
        ),
        _futureVersion(good),
      ];
      for (var i = 0; i < cases.length; i++) {
        final incoming = File('${temp.path}/bad-$i.zip')
          ..writeAsBytesSync(cases[i]);
        await expectLater(
          service.restore(
            incoming,
            preRestoreBackup: File('${temp.path}/pre-$i.zip'),
          ),
          throwsA(isA<Object>()),
        );
        expect((await source.homes()).single.id, 'home');
        expect(
          File('${temp.path}/attachments/home/a.txt').readAsStringSync(),
          'photo bytes',
        );
      }
    },
  );

  test('pre-restore storage failure preserves database and files', () async {
    final service = DataPortabilityService(
      repository: source,
      privateRoot: temp,
    );
    final incoming = File('${temp.path}/valid.zip')
      ..writeAsBytesSync(await service.createBackup());
    final blocker = File('${temp.path}/not-a-directory')
      ..writeAsStringSync('occupied');
    await expectLater(
      service.restore(
        incoming,
        preRestoreBackup: File('${blocker.path}/backup.zip'),
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect((await source.homes()).single.id, 'home');
    expect(
      File('${temp.path}/attachments/home/a.txt').readAsStringSync(),
      'photo bytes',
    );
  });

  test(
    'stale offered pre-restore backup is rejected before live changes',
    () async {
      final service = DataPortabilityService(
        repository: source,
        privateRoot: temp,
      );
      final File offered = File('${temp.path}/offered-before.zip')
        ..writeAsBytesSync(await service.createBackup());
      final File incoming = File('${temp.path}/stale-incoming.zip')
        ..writeAsBytesSync(await service.createBackup());
      await source.saveHome(HomeProfile(id: 'new-home', name: 'New home'));

      await expectLater(
        service.restore(incoming, preRestoreBackup: offered),
        throwsA(
          isA<PortabilityException>().having(
            (error) => error.message,
            'message',
            contains('stale'),
          ),
        ),
      );
      expect((await source.homes()).map((home) => home.id), <String>[
        'home',
        'new-home',
      ]);
      expect(
        File('${temp.path}/attachments/home/a.txt').readAsStringSync(),
        'photo bytes',
      );
    },
  );

  for (final boundary in RestoreCrashBoundary.values) {
    test('recovers a simulated crash at ${boundary.name}', () async {
      final File incoming = File('${temp.path}/crash-${boundary.name}.zip')
        ..writeAsBytesSync(
          await DataPortabilityService(
            repository: source,
            privateRoot: temp,
          ).createBackup(),
        );
      final File offered =
          File('${temp.path}/crash-before-${boundary.name}.zip')
            ..writeAsBytesSync(
              await DataPortabilityService(
                repository: source,
                privateRoot: temp,
              ).createBackup(),
            );
      final service = DataPortabilityService(
        repository: source,
        privateRoot: temp,
        crashBoundary: (value) async {
          if (value == boundary) throw const RestoreCrashSimulation();
        },
      );

      await expectLater(
        service.restore(incoming, preRestoreBackup: offered),
        throwsA(isA<RestoreCrashSimulation>()),
      );
      await DataPortabilityService(
        repository: source,
        privateRoot: temp,
      ).recoverInterruptedRestore();

      expect((await source.homes()).single.id, 'home');
      expect(
        File('${temp.path}/attachments/home/a.txt').readAsStringSync(),
        'photo bytes',
      );
      expect(File('${temp.path}/.restore-journal.json').existsSync(), isFalse);
      expect(
        temp.listSync().where(
          (entity) => entity.path.contains('.restore-stage-'),
        ),
        isEmpty,
      );
    });
  }

  test(
    'database import failure rolls back structured data and live files',
    () async {
      final service = DataPortabilityService(
        repository: source,
        privateRoot: temp,
      );
      final incoming = File('${temp.path}/transaction-failure.zip')
        ..writeAsBytesSync(await service.createBackup());
      await sourceDb.customStatement(
        "CREATE TRIGGER force_import_failure BEFORE INSERT ON homes BEGIN SELECT RAISE(ABORT, 'forced'); END",
      );
      await expectLater(
        service.restore(
          incoming,
          preRestoreBackup: File('${temp.path}/transaction-pre.zip'),
        ),
        throwsA(isA<Object>()),
      );
      expect((await source.homes()).single.name, 'House');
      expect(
        File('${temp.path}/attachments/home/a.txt').readAsStringSync(),
        'photo bytes',
      );
    },
  );

  test(
    'deliberate per-home deletion and full reset remove private data',
    () async {
      final service = DataPortabilityService(
        repository: source,
        privateRoot: temp,
      );
      await source.saveHome(HomeProfile(id: 'other', name: 'Other'));
      await service.deleteHomeData('home');
      expect((await source.homes()).map((e) => e.id), <String>['other']);
      expect(File('${temp.path}/attachments/home/a.txt').existsSync(), isFalse);
      await service.resetAllData();
      expect(await source.homes(), isEmpty);
    },
  );
}

List<int> _rewrite(List<int> bytes, void Function(Archive) change) {
  final archive = ZipDecoder().decodeBytes(bytes);
  change(archive);
  return ZipEncoder().encodeBytes(archive);
}

List<int> _futureVersion(List<int> bytes) {
  final source = ZipDecoder().decodeBytes(bytes);
  final result = Archive();
  for (final file in source) {
    if (file.name != 'manifest.json') {
      result.addFile(ArchiveFile(file.name, file.size, file.content));
      continue;
    }
    final json = jsonDecode(utf8.decode(file.content)) as Map<String, Object?>;
    json['schemaVersion'] = 999;
    result.addFile(ArchiveFile.string('manifest.json', jsonEncode(json)));
  }
  return ZipEncoder().encodeBytes(result);
}

List<int> _rewriteData(
  List<int> bytes,
  void Function(Map<String, Object?> data) change,
) {
  final Archive source = ZipDecoder().decodeBytes(bytes);
  final Map<String, Uint8List> original = <String, Uint8List>{
    for (final ArchiveFile file in source) file.name: file.content,
  };
  final Map<String, Object?> data =
      jsonDecode(utf8.decode(original['data.json']!)) as Map<String, Object?>;
  change(data);
  final Uint8List dataBytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
  final Map<String, Object?> manifest = jsonDecode(
    utf8.decode(original['manifest.json']!),
  ) as Map<String, Object?>;
  final List<Object?> attachments = data['attachments']! as List<Object?>;
  final List<MapEntry<String, Uint8List>> contents =
      <MapEntry<String, Uint8List>>[
        MapEntry<String, Uint8List>('data.json', dataBytes),
      ];
  for (final Object? raw in attachments) {
    final Map<String, Object?> item = raw! as Map<String, Object?>;
    final String hash = item['sha256']! as String;
    final Uint8List content = original.entries
        .firstWhere((entry) => sha256.convert(entry.value).toString() == hash)
        .value;
    contents.add(
      MapEntry<String, Uint8List>(item['relativePath']! as String, content),
    );
  }
  manifest['entries'] = contents
      .map(
        (entry) => <String, Object?>{
          'path': entry.key,
          'sha256': sha256.convert(entry.value).toString(),
        },
      )
      .toList();
  final Map<String, Object?> counts =
      manifest['counts']! as Map<String, Object?>;
  for (final String key in <String>[
    'homes',
    'rooms',
    'assets',
    'tasks',
    'occurrences',
    'completionRevisions',
    'attachments',
  ]) {
    counts[key] = (data[key]! as List<Object?>).length;
  }
  final Archive result = Archive();
  for (final MapEntry<String, Uint8List> entry in contents) {
    result.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
  }
  result.addFile(ArchiveFile.string('manifest.json', jsonEncode(manifest)));
  return ZipEncoder().encodeBytes(result);
}

Uint8List _understateFirstCentralEntry(Uint8List bytes) {
  final Uint8List result = Uint8List.fromList(bytes);
  final ByteData view = ByteData.sublistView(result);
  for (var offset = 0; offset <= result.length - 46; offset++) {
    if (view.getUint32(offset, Endian.little) != 0x02014b50) continue;
    if (view.getUint32(offset + 24, Endian.little) > 1) {
      view.setUint32(offset + 24, 1, Endian.little);
      return result;
    }
  }
  throw StateError('ZIP central directory entry was not found');
}

Future<void> _seed(DriftUpkeepRepository repository, Directory root) async {
  await repository.saveHome(
    HomeProfile(id: 'home', name: 'House', addressLabel: '1 Main St'),
  );
  await repository.saveRoom(Room(id: 'room', homeId: 'home', name: 'Kitchen'));
  await repository.saveAsset(
    Asset(id: 'asset', homeId: 'home', roomId: 'room', name: 'Boiler'),
  );
  await repository.saveTask(
    TaskTemplate(
      id: 'task',
      homeId: 'home',
      roomId: 'room',
      assetId: 'asset',
      name: 'Service',
      startDate: LocalDate(2026, 2, 1),
      recurrence: const OneTimeRecurrence(),
      reminder: ReminderIntent(
        hour: 9,
        minute: 30,
        timeZoneId: 'Europe/London',
      ),
    ),
  );
  await repository.saveOccurrence(
    TaskOccurrence(
      id: 'occurrence',
      taskTemplateId: 'task',
      scheduledDate: LocalDate(2026, 2, 1),
      snoozedUntil: LocalDate(2026, 2, 2),
    ),
  );
  await repository.saveCompletion(
    Completion(
      id: 'completion',
      occurrenceId: 'occurrence',
      scheduledDate: LocalDate(2026, 2, 1),
      actualDate: LocalDate(2026, 2, 3),
      notes: 'line 1, "quoted"\r\nline 2',
      parts: 'filter',
      cost: Money(minorUnits: 1234, currency: 'GBP'),
      revision: 1,
      revisedAtUtc: DateTime.utc(2026, 2, 3, 10),
    ),
  );
  await repository.appendCompletionRevision(
    Completion(
      id: 'completion',
      occurrenceId: 'occurrence',
      scheduledDate: LocalDate(2026, 2, 1),
      actualDate: LocalDate(2026, 2, 4),
      notes: 'corrected',
      parts: 'filter',
      cost: Money(minorUnits: 1200, currency: 'GBP'),
      revision: 2,
      revisedAtUtc: DateTime.utc(2026, 2, 4, 10),
    ),
  );
  final file = File('${root.path}/attachments/home/a.txt');
  await file.parent.create(recursive: true);
  await file.writeAsString('photo bytes');
  await repository.saveAttachment(
    AttachmentMetadata(
      id: 'attachment',
      completionId: 'completion',
      relativePath: 'attachments/home/a.txt',
      mediaType: 'text/plain',
      sha256:
          '2a6927613ddc903379f3e02145f22074ccf048c7753cfa1ed8ee26c746682997',
    ),
  );
}
