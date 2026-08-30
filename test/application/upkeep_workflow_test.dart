import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upkeep_log/adapters/database/drift_upkeep_repository.dart';
import 'package:upkeep_log/adapters/database/upkeep_database.dart'
    hide Completion, TaskOccurrence, TaskTemplate;
import 'package:upkeep_log/application/reminder_coordinator.dart';
import 'package:upkeep_log/application/upkeep_workflow.dart';
import 'package:upkeep_log/domain/domain.dart';

void main() {
  late UpkeepDatabase database;
  late DriftUpkeepRepository repository;
  late FakeClock clock;
  late UpkeepWorkflow workflow;
  var sequence = 0;

  setUp(() {
    database = UpkeepDatabase(NativeDatabase.memory());
    repository = DriftUpkeepRepository(database);
    clock = FakeClock(
      DateTime.utc(2026, 2, 2, 12),
      today: LocalDate(2026, 2, 2),
      timeZoneId: 'America/New_York',
    );
    workflow = UpkeepWorkflow(
      repository,
      clock: clock,
      idFactory: (String kind) => '$kind-${sequence++}',
    );
  });

  tearDown(() => database.close());

  test(
    'create, bucket, snooze, and complete use domain schedule rules',
    () async {
      await workflow.saveHome(HomeProfile(id: 'h', name: 'Home'));
      final TaskTemplate task = TaskTemplate(
        id: 't',
        homeId: 'h',
        name: 'Replace filter',
        startDate: LocalDate(2026, 1, 31),
        recurrence: MonthlyRecurrence(),
      );
      await workflow.createTask(task);

      WorkflowSnapshot snapshot = await workflow.load();
      expect(snapshot.inBucket(OccurrenceBucket.overdue), hasLength(1));
      final TaskOccurrence occurrence = snapshot.occurrences.single;
      await workflow.snooze(occurrence, LocalDate(2026, 2, 4));
      snapshot = await workflow.load();
      expect(snapshot.inBucket(OccurrenceBucket.snoozed), hasLength(1));

      await workflow.complete(
        occurrence: snapshot.occurrences.single,
        actualDate: LocalDate(2026, 2, 2),
        notes: 'Changed early',
        parts: '20x20 filter',
        cost: Money(minorUnits: 1299, currency: 'USD'),
      );
      snapshot = await workflow.load();
      expect(snapshot.inBucket(OccurrenceBucket.completed), hasLength(1));
      expect(
        snapshot.inBucket(OccurrenceBucket.upcoming).single.scheduledDate,
        LocalDate(2026, 2, 28),
      );
      expect(snapshot.completions.single.parts, '20x20 filter');
      expect(snapshot.completions.single.cost!.minorUnits, 1299);
    },
  );

  test('actual-completion anchor handles a late completion', () async {
    await workflow.saveHome(HomeProfile(id: 'h', name: 'Home'));
    await workflow.createTask(
      TaskTemplate(
        id: 't',
        homeId: 'h',
        name: 'Inspect',
        startDate: LocalDate(2026, 1, 10),
        recurrence: FixedDayRecurrence(
          30,
          anchor: RecurrenceAnchor.actualCompletionDate,
        ),
      ),
    );
    final TaskOccurrence occurrence =
        (await workflow.load()).occurrences.single;
    await workflow.complete(
      occurrence: occurrence,
      actualDate: LocalDate(2026, 1, 15),
    );
    expect(
      (await workflow.load())
          .inBucket(OccurrenceBucket.upcoming)
          .single
          .scheduledDate,
      LocalDate(2026, 2, 14),
    );
  });

  test(
    'completion and next occurrence roll back together on failure',
    () async {
      await repository.saveHome(HomeProfile(id: 'h', name: 'Home'));
      await repository.saveTask(
        TaskTemplate(
          id: 't',
          homeId: 'h',
          name: 'Task',
          startDate: LocalDate(2026, 1, 1),
          recurrence: MonthlyRecurrence(),
        ),
      );
      await repository.saveOccurrence(
        TaskOccurrence(
          id: 'o',
          taskTemplateId: 't',
          scheduledDate: LocalDate(2026, 1, 1),
        ),
      );
      await repository.saveOccurrence(
        TaskOccurrence(
          id: 'duplicate',
          taskTemplateId: 't',
          scheduledDate: LocalDate(2026, 2, 1),
        ),
      );
      await expectLater(
        repository.completeOccurrence(
          Completion(
            id: 'c',
            occurrenceId: 'o',
            scheduledDate: LocalDate(2026, 1, 1),
            actualDate: LocalDate(2026, 1, 1),
            revision: 1,
            revisedAtUtc: DateTime.utc(2026),
          ),
          nextOccurrence: TaskOccurrence(
            id: 'duplicate',
            taskTemplateId: 't',
            scheduledDate: LocalDate(2026, 3, 1),
          ),
        ),
        throwsA(anything),
      );
      expect(
        (await repository.occurrenceById('o'))!.state,
        OccurrenceState.pending,
      );
      expect(await repository.latestCompletion('c'), isNull);
    },
  );

  test('reminder side effects follow persisted task lifecycle', () async {
    final _WorkflowReminderAdapter adapter = _WorkflowReminderAdapter();
    final ReminderCoordinator reminders = ReminderCoordinator(
      repository: repository,
      adapter: adapter,
      clock: clock,
    );
    final UpkeepWorkflow remindedWorkflow = UpkeepWorkflow(
      repository,
      clock: clock,
      reminders: reminders,
      idFactory: (String kind) => '$kind-${sequence++}',
    );
    await remindedWorkflow.saveHome(HomeProfile(id: 'h', name: 'Home'));
    final TaskTemplate task = TaskTemplate(
      id: 't',
      homeId: 'h',
      name: 'Filter',
      startDate: LocalDate(2026, 2, 2),
      recurrence: MonthlyRecurrence(),
      reminder: ReminderIntent(
        hour: 9,
        minute: 0,
        timeZoneId: 'America/New_York',
      ),
    );

    await remindedWorkflow.createTask(task, requestReminderPermission: true);
    expect(adapter.permissionRequests, 1);
    expect(adapter.latest.single.date, LocalDate(2026, 2, 2));

    TaskOccurrence occurrence = (await repository.occurrences()).single;
    await remindedWorkflow.snooze(occurrence, LocalDate(2026, 2, 5));
    expect(adapter.latest.single.date, LocalDate(2026, 2, 5));

    occurrence = (await repository.occurrences()).single;
    await remindedWorkflow.complete(
      occurrence: occurrence,
      actualDate: LocalDate(2026, 2, 2),
    );
    expect(adapter.latest.single.date, LocalDate(2026, 3, 2));

    await remindedWorkflow.updateTask(
      TaskTemplate(
        id: task.id,
        homeId: task.homeId,
        name: task.name,
        startDate: task.startDate,
        recurrence: task.recurrence,
        reminder: task.reminder,
        paused: true,
      ),
    );
    expect(adapter.latest, isEmpty);

    final UpkeepWorkflow restarted = UpkeepWorkflow(
      repository,
      clock: clock,
      reminders: reminders,
    );
    await restarted.load();
    expect(adapter.latest, isEmpty);
  });
}

final class _WorkflowReminderAdapter implements ReminderAdapter {
  int permissionRequests = 0;
  ReminderPermission permission = ReminderPermission.notDetermined;
  List<ReminderScheduleRequest> latest = <ReminderScheduleRequest>[];

  @override
  Future<String> currentTimeZoneId() async => 'America/New_York';

  @override
  Future<ReminderPermission> permissionStatus() async => permission;

  @override
  Future<ReminderPermission> requestPermission() async {
    permissionRequests++;
    permission = ReminderPermission.granted;
    return permission;
  }

  @override
  Future<ReminderDeliveryReport> replaceAll(
    List<ReminderScheduleRequest> requests,
  ) async {
    latest = List<ReminderScheduleRequest>.of(requests);
    return ReminderDeliveryReport(
      scheduledCount: latest.length,
      limitation: 'OS controlled.',
    );
  }

  @override
  Future<void> openSettings() async {}
}
