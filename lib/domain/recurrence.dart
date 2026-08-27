import 'local_date.dart';

enum RecurrenceAnchor { scheduledDate, actualCompletionDate }

sealed class RecurrencePolicy {
  const RecurrencePolicy({this.anchor = RecurrenceAnchor.scheduledDate});
  final RecurrenceAnchor anchor;
}

final class OneTimeRecurrence extends RecurrencePolicy {
  const OneTimeRecurrence();
}

final class FixedDayRecurrence extends RecurrencePolicy {
  FixedDayRecurrence(this.days, {super.anchor}) {
    _positive(days, 'days');
  }
  final int days;
}

final class WeeklyRecurrence extends RecurrencePolicy {
  WeeklyRecurrence({this.intervalWeeks = 1, super.anchor}) {
    _positive(intervalWeeks, 'intervalWeeks');
  }
  final int intervalWeeks;
}

final class MonthlyRecurrence extends RecurrencePolicy {
  MonthlyRecurrence({this.intervalMonths = 1, super.anchor}) {
    _positive(intervalMonths, 'intervalMonths');
  }
  final int intervalMonths;
}

final class YearlyRecurrence extends RecurrencePolicy {
  YearlyRecurrence({this.intervalYears = 1, super.anchor}) {
    _positive(intervalYears, 'intervalYears');
  }
  final int intervalYears;
}

/// Pure deterministic recurrence calculations over date-only values.
final class RecurrenceEngine {
  const RecurrenceEngine();

  LocalDate? next(
    RecurrencePolicy policy,
    LocalDate scheduled, {
    LocalDate? actualCompletion,
    int? intendedDay,
    int? intendedMonth,
  }) {
    if (policy is OneTimeRecurrence) return null;
    final LocalDate anchor = switch (policy.anchor) {
      RecurrenceAnchor.scheduledDate => scheduled,
      RecurrenceAnchor.actualCompletionDate =>
        actualCompletion ??
            (throw ArgumentError(
              'Actual completion date required for actual anchor',
            )),
    };
    return cursor(
      policy,
      anchor,
      intendedDay: policy.anchor == RecurrenceAnchor.scheduledDate
          ? intendedDay
          : null,
      intendedMonth: policy.anchor == RecurrenceAnchor.scheduledDate
          ? intendedMonth
          : null,
    ).advance().date;
  }

  RecurrenceCursor cursor(
    RecurrencePolicy policy,
    LocalDate anchor, {
    int? intendedDay,
    int? intendedMonth,
  }) => RecurrenceCursor._(
    policy,
    anchor,
    intendedDay ?? anchor.day,
    intendedMonth ?? anchor.month,
  );

  LocalDate? nextAfter(
    RecurrencePolicy policy, {
    required LocalDate lastScheduled,
    required LocalDate today,
    LocalDate? actualCompletion,
    int? intendedDay,
    int? intendedMonth,
  }) {
    if (policy is OneTimeRecurrence) return null;
    if (policy.anchor == RecurrenceAnchor.actualCompletionDate) {
      return next(policy, lastScheduled, actualCompletion: actualCompletion);
    }
    final RecurrenceCursor value = cursor(
      policy,
      lastScheduled,
      intendedDay: intendedDay,
      intendedMonth: intendedMonth,
    );
    do {
      value.advance();
    } while (value.date <= today);
    return value.date;
  }

  LocalDate? resume(
    RecurrencePolicy policy, {
    required LocalDate lastScheduled,
    required LocalDate resumedOn,
    int? intendedDay,
    int? intendedMonth,
  }) => policy.anchor == RecurrenceAnchor.actualCompletionDate
      ? next(policy, resumedOn, actualCompletion: resumedOn)
      : nextAfter(
          policy,
          lastScheduled: lastScheduled,
          today: resumedOn,
          intendedDay: intendedDay,
          intendedMonth: intendedMonth,
        );
}

void _positive(int value, String name) {
  if (value <= 0) {
    throw ArgumentError.value(value, name, 'Must be positive');
  }
}

/// Iterator retaining the intended calendar day across shorter months.
final class RecurrenceCursor {
  RecurrenceCursor._(
    this.policy,
    this.date,
    this._intendedDay,
    this._intendedMonth,
  );
  final RecurrencePolicy policy;
  LocalDate date;
  final int _intendedDay;
  final int _intendedMonth;

  RecurrenceCursor advance() {
    date = switch (policy) {
      OneTimeRecurrence() => date,
      FixedDayRecurrence(:final days) => date.addDays(days),
      WeeklyRecurrence(:final intervalWeeks) => date.addDays(intervalWeeks * 7),
      MonthlyRecurrence(:final intervalMonths) => _addMonths(
        date,
        intervalMonths,
        _intendedDay,
      ),
      YearlyRecurrence(:final intervalYears) => _addYears(
        date,
        intervalYears,
        _intendedMonth,
        _intendedDay,
      ),
    };
    return this;
  }
}

LocalDate _addMonths(LocalDate value, int months, int intendedDay) {
  final int zeroBased = value.year * 12 + value.month - 1 + months;
  final int year = zeroBased ~/ 12;
  final int month = zeroBased % 12 + 1;
  return LocalDate(
    year,
    month,
    intendedDay.clamp(1, _daysInMonth(year, month)),
  );
}

LocalDate _addYears(LocalDate value, int years, int month, int intendedDay) {
  final int year = value.year + years;
  return LocalDate(
    year,
    month,
    intendedDay.clamp(1, _daysInMonth(year, month)),
  );
}

int _daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;
