import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upkeep_log/adapters/database/drift_upkeep_repository.dart';
import 'package:upkeep_log/adapters/database/upkeep_database.dart'
    hide TaskOccurrence, TaskTemplate;
import 'package:upkeep_log/application/reminder_coordinator.dart';
import 'package:upkeep_log/domain/domain.dart';

void main() {
  late UpkeepDatabase database;
  late DriftUpkeepRepository repository;
  late FakeClock clock;
  late _FakeReminderAdapter adapter;
  late ReminderCoordinator coordinator;

  setUp(() {
    database = UpkeepDatabase(NativeDatabase.memory());
    repository = DriftUpkeepRepository(database);
    clock = FakeClock(
      DateTime.utc(2026, 3, 7, 12),
      today: LocalDate(2026, 3, 7),
      timeZoneId: 'America/New_York',
    );
    adapter = _FakeReminderAdapter();
    coordinator = ReminderCoordinator(
      repository: repository,
      adapter: adapter,
      clock: clock,
    );
  });

  tearDown(() => database.close());

  test(
    'normal reconciliation never requests permission and denied stays safe',
    () async {
      await _seedReminder(repository);
      adapter.permission = ReminderPermission.denied;

      final ReminderStatus status = await coordinator.reconcile();

      expect(adapter.permissionRequests, 0);
      expect(adapter.replacements, hasLength(1));
      expect(adapter.replacements.single, isEmpty);
      expect(status.permission, ReminderPermission.denied);
      expect(status.scheduledCount, 0);
      expect(status.message, contains('Due lists still work'));
    },
  );

  test(
    'explicit enable requests once and schedules snoozed wall-clock intent',
    () async {
      await _seedReminder(repository, snoozedUntil: LocalDate(2026, 3, 9));
      adapter.permission = ReminderPermission.notDetermined;
      adapter.permissionAfterRequest = ReminderPermission.granted;

      final ReminderStatus status = await coordinator.reconcile(
        requestPermission: true,
      );

      expect(adapter.permissionRequests, 1);
      final ReminderScheduleRequest request =
          adapter.replacements.single.single;
      expect(request.id, 'occurrence');
      expect(request.taskName, 'Change filter');
      expect(request.date, LocalDate(2026, 3, 9));
      expect(request.intent.hour, 8);
      expect(request.intent.minute, 30);
      expect(request.intent.timeZoneId, 'America/New_York');
      expect(status.permission, ReminderPermission.granted);
      expect(status.scheduledCount, 1);
      expect(status.message, contains('convenience'));
    },
  );

  test(
    'paused tasks and completed occurrences are removed from delivery',
    () async {
      await _seedReminder(repository, paused: true);
      adapter.permission = ReminderPermission.granted;

      await coordinator.reconcile();

      expect(adapter.replacements.single, isEmpty);
    },
  );

  test(
    'adapter failure is reported without changing local task truth',
    () async {
      await _seedReminder(repository);
      adapter.permission = ReminderPermission.granted;
      adapter.failure = StateError('OS scheduler unavailable');

      final ReminderStatus status = await coordinator.reconcile();

      expect(status.scheduledCount, 0);
      expect(status.message, contains('OS scheduler unavailable'));
      expect((await repository.tasks()).single.name, 'Change filter');
      expect(
        (await repository.occurrences()).single.state,
        OccurrenceState.pending,
      );
    },
  );
}

Future<void> _seedReminder(
  DriftUpkeepRepository repository, {
  LocalDate? snoozedUntil,
  bool paused = false,
}) async {
  await repository.saveHome(HomeProfile(id: 'home', name: 'Home'));
  await repository.saveTask(
    TaskTemplate(
      id: 'task',
      homeId: 'home',
      name: 'Change filter',
      startDate: LocalDate(2026, 3, 8),
      recurrence: MonthlyRecurrence(),
      reminder: ReminderIntent(
        hour: 8,
        minute: 30,
        timeZoneId: 'America/New_York',
      ),
      paused: paused,
    ),
  );
  await repository.saveOccurrence(
    TaskOccurrence(
      id: 'occurrence',
      taskTemplateId: 'task',
      scheduledDate: LocalDate(2026, 3, 8),
      snoozedUntil: snoozedUntil,
    ),
  );
}

final class _FakeReminderAdapter implements ReminderAdapter {
  ReminderPermission permission = ReminderPermission.notDetermined;
  ReminderPermission permissionAfterRequest = ReminderPermission.denied;
  int permissionRequests = 0;
  final List<List<ReminderScheduleRequest>> replacements =
      <List<ReminderScheduleRequest>>[];
  Object? failure;
  var settingsOpens = 0;

  @override
  Future<String> currentTimeZoneId() async => 'America/New_York';

  @override
  Future<ReminderPermission> permissionStatus() async => permission;

  @override
  Future<ReminderPermission> requestPermission() async {
    permissionRequests++;
    permission = permissionAfterRequest;
    return permission;
  }

  @override
  Future<ReminderDeliveryReport> replaceAll(
    List<ReminderScheduleRequest> requests,
  ) async {
    replacements.add(List<ReminderScheduleRequest>.of(requests));
    if (failure case final Object error) throw error;
    return ReminderDeliveryReport(
      scheduledCount: requests.length,
      limitation: 'Delivery timing is controlled by the operating system.',
    );
  }

  @override
  Future<void> openSettings() async {
    settingsOpens++;
  }
}
