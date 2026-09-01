import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upkeep_log/adapters/database/drift_upkeep_repository.dart';
import 'package:upkeep_log/adapters/database/upkeep_database.dart'
    hide Asset, Completion, Room, TaskOccurrence, TaskTemplate;
import 'package:upkeep_log/application/attachment_service.dart';
import 'package:upkeep_log/application/data_portability.dart';
import 'package:upkeep_log/application/reminder_coordinator.dart';
import 'package:upkeep_log/application/upkeep_workflow.dart';
import 'package:upkeep_log/domain/domain.dart';
import 'package:upkeep_log/presentation/upkeep_log_app.dart';

void main() {
  late UpkeepDatabase database;
  late DriftUpkeepRepository repository;
  late UpkeepWorkflow workflow;
  var sequence = 0;

  setUp(() {
    database = UpkeepDatabase(NativeDatabase.memory());
    repository = DriftUpkeepRepository(database);
    workflow = UpkeepWorkflow(
      repository,
      clock: FakeClock(
        DateTime.utc(2026, 4, 10, 12),
        today: LocalDate(2026, 4, 10),
        timeZoneId: 'UTC',
      ),
      idFactory: (String kind) => '$kind-${sequence++}',
    );
  });

  tearDown(() => database.close());

  testWidgets('launches to an accessible local-first first-run state', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(UpkeepLogApp(workflow: workflow));
    await tester.pumpAndSettle();

    expect(find.text('Upkeep Log'), findsOneWidget);
    expect(find.text('Start your local upkeep log'), findsOneWidget);
    expect(find.textContaining('No account or network'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Start your local upkeep log')),
      findsOneWidget,
    );
    expect(find.text('Create home profile'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'privacy screen explains storage, exports, and destructive controls',
    (tester) async {
      await workflow.saveHome(HomeProfile(id: 'h', name: 'Home'));
      await tester.pumpWidget(
        UpkeepLogApp(
          workflow: workflow,
          portability: _WidgetPortability(),
          dataTransfer: _WidgetDataTransfer(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Data'));
      await tester.pumpAndSettle();
      expect(find.text('Privacy & data'), findsOneWidget);
      expect(find.textContaining('app-private storage'), findsOneWidget);
      expect(find.text('Local storage: 3.0 KiB'), findsOneWidget);
      expect(find.text('Export CSV history'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Export full backup'), 150);
      expect(find.text('Export full backup'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Restore backup'), 250);
      expect(find.text('Restore backup'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('private addresses'),
        250,
      );
      expect(find.textContaining('private addresses'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Delete Home data'), 250);
      expect(find.text('Delete Home data'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Full reset'), 250);
      expect(find.text('Full reset'), findsOneWidget);
    },
  );

  testWidgets(
    'reminders stay opt-in, explain limits, and expose denied settings recovery',
    (WidgetTester tester) async {
      final _WidgetReminderAdapter adapter = _WidgetReminderAdapter();
      workflow = UpkeepWorkflow(
        repository,
        clock: FakeClock(
          DateTime.utc(2026, 4, 10, 12),
          today: LocalDate(2026, 4, 10),
          timeZoneId: 'America/New_York',
        ),
        reminders: ReminderCoordinator(
          repository: repository,
          adapter: adapter,
          clock: FakeClock(
            DateTime.utc(2026, 4, 10, 12),
            today: LocalDate(2026, 4, 10),
            timeZoneId: 'America/New_York',
          ),
        ),
        idFactory: (String kind) => '$kind-${sequence++}',
      );
      await workflow.saveHome(HomeProfile(id: 'h', name: 'Home'));
      await tester.pumpWidget(UpkeepLogApp(workflow: workflow));
      await tester.pumpAndSettle();
      expect(adapter.permissionRequests, 0);

      await tester.tap(find.text('Setup'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Add task'), 300);
      await tester.tap(find.text('Add task'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Task name'),
        'Change filter',
      );
      await tester.tap(find.text('Enable a local reminder'));
      await tester.pumpAndSettle();

      expect(adapter.permissionRequests, 0);
      expect(find.textContaining('convenience aid'), findsOneWidget);
      expect(
        find.textContaining('permission is requested only'),
        findsOneWidget,
      );
      await tester.tap(find.text('Save task'));
      await tester.pumpAndSettle();

      expect(adapter.permissionRequests, 1);
      expect((await repository.tasks()).single.reminder!.hour, 9);
      expect(
        (await repository.tasks()).single.reminder!.timeZoneId,
        'America/New_York',
      );
      await tester.drag(find.byType(ListView), const Offset(0, 1000));
      await tester.pumpAndSettle();
      expect(find.text('Local reminders'), findsOneWidget);
      expect(find.textContaining('Due lists still work'), findsOneWidget);
      expect(find.text('Open notification settings'), findsOneWidget);
      await tester.tap(find.text('Open notification settings'));
      await tester.pump();
      expect(adapter.settingsOpens, 1);
    },
  );

  testWidgets('create to due to complete workflow records all details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(UpkeepLogApp(workflow: workflow));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create home profile'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Home name'),
      'My home',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Setup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Task name'),
      'Change filter',
    );
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Due'));
    await tester.pumpAndSettle();
    expect(find.text('Change filter'), findsOneWidget);
    expect(find.textContaining('Due today'), findsWidgets);
    expect(
      find.bySemanticsLabel(RegExp('Change filter.*Due today')),
      findsOneWidget,
    );

    await tester.tap(find.text('Complete Change filter'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Notes (optional)'),
      'Replaced on time',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Parts used (optional)'),
      '20x20 filter',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cost (optional)'),
      '12.99',
    );
    await tester.tap(find.text('Record completion'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Completed 2026-04-10'), findsOneWidget);
    expect(find.textContaining('Replaced on time'), findsOneWidget);
    expect(find.textContaining('Parts: 20x20 filter'), findsOneWidget);
    expect(find.textContaining('Cost: USD 12.99'), findsOneWidget);
  });

  testWidgets('validation survives narrow layout and large text', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(UpkeepLogApp(workflow: workflow));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create home profile'));
    await tester.tap(find.text('Create home profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('This field is required'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('early and late completions show domain-derived next dates', (
    WidgetTester tester,
  ) async {
    await workflow.saveHome(HomeProfile(id: 'h', name: 'Home'));
    await workflow.createTask(
      TaskTemplate(
        id: 'early',
        homeId: 'h',
        name: 'Early task',
        startDate: LocalDate(2026, 4, 15),
        recurrence: FixedDayRecurrence(30),
      ),
    );
    await workflow.createTask(
      TaskTemplate(
        id: 'late',
        homeId: 'h',
        name: 'Late task',
        startDate: LocalDate(2026, 4, 1),
        recurrence: FixedDayRecurrence(
          30,
          anchor: RecurrenceAnchor.actualCompletionDate,
        ),
      ),
    );
    await tester.pumpWidget(UpkeepLogApp(workflow: workflow));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Upcoming'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete Early task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record completion'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Scheduled 2026-05-15'), findsOneWidget);

    await tester.tap(find.text('Due'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete Late task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record completion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upcoming'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Scheduled 2026-05-10'), findsOneWidget);
  });

  testWidgets(
    'asset timeline, history filters, and revision detail are visible',
    (WidgetTester tester) async {
      await _seedCorrectedAssetHistory(repository);
      await tester.pumpWidget(UpkeepLogApp(workflow: workflow));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Setup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Boiler'));
      await tester.pumpAndSettle();
      expect(find.text('Chronological timeline'), findsOneWidget);
      expect(find.textContaining('Revision 2'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'nothing');
      await tester.pump();
      expect(
        find.text('No history matches these local filters.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), 'service');
      await tester.pump();
      expect(find.text('1 results • newest completion first'), findsOneWidget);
      await tester.tap(find.text('Service boiler'));
      await tester.pumpAndSettle();
      expect(find.text('Revision 2 • current'), findsOneWidget);
      expect(find.text('Revision 1 • previous'), findsOneWidget);
      expect(find.text('No attachments'), findsOneWidget);
    },
  );

  testWidgets(
    'picker waits for explicit Attach source and cancellation changes nothing',
    (WidgetTester tester) async {
      await _seedCorrectedAssetHistory(repository);
      final _CancellingPicker picker = _CancellingPicker();
      final AttachmentService attachments = AttachmentService(
        repository: repository,
        store: _UnusedStore(),
        picker: picker,
        idFactory: (_) => 'unused',
      );
      await tester.pumpWidget(
        UpkeepLogApp(workflow: workflow, attachments: attachments),
      );
      await tester.pumpAndSettle();
      expect(picker.calls, 0);

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Service boiler'));
      await tester.pumpAndSettle();
      expect(picker.calls, 0);
      await tester.tap(find.text('Attach'));
      await tester.pumpAndSettle();
      expect(picker.calls, 0);
      await tester.tap(find.text('Choose document'));
      await tester.pumpAndSettle();
      expect(picker.calls, 0);
      expect(find.text('Attach privately'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(picker.calls, 1);
      expect(picker.sources, <AttachmentSource>[AttachmentSource.document]);
      expect(await repository.attachments(), isEmpty);
      expect(
        find.textContaining('cancelled or access was denied'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'remove delete failure is caught and refreshes attachment metadata state',
    (WidgetTester tester) async {
      await _seedCorrectedAssetHistory(repository);
      await repository.saveAttachment(
        AttachmentMetadata(
          id: 'attachment',
          completionId: 'c',
          relativePath: 'attachments/h/receipt.pdf',
          mediaType: 'application/pdf',
          sha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          caption: 'Receipt',
        ),
      );
      final AttachmentService attachments = AttachmentService(
        repository: repository,
        store: _ThrowingDeleteStore(),
        picker: _CancellingPicker(),
        idFactory: (_) => 'unused',
      );
      await tester.pumpWidget(
        UpkeepLogApp(workflow: workflow, attachments: attachments),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Service boiler'));
      await tester.pumpAndSettle();
      expect(find.text('Receipt'), findsOneWidget);
      final Finder removeButton = find.byTooltip(
        'Remove attachment metadata and its unreferenced private file',
      );
      await tester.ensureVisible(removeButton);
      await tester.pumpAndSettle();
      await tester.tap(removeButton);
      await tester.pumpAndSettle();
      expect(find.text('Remove attachment?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Remove attachment'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(await repository.attachments(), isEmpty);
      expect(
        find.textContaining(
          'removed from history, but its private file could not be fully cleaned up',
        ),
        findsOneWidget,
      );
      expect(find.text('Remove attachment?'), findsNothing);
      await tester.tap(find.text('Service boiler'));
      await tester.pumpAndSettle();
      expect(find.text('No attachments'), findsOneWidget);
    },
  );

  testWidgets(
    'cleanup failure is caught, retains setup, and refreshes storage',
    (WidgetTester tester) async {
      await workflow.saveHome(HomeProfile(id: 'h', name: 'Home'));
      final _ThrowingCleanupStore store = _ThrowingCleanupStore();
      final AttachmentService attachments = AttachmentService(
        repository: repository,
        store: store,
        picker: _CancellingPicker(),
        idFactory: (_) => 'unused',
      );
      await tester.pumpWidget(
        UpkeepLogApp(workflow: workflow, attachments: attachments),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Setup'));
      await tester.pumpAndSettle();
      expect(find.text('Total: 1.0 KiB'), findsOneWidget);

      await tester.tap(find.text('Clean up Home'));
      await tester.pumpAndSettle();
      expect(find.text('Clean up attachments for Home?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Clean up files'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Private attachment storage — Home'), findsOneWidget);
      expect(find.text('Total: 2.0 KiB'), findsOneWidget);
      expect(
        find.textContaining('Could not finish attachment cleanup for Home'),
        findsOneWidget,
      );
      expect(find.text('Clean up attachments for Home?'), findsNothing);
    },
  );

  testWidgets('setup shows storage and confirmed cleanup for every home', (
    WidgetTester tester,
  ) async {
    await workflow.saveHome(HomeProfile(id: 'first', name: 'First home'));
    await workflow.saveHome(HomeProfile(id: 'second', name: 'Second home'));
    final _StorageStore store = _StorageStore(<String, int>{
      'first': 1024,
      'second': 2048,
    });
    final AttachmentService attachments = AttachmentService(
      repository: repository,
      store: store,
      picker: _CancellingPicker(),
      idFactory: (_) => 'unused',
    );
    await tester.pumpWidget(
      UpkeepLogApp(workflow: workflow, attachments: attachments),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Setup'));
    await tester.pumpAndSettle();
    expect(
      find.text('Private attachment storage — First home'),
      findsOneWidget,
    );
    expect(
      find.text('Private attachment storage — Second home'),
      findsOneWidget,
    );
    expect(find.text('Total: 1.0 KiB'), findsOneWidget);
    expect(find.text('Total: 2.0 KiB'), findsOneWidget);

    await tester.tap(find.text('Clean up Second home'));
    await tester.pumpAndSettle();
    expect(find.text('Clean up attachments for Second home?'), findsOneWidget);
    expect(store.cleanedHomes, isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, 'Clean up files'));
    await tester.pumpAndSettle();
    expect(store.cleanedHomes, <String>['second']);
  });
}

Future<void> _seedCorrectedAssetHistory(
  DriftUpkeepRepository repository,
) async {
  await repository.saveHome(HomeProfile(id: 'h', name: 'Home'));
  await repository.saveRoom(Room(id: 'r', homeId: 'h', name: 'Utility'));
  await repository.saveAsset(
    Asset(id: 'a', homeId: 'h', roomId: 'r', name: 'Boiler'),
  );
  await repository.saveTask(
    TaskTemplate(
      id: 't',
      homeId: 'h',
      roomId: 'r',
      assetId: 'a',
      name: 'Service boiler',
      startDate: LocalDate(2026, 4, 1),
      recurrence: const OneTimeRecurrence(),
    ),
  );
  await repository.saveOccurrence(
    TaskOccurrence(
      id: 'o',
      taskTemplateId: 't',
      scheduledDate: LocalDate(2026, 4, 1),
    ),
  );
  await repository.saveCompletion(
    Completion(
      id: 'c',
      occurrenceId: 'o',
      scheduledDate: LocalDate(2026, 4, 1),
      actualDate: LocalDate(2026, 4, 2),
      notes: 'initial',
      revision: 1,
      revisedAtUtc: DateTime.utc(2026, 4, 2),
    ),
  );
  await repository.appendCompletionRevision(
    Completion(
      id: 'c',
      occurrenceId: 'o',
      scheduledDate: LocalDate(2026, 4, 1),
      actualDate: LocalDate(2026, 4, 3),
      notes: 'corrected',
      revision: 2,
      revisedAtUtc: DateTime.utc(2026, 4, 3),
    ),
  );
}

final class _WidgetReminderAdapter implements ReminderAdapter {
  int permissionRequests = 0;
  int settingsOpens = 0;
  ReminderPermission permission = ReminderPermission.notDetermined;

  @override
  Future<String> currentTimeZoneId() async => 'America/New_York';

  @override
  Future<ReminderPermission> permissionStatus() async => permission;

  @override
  Future<ReminderPermission> requestPermission() async {
    permissionRequests++;
    permission = ReminderPermission.denied;
    return permission;
  }

  @override
  Future<ReminderDeliveryReport> replaceAll(
    List<ReminderScheduleRequest> requests,
  ) async => ReminderDeliveryReport(
    scheduledCount: requests.length,
    limitation: 'Delivery timing is controlled by the operating system.',
  );

  @override
  Future<void> openSettings() async {
    settingsOpens++;
  }
}

final class _CancellingPicker implements AttachmentPicker {
  int calls = 0;
  final List<AttachmentSource> sources = <AttachmentSource>[];

  @override
  Future<PickedAttachment?> pick(AttachmentSource source) async {
    calls++;
    sources.add(source);
    return null;
  }
}

final class _WidgetPortability implements DataPortability {
  @override
  Future<LocalStorageSummary> storageSummary() async =>
      const LocalStorageSummary(
        databaseBytes: 2048,
        attachmentBytesByHome: <String, int>{'h': 1024},
      );
  @override
  Future<Uint8List> createBackup() async => Uint8List(0);
  @override
  Future<void> deleteHomeData(String homeId) async {}
  @override
  Future<Uint8List> exportCsv({String? homeId, String? assetId}) async =>
      Uint8List(0);
  @override
  Future<void> resetAllData() async {}
  @override
  Future<RestoreReport> restorePaths(
    String incomingPath, {
    required String preRestoreBackupPath,
  }) async => const RestoreReport(
    schemaVersion: 1,
    homeCount: 0,
    attachmentCount: 0,
    preRestoreBackupPath: 'before.zip',
    conflictCount: 0,
  );
}

final class _WidgetDataTransfer implements DataTransfer {
  @override
  Future<TransferResult> exportFile({
    required String suggestedName,
    required String mediaType,
    required Uint8List bytes,
  }) async => const TransferResult(TransferStatus.cancelled);
  @override
  Future<TransferResult> importBackup() async =>
      const TransferResult(TransferStatus.cancelled);
}

final class _UnusedStore implements AttachmentStore {
  Never _unused() =>
      throw StateError('Store must not be used for cancellation');

  @override
  Future<int> cleanup(String homeId, Set<String> referencedPaths) async => 0;
  @override
  Future<StoredAttachment> copyIntoPrivateStorage(
    PickedAttachment selected,
    String relativePath,
  ) async => _unused();
  @override
  Future<void> delete(String relativePath) async => _unused();
  @override
  Future<void> discardSelection(PickedAttachment selected) async => _unused();
  @override
  Future<AttachmentInspection> inspect(
    String relativePath,
    String expectedSha256,
  ) async => _unused();
  @override
  Future<int> storageUsed(String homeId) async => 0;
}

final class _StorageStore implements AttachmentStore {
  _StorageStore(this.totals);

  final Map<String, int> totals;
  final List<String> cleanedHomes = <String>[];

  Never _unused() => throw StateError('Mutation is not expected');

  @override
  Future<int> cleanup(String homeId, Set<String> referencedPaths) async {
    cleanedHomes.add(homeId);
    return 0;
  }

  @override
  Future<StoredAttachment> copyIntoPrivateStorage(
    PickedAttachment selected,
    String relativePath,
  ) async => _unused();

  @override
  Future<void> delete(String relativePath) async => _unused();

  @override
  Future<void> discardSelection(PickedAttachment selected) async => _unused();

  @override
  Future<AttachmentInspection> inspect(
    String relativePath,
    String expectedSha256,
  ) async => _unused();

  @override
  Future<int> storageUsed(String homeId) async => totals[homeId]!;
}

final class _ThrowingDeleteStore implements AttachmentStore {
  Never _unused() => throw StateError('Mutation is not expected');

  @override
  Future<int> cleanup(String homeId, Set<String> referencedPaths) async =>
      _unused();

  @override
  Future<StoredAttachment> copyIntoPrivateStorage(
    PickedAttachment selected,
    String relativePath,
  ) async => _unused();

  @override
  Future<void> delete(String relativePath) async {
    throw StateError('private file is locked');
  }

  @override
  Future<void> discardSelection(PickedAttachment selected) async => _unused();

  @override
  Future<AttachmentInspection> inspect(
    String relativePath,
    String expectedSha256,
  ) async => const AttachmentInspection(AttachmentHealth.available, 128);

  @override
  Future<int> storageUsed(String homeId) async => 128;
}

final class _ThrowingCleanupStore implements AttachmentStore {
  var bytes = 1024;

  Never _unused() => throw StateError('Mutation is not expected');

  @override
  Future<int> cleanup(String homeId, Set<String> referencedPaths) async {
    bytes = 2048;
    throw StateError('storage access denied');
  }

  @override
  Future<StoredAttachment> copyIntoPrivateStorage(
    PickedAttachment selected,
    String relativePath,
  ) async => _unused();

  @override
  Future<void> delete(String relativePath) async => _unused();

  @override
  Future<void> discardSelection(PickedAttachment selected) async => _unused();

  @override
  Future<AttachmentInspection> inspect(
    String relativePath,
    String expectedSha256,
  ) async => _unused();

  @override
  Future<int> storageUsed(String homeId) async => bytes;
}
