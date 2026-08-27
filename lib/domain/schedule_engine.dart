import 'clock.dart';
import 'entities.dart';
import 'local_date.dart';
import 'recurrence.dart';

/// Task-aware scheduling entry point.
///
/// This service always carries a task's persisted calendar anchor into the
/// lower-level recurrence calculations, preventing month-end and leap-day
/// drift after an occurrence has been saved and reloaded.
final class ScheduleEngine {
  const ScheduleEngine([this._recurrence = const RecurrenceEngine()]);

  final RecurrenceEngine _recurrence;

  LocalDate? nextDue(
    TaskTemplate task, {
    required LocalDate lastScheduled,
    LocalDate? actualCompletion,
  }) {
    if (task.paused) return null;
    return _recurrence.next(
      task.recurrence,
      lastScheduled,
      actualCompletion: actualCompletion,
      intendedDay: task.recurrenceAnchorDay,
      intendedMonth: task.recurrenceAnchorMonth,
    );
  }

  LocalDate? nextDueAfter(
    TaskTemplate task, {
    required LocalDate lastScheduled,
    required Clock clock,
    LocalDate? actualCompletion,
  }) {
    if (task.paused) return null;
    return _recurrence.nextAfter(
      task.recurrence,
      lastScheduled: lastScheduled,
      today: clock.today,
      actualCompletion: actualCompletion,
      intendedDay: task.recurrenceAnchorDay,
      intendedMonth: task.recurrenceAnchorMonth,
    );
  }

  LocalDate? resume(
    TaskTemplate task, {
    required LocalDate lastScheduled,
    required LocalDate resumedOn,
  }) => _recurrence.resume(
    task.recurrence,
    lastScheduled: lastScheduled,
    resumedOn: resumedOn,
    intendedDay: task.recurrenceAnchorDay,
    intendedMonth: task.recurrenceAnchorMonth,
  );
}
