import 'entities.dart';
import 'local_date.dart';

/// User-facing schedule buckets. Classification lives in the domain so the UI
/// never reimplements date or snooze rules.
enum OccurrenceBucket { overdue, due, upcoming, snoozed, completed }

OccurrenceBucket classifyOccurrence(
  TaskOccurrence occurrence,
  LocalDate today,
) {
  if (occurrence.state == OccurrenceState.completed) {
    return OccurrenceBucket.completed;
  }
  if (occurrence.snoozedUntil != null && occurrence.snoozedUntil! > today) {
    return OccurrenceBucket.snoozed;
  }
  if (occurrence.visibleDate < today) return OccurrenceBucket.overdue;
  if (occurrence.visibleDate == today) return OccurrenceBucket.due;
  return OccurrenceBucket.upcoming;
}
