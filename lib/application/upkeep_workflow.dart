import 'package:upkeep_log/domain/domain.dart';

import 'upkeep_repository.dart';

typedef IdFactory = String Function(String kind);

/// Fully resolved local state used by the presentation layer.
final class WorkflowSnapshot {
  const WorkflowSnapshot({
    required this.homes,
    required this.rooms,
    required this.assets,
    required this.tasks,
    required this.occurrences,
    required this.completions,
    required this.today,
  });

  final List<HomeProfile> homes;
  final List<Room> rooms;
  final List<Asset> assets;
  final List<TaskTemplate> tasks;
  final List<TaskOccurrence> occurrences;
  final List<Completion> completions;
  final LocalDate today;

  HomeProfile? get primaryHome => homes.isEmpty ? null : homes.first;
  TaskTemplate taskFor(TaskOccurrence value) =>
      tasks.singleWhere((TaskTemplate task) => task.id == value.taskTemplateId);
  Completion? completionFor(TaskOccurrence value) {
    for (final Completion completion in completions) {
      if (completion.occurrenceId == value.id) return completion;
    }
    return null;
  }

  List<TaskOccurrence> inBucket(OccurrenceBucket bucket) =>
      occurrences
          .where(
            (TaskOccurrence value) =>
                classifyOccurrence(value, today) == bucket,
          )
          .toList(growable: false)
        ..sort(
          (TaskOccurrence a, TaskOccurrence b) =>
              a.visibleDate.compareTo(b.visibleDate),
        );
}

/// Application use cases for the due-to-completion vertical workflow.
final class UpkeepWorkflow {
  UpkeepWorkflow(this.repository, {required this.clock, IdFactory? idFactory})
    : _idFactory = idFactory ?? _defaultId;

  final UpkeepRepository repository;
  final Clock clock;
  final IdFactory _idFactory;
  final ScheduleEngine _schedule = const ScheduleEngine();

  static int _counter = 0;
  static String _defaultId(String kind) =>
      '$kind-${DateTime.now().toUtc().microsecondsSinceEpoch}-${_counter++}';

  Future<WorkflowSnapshot> load() async => WorkflowSnapshot(
    homes: await repository.homes(),
    rooms: await repository.rooms(),
    assets: await repository.assets(),
    tasks: await repository.tasks(),
    occurrences: await repository.occurrences(),
    completions: await repository.completions(),
    today: clock.today,
  );

  Future<void> saveHome(HomeProfile value) => repository.saveHome(value);
  Future<void> saveRoom(Room value) => repository.saveRoom(value);
  Future<void> saveAsset(Asset value) => repository.saveAsset(value);

  Future<void> createTask(TaskTemplate task) =>
      repository.saveTaskWithOccurrence(
        task,
        TaskOccurrence(
          id: _idFactory('occurrence'),
          taskTemplateId: task.id,
          scheduledDate: task.startDate,
        ),
      );

  Future<void> updateTask(TaskTemplate task) => repository.saveTask(task);

  Future<void> snooze(TaskOccurrence occurrence, LocalDate until) {
    if (occurrence.state != OccurrenceState.pending) {
      throw StateError('Only pending upkeep can be snoozed');
    }
    return repository.saveOccurrence(
      TaskOccurrence(
        id: occurrence.id,
        taskTemplateId: occurrence.taskTemplateId,
        scheduledDate: occurrence.scheduledDate,
        snoozedUntil: until,
      ),
    );
  }

  Future<void> complete({
    required TaskOccurrence occurrence,
    required LocalDate actualDate,
    String? notes,
    String? parts,
    Money? cost,
  }) async {
    if (occurrence.state != OccurrenceState.pending) {
      throw StateError('Only pending upkeep can be completed');
    }
    final TaskTemplate? task = await repository.taskById(
      occurrence.taskTemplateId,
    );
    if (task == null) throw StateError('Task no longer exists');
    final Completion completion = Completion(
      id: _idFactory('completion'),
      occurrenceId: occurrence.id,
      scheduledDate: occurrence.scheduledDate,
      actualDate: actualDate,
      notes: _optional(notes),
      parts: _optional(parts),
      cost: cost,
      revision: 1,
      revisedAtUtc: clock.nowUtc,
    );
    final LocalDate? nextDate = _schedule.nextDue(
      task,
      lastScheduled: occurrence.scheduledDate,
      actualCompletion: actualDate,
    );
    await repository.completeOccurrence(
      completion,
      nextOccurrence: nextDate == null
          ? null
          : TaskOccurrence(
              id: _idFactory('occurrence'),
              taskTemplateId: task.id,
              scheduledDate: nextDate,
            ),
    );
  }

  Future<void> deleteTask(String id) => repository.deleteTask(id);
}

String? _optional(String? value) {
  final String? trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
