import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upkeep_log/adapters/database/drift_upkeep_repository.dart';
import 'package:upkeep_log/adapters/database/upkeep_database.dart'
    hide Asset, Completion, Room, TaskOccurrence, TaskTemplate;
import 'package:upkeep_log/domain/domain.dart';

void main() {
  late UpkeepDatabase database;
  late DriftUpkeepRepository repository;

  setUp(() {
    database = UpkeepDatabase(NativeDatabase.memory());
    repository = DriftUpkeepRepository(database);
  });
  tearDown(() => database.close());

  test('schema v1 performs typed hierarchy round trips', () async {
    expect(database.schemaVersion, 1);
    await repository.saveHome(HomeProfile(id: 'h', name: 'Home'));
    await repository.saveRoom(Room(id: 'r', homeId: 'h', name: 'Kitchen'));
    await repository.saveAsset(
      Asset(id: 'a', homeId: 'h', roomId: 'r', name: 'Boiler'),
    );
    await repository.saveTask(
      TaskTemplate(
        id: 't',
        homeId: 'h',
        roomId: 'r',
        assetId: 'a',
        name: 'Service',
        startDate: LocalDate(2024, 2, 29),
        recurrence: YearlyRecurrence(
          anchor: RecurrenceAnchor.actualCompletionDate,
        ),
        reminder: ReminderIntent(
          hour: 9,
          minute: 15,
          timeZoneId: 'Europe/London',
        ),
      ),
    );
    await repository.saveOccurrence(
      TaskOccurrence(
        id: 'o',
        taskTemplateId: 't',
        scheduledDate: LocalDate(2025, 2, 28),
        snoozedUntil: LocalDate(2025, 3, 2),
      ),
    );

    expect((await repository.homeById('h'))!.name, 'Home');
    expect((await repository.roomById('r'))!.homeId, 'h');
    expect((await repository.assetById('a'))!.roomId, 'r');
    final TaskTemplate task = (await repository.taskById('t'))!;
    expect(task.startDate, LocalDate(2024, 2, 29));
    expect(task.recurrenceAnchorDay, 29);
    expect(task.recurrenceAnchorMonth, 2);
    expect(task.recurrence, isA<YearlyRecurrence>());
    expect(task.recurrence.anchor, RecurrenceAnchor.actualCompletionDate);
    expect(task.reminder!.timeZoneId, 'Europe/London');
    expect(
      const ScheduleEngine().nextDue(
        task,
        lastScheduled: LocalDate(2025, 2, 28),
        actualCompletion: LocalDate(2027, 2, 28),
      ),
      LocalDate(2028, 2, 28),
    );
    await repository.saveTask(
      TaskTemplate(
        id: 'calendar-task',
        homeId: 'h',
        name: 'Calendar anchor',
        startDate: LocalDate(2024, 1, 31),
        recurrence: MonthlyRecurrence(),
      ),
    );
    final TaskTemplate persistedCalendarTask = (await repository.taskById(
      'calendar-task',
    ))!;
    expect(
      const ScheduleEngine().nextDue(
        persistedCalendarTask,
        lastScheduled: LocalDate(2024, 2, 29),
      ),
      LocalDate(2024, 3, 31),
    );
    expect(
      (await repository.occurrenceById('o'))!.snoozedUntil,
      LocalDate(2025, 3, 2),
    );
  });

  test(
    'completion corrections append revisions and attachments round trip',
    () async {
      await repository.saveHome(HomeProfile(id: 'h', name: 'Home'));
      await repository.saveTask(
        TaskTemplate(
          id: 't',
          homeId: 'h',
          name: 'Filter',
          startDate: LocalDate(2026, 1, 1),
          recurrence: FixedDayRecurrence(90),
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
          actualDate: LocalDate(2026, 4, 3),
          notes: 'first',
          cost: Money(minorUnits: 1299, currency: 'USD'),
          revision: 1,
          revisedAtUtc: DateTime.utc(2026, 4, 3, 10),
        ),
      );
      await repository.appendCompletionRevision(
        Completion(
          id: 'c',
          occurrenceId: 'o',
          scheduledDate: LocalDate(2026, 4, 1),
          actualDate: LocalDate(2026, 4, 2),
          notes: 'corrected',
          cost: Money(minorUnits: 999, currency: 'USD'),
          revision: 2,
          revisedAtUtc: DateTime.utc(2026, 4, 4, 10),
        ),
      );
      await repository.saveAttachment(
        AttachmentMetadata(
          id: 'att',
          completionId: 'c',
          relativePath: 'attachments/r.jpg',
          mediaType: 'image/jpeg',
          sha256: 'b' * 64,
          caption: 'Receipt',
        ),
      );

      final List<Completion> history = await repository.completionHistory('c');
      expect(history.map((Completion c) => c.revision), <int>[1, 2]);
      expect((await repository.latestCompletion('c'))!.notes, 'corrected');
      expect(
        (await repository.attachmentsForCompletion('c')).single.sha256,
        'b' * 64,
      );
      await expectLater(
        repository.appendCompletionRevision(history.first),
        throwsStateError,
      );
    },
  );

  test(
    'foreign keys restrict referenced room deletion and cascade home deletion',
    () async {
      await repository.saveHome(HomeProfile(id: 'h', name: 'Home'));
      await repository.saveRoom(Room(id: 'r', homeId: 'h', name: 'Kitchen'));
      await repository.saveAsset(
        Asset(id: 'a', homeId: 'h', roomId: 'r', name: 'Sink'),
      );

      await expectLater(repository.deleteRoom('r'), throwsA(anything));
      await repository.deleteHome('h');
      expect(await repository.homeById('h'), isNull);
      expect(await repository.roomById('r'), isNull);
      expect(await repository.assetById('a'), isNull);
    },
  );

  test('rejects cross-home hierarchy through repository and raw SQL', () async {
    await repository.saveHome(HomeProfile(id: 'h1', name: 'One'));
    await repository.saveHome(HomeProfile(id: 'h2', name: 'Two'));
    await repository.saveRoom(Room(id: 'r2', homeId: 'h2', name: 'Other'));
    await expectLater(
      repository.saveAsset(
        Asset(id: 'bad', homeId: 'h1', roomId: 'r2', name: 'Bad'),
      ),
      throwsA(anything),
    );
    await expectLater(
      database.customStatement(
        "INSERT INTO assets(id,home_id,room_id,name) VALUES ('raw','h1','r2','Bad')",
      ),
      throwsA(anything),
    );
    await repository.saveAsset(
      Asset(id: 'a2', homeId: 'h2', roomId: 'r2', name: 'Other asset'),
    );
    await expectLater(
      repository.saveTask(
        TaskTemplate(
          id: 'bad-task',
          homeId: 'h1',
          roomId: 'r2',
          assetId: 'a2',
          name: 'Bad',
          startDate: LocalDate(2026, 1, 1),
          recurrence: MonthlyRecurrence(),
        ),
      ),
      throwsA(anything),
    );
    await expectLater(
      database.customStatement(
        "INSERT INTO task_templates(id,home_id,room_id,name,start_date,recurrence_kind,recurrence_interval,recurrence_anchor,recurrence_anchor_day,recurrence_anchor_month,paused) VALUES ('raw-task','h1','r2','Bad','2026-01-01','monthly',1,'scheduledDate',1,1,0)",
      ),
      throwsA(anything),
    );
  });

  test('completion validates date, updates state atomically, and revisions increase time', () async {
    await repository.saveHome(HomeProfile(id: 'h', name: 'Home'));
    await repository.saveTask(
      TaskTemplate(
        id: 't',
        homeId: 'h',
        name: 'Task',
        startDate: LocalDate(2026, 1, 1),
        recurrence: const OneTimeRecurrence(),
      ),
    );
    await repository.saveOccurrence(
      TaskOccurrence(
        id: 'o',
        taskTemplateId: 't',
        scheduledDate: LocalDate(2026, 1, 2),
      ),
    );
    Completion completion(
      DateTime revisedAt, {
      int revision = 1,
      LocalDate? scheduled,
    }) => Completion(
      id: 'c',
      occurrenceId: 'o',
      scheduledDate: scheduled ?? LocalDate(2026, 1, 2),
      actualDate: LocalDate(2026, 1, 3),
      revision: revision,
      revisedAtUtc: revisedAt,
    );
    await expectLater(
      repository.saveCompletion(
        completion(DateTime.utc(2026), scheduled: LocalDate(2026, 1, 1)),
      ),
      throwsStateError,
    );
    expect(await repository.completionHistory('c'), isEmpty);
    expect(
      (await repository.occurrenceById('o'))!.state,
      OccurrenceState.pending,
    );
    await repository.saveCompletion(completion(DateTime.utc(2026, 1, 3)));
    expect(
      (await repository.occurrenceById('o'))!.state,
      OccurrenceState.completed,
    );
    await expectLater(
      repository.appendCompletionRevision(
        completion(DateTime.utc(2026, 1, 2), revision: 2),
      ),
      throwsStateError,
    );
  });

  test('database rejects invalid constrained values', () async {
    await repository.saveHome(HomeProfile(id: 'h', name: 'Home'));
    final List<String> invalidTasks = <String>[
      "VALUES ('t1','h','T','2026-01-01','monthly',0,'scheduledDate',31,1,0)",
      "VALUES ('t2','h','T','2026-01-01','nonsense',1,'scheduledDate',1,1,0)",
      "VALUES ('t3','h','T','2026-01-01','monthly',1,'bad',1,1,0)",
      "VALUES ('t4','h','T','2026-01-01','monthly',1,'scheduledDate',31,2,0)",
    ];
    for (final String values in invalidTasks) {
      await expectLater(
        database.customStatement(
          'INSERT INTO task_templates(id,home_id,name,start_date,recurrence_kind,recurrence_interval,recurrence_anchor,recurrence_anchor_day,recurrence_anchor_month,paused) $values',
        ),
        throwsA(anything),
      );
    }
    await expectLater(
      database.customStatement(
        "INSERT INTO task_templates(id,home_id,name,start_date,recurrence_kind,recurrence_interval,recurrence_anchor,recurrence_anchor_day,recurrence_anchor_month,reminder_hour,paused) VALUES ('t5','h','T','2026-01-01','monthly',1,'scheduledDate',1,1,9,0)",
      ),
      throwsA(anything),
    );

    await repository.saveTask(
      TaskTemplate(
        id: 'valid-task',
        homeId: 'h',
        name: 'Valid',
        startDate: LocalDate(2026, 1, 1),
        recurrence: const OneTimeRecurrence(),
      ),
    );
    await expectLater(
      database.customStatement(
        "INSERT INTO task_occurrences(id,task_template_id,scheduled_date,state) VALUES ('bad-state','valid-task','2026-01-01','unknown')",
      ),
      throwsA(anything),
    );
    await expectLater(
      database.customStatement(
        "INSERT INTO task_occurrences(id,task_template_id,scheduled_date,snoozed_until,state) VALUES ('bad-snooze','valid-task','2026-01-02','2026-01-01','pending')",
      ),
      throwsA(anything),
    );
    await repository.saveOccurrence(
      TaskOccurrence(
        id: 'valid-occurrence',
        taskTemplateId: 'valid-task',
        scheduledDate: LocalDate(2026, 1, 1),
      ),
    );
    await expectLater(
      database.customStatement(
        "INSERT INTO completions(id,occurrence_id,scheduled_date) VALUES ('bad-completion','valid-occurrence','2026-01-02')",
      ),
      throwsA(anything),
    );
    await repository.saveCompletion(
      Completion(
        id: 'valid-completion',
        occurrenceId: 'valid-occurrence',
        scheduledDate: LocalDate(2026, 1, 1),
        actualDate: LocalDate(2026, 1, 1),
        revision: 1,
        revisedAtUtc: DateTime.utc(1960),
      ),
    );
    await expectLater(
      database.customStatement(
        "INSERT INTO completion_revisions(completion_id,revision,actual_date,cost_minor_units,revised_at_utc) VALUES ('valid-completion',2,'2026-01-02',100,0)",
      ),
      throwsA(anything),
    );
    await expectLater(
      database.customStatement(
        "INSERT INTO completion_revisions(completion_id,revision,actual_date,cost_minor_units,cost_currency,revised_at_utc) VALUES ('valid-completion',2,'2026-01-02',100,'usd',0)",
      ),
      throwsA(anything),
    );
    await expectLater(
      database.customStatement(
        "INSERT INTO attachment_metadata_rows(id,completion_id,relative_path,media_type,sha256) VALUES ('bad-path','valid-completion','C:\\secret','text/plain','aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')",
      ),
      throwsA(anything),
    );
    await expectLater(
      database.customStatement(
        "INSERT INTO attachment_metadata_rows(id,completion_id,relative_path,media_type,sha256) VALUES ('bad-hash','valid-completion','attachments/x','text/plain','not-a-sha')",
      ),
      throwsA(anything),
    );
  });

  test('duplicate completion retry leaves exactly one completion', () async {
    await repository.saveHome(HomeProfile(id: 'h', name: 'Home'));
    await repository.saveTask(
      TaskTemplate(
        id: 't',
        homeId: 'h',
        name: 'Task',
        startDate: LocalDate(2026, 1, 1),
        recurrence: const OneTimeRecurrence(),
      ),
    );
    await repository.saveOccurrence(
      TaskOccurrence(
        id: 'o',
        taskTemplateId: 't',
        scheduledDate: LocalDate(2026, 1, 1),
      ),
    );
    Completion value(String id) => Completion(
      id: id,
      occurrenceId: 'o',
      scheduledDate: LocalDate(2026, 1, 1),
      actualDate: LocalDate(2026, 1, 1),
      revision: 1,
      revisedAtUtc: DateTime.utc(2026),
    );
    final List<Object?> results = await Future.wait(<Future<Object?>>[
      repository
          .saveCompletion(value('c1'))
          .then<Object?>((_) => null)
          .catchError((Object e) => e),
      repository
          .saveCompletion(value('c2'))
          .then<Object?>((_) => null)
          .catchError((Object e) => e),
    ]);
    expect(results.whereType<Object>().length, 1);
    expect(
      (await repository.occurrenceById('o'))!.state,
      OccurrenceState.completed,
    );
    final int count =
        (await database
                .customSelect('SELECT count(*) AS n FROM completions')
                .getSingle())
            .read<int>('n');
    expect(count, 1);
  });

  test(
    'revision timestamps round trip at microsecond precision across epoch',
    () async {
      await repository.saveHome(HomeProfile(id: 'h', name: 'Home'));
      await repository.saveTask(
        TaskTemplate(
          id: 't',
          homeId: 'h',
          name: 'Historic task',
          startDate: LocalDate(1969, 12, 31),
          recurrence: const OneTimeRecurrence(),
        ),
      );
      await repository.saveOccurrence(
        TaskOccurrence(
          id: 'o',
          taskTemplateId: 't',
          scheduledDate: LocalDate(1969, 12, 31),
        ),
      );
      final DateTime beforeEpoch = DateTime.utc(
        1969,
        12,
        31,
        23,
        59,
        59,
        999,
        500,
      );
      final DateTime afterEpoch = DateTime.utc(1970, 1, 1, 0, 0, 0, 0, 100);
      await repository.saveCompletion(
        Completion(
          id: 'c',
          occurrenceId: 'o',
          scheduledDate: LocalDate(1969, 12, 31),
          actualDate: LocalDate(1969, 12, 31),
          revision: 1,
          revisedAtUtc: beforeEpoch,
        ),
      );
      await repository.appendCompletionRevision(
        Completion(
          id: 'c',
          occurrenceId: 'o',
          scheduledDate: LocalDate(1969, 12, 31),
          actualDate: LocalDate(1970, 1, 1),
          revision: 2,
          revisedAtUtc: afterEpoch,
        ),
      );

      final List<Completion> history = await repository.completionHistory('c');
      expect(history.map((Completion value) => value.revisedAtUtc), <DateTime>[
        beforeEpoch,
        afterEpoch,
      ]);
    },
  );
}
