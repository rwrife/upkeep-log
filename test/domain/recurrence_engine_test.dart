import 'package:flutter_test/flutter_test.dart';
import 'package:upkeep_log/domain/domain.dart';

void main() {
  const RecurrenceEngine engine = RecurrenceEngine();

  test('supports one-time, fixed-day, and weekly policies', () {
    final LocalDate date = LocalDate(2026, 1, 5);
    expect(engine.next(const OneTimeRecurrence(), date), isNull);
    expect(engine.next(FixedDayRecurrence(10), date), LocalDate(2026, 1, 15));
    expect(
      engine.next(WeeklyRecurrence(intervalWeeks: 2), date),
      LocalDate(2026, 1, 19),
    );
  });

  test(
    'scheduled and actual anchors handle early and late completion explicitly',
    () {
      final LocalDate scheduled = LocalDate(2026, 4, 10);
      final LocalDate early = LocalDate(2026, 4, 8);
      final LocalDate late = LocalDate(2026, 4, 15);
      expect(
        engine.next(FixedDayRecurrence(30), scheduled, actualCompletion: early),
        LocalDate(2026, 5, 10),
      );
      expect(
        engine.next(
          FixedDayRecurrence(30, anchor: RecurrenceAnchor.actualCompletionDate),
          scheduled,
          actualCompletion: early,
        ),
        LocalDate(2026, 5, 8),
      );
      expect(
        engine.next(
          FixedDayRecurrence(30, anchor: RecurrenceAnchor.actualCompletionDate),
          scheduled,
          actualCompletion: late,
        ),
        LocalDate(2026, 5, 15),
      );
      expect(
        () => engine.next(
          FixedDayRecurrence(30, anchor: RecurrenceAnchor.actualCompletionDate),
          scheduled,
        ),
        throwsArgumentError,
      );
    },
  );

  test('monthly preserves intended day and clamps month-end without drift', () {
    final RecurrenceCursor cursor = engine.cursor(
      MonthlyRecurrence(),
      LocalDate(2024, 1, 31),
    );
    expect(cursor.advance().date, LocalDate(2024, 2, 29));
    expect(cursor.advance().date, LocalDate(2024, 3, 31));
    expect(cursor.advance().date, LocalDate(2024, 4, 30));
  });

  test('yearly leap day clamps then returns to leap day', () {
    final RecurrenceCursor cursor = engine.cursor(
      YearlyRecurrence(),
      LocalDate(2024, 2, 29),
    );
    expect(cursor.advance().date, LocalDate(2025, 2, 28));
    expect(cursor.advance().date, LocalDate(2026, 2, 28));
    expect(cursor.advance().date, LocalDate(2027, 2, 28));
    expect(cursor.advance().date, LocalDate(2028, 2, 29));
  });

  test('persisted calendar anchors survive clamped occurrence boundaries', () {
    final RecurrenceCursor monthly = engine.cursor(
      MonthlyRecurrence(intervalMonths: 1),
      LocalDate(2024, 2, 29),
      intendedDay: 31,
      intendedMonth: 1,
    );
    expect(monthly.advance().date, LocalDate(2024, 3, 31));
    final RecurrenceCursor multiYear = engine.cursor(
      YearlyRecurrence(intervalYears: 2),
      LocalDate(2026, 2, 28),
      intendedDay: 29,
      intendedMonth: 2,
    );
    expect(multiYear.advance().date, LocalDate(2028, 2, 29));

    expect(
      engine.next(
        MonthlyRecurrence(),
        LocalDate(2024, 2, 29),
        intendedDay: 31,
        intendedMonth: 1,
      ),
      LocalDate(2024, 3, 31),
    );
    expect(
      engine.nextAfter(
        YearlyRecurrence(),
        lastScheduled: LocalDate(2027, 2, 28),
        today: LocalDate(2027, 3, 1),
        intendedDay: 29,
        intendedMonth: 2,
      ),
      LocalDate(2028, 2, 29),
    );
  });

  test('task-aware scheduling always consumes persisted calendar anchors', () {
    final TaskTemplate monthly = TaskTemplate(
      id: 'monthly',
      homeId: 'home',
      name: 'Month end',
      startDate: LocalDate(2024, 1, 31),
      recurrence: MonthlyRecurrence(),
    );
    const ScheduleEngine schedule = ScheduleEngine();

    expect(
      schedule.nextDue(monthly, lastScheduled: LocalDate(2024, 2, 29)),
      LocalDate(2024, 3, 31),
    );
    expect(
      schedule.nextDueAfter(
        monthly,
        lastScheduled: LocalDate(2024, 2, 29),
        clock: FakeClock(
          DateTime.utc(2024, 4, 1),
          today: LocalDate(2024, 4, 1),
          timeZoneId: 'UTC',
        ),
      ),
      LocalDate(2024, 4, 30),
    );
    expect(
      schedule.resume(
        monthly,
        lastScheduled: LocalDate(2024, 2, 29),
        resumedOn: LocalDate(2024, 4, 1),
      ),
      LocalDate(2024, 4, 30),
    );
    final TaskTemplate paused = TaskTemplate(
      id: 'paused',
      homeId: 'home',
      name: 'Paused task',
      startDate: LocalDate(2024, 1, 31),
      recurrence: MonthlyRecurrence(),
      paused: true,
    );
    expect(
      schedule.nextDue(paused, lastScheduled: LocalDate(2024, 2, 29)),
      isNull,
    );
  });

  test('recurrence intervals are validated at runtime', () {
    expect(() => FixedDayRecurrence(0), throwsArgumentError);
    expect(() => WeeklyRecurrence(intervalWeeks: -1), throwsArgumentError);
    expect(() => MonthlyRecurrence(intervalMonths: 0), throwsArgumentError);
    expect(() => YearlyRecurrence(intervalYears: -2), throwsArgumentError);
  });

  test('overdue carry-forward advances scheduled anchor beyond today', () {
    expect(
      engine.nextAfter(
        MonthlyRecurrence(),
        lastScheduled: LocalDate(2026, 1, 31),
        today: LocalDate(2026, 4, 15),
      ),
      LocalDate(2026, 4, 30),
    );
  });

  test(
    'snooze changes visibility only and pause/resume skips paused dates',
    () {
      final TaskOccurrence occurrence = TaskOccurrence(
        id: 'o',
        taskTemplateId: 't',
        scheduledDate: LocalDate(2026, 3, 1),
        snoozedUntil: LocalDate(2026, 3, 8),
      );
      expect(occurrence.visibleDate, LocalDate(2026, 3, 8));
      expect(
        engine.next(WeeklyRecurrence(), occurrence.scheduledDate),
        LocalDate(2026, 3, 8),
      );
      expect(
        engine.resume(
          WeeklyRecurrence(),
          lastScheduled: LocalDate(2026, 3, 1),
          resumedOn: LocalDate(2026, 3, 20),
        ),
        LocalDate(2026, 3, 22),
      );
    },
  );

  test(
    'FakeClock is injectable and time-zone/DST instants cannot alter dates',
    () {
      final FakeClock beforeDst = FakeClock(
        DateTime.parse('2026-03-08T01:30:00-05:00'),
        today: LocalDate(2026, 3, 8),
        timeZoneId: 'America/New_York',
      );
      final FakeClock afterTravel = FakeClock(
        DateTime.parse('2026-03-08T23:30:00+09:00'),
        today: LocalDate(2026, 3, 8),
        timeZoneId: 'Asia/Tokyo',
      );
      expect(beforeDst.today, LocalDate(2026, 3, 8));
      expect(afterTravel.today, LocalDate(2026, 3, 8));
      expect(
        engine.next(WeeklyRecurrence(), beforeDst.today),
        engine.next(WeeklyRecurrence(), afterTravel.today),
      );
      beforeDst.advance(const Duration(days: 1));
      expect(beforeDst.nowUtc.isUtc, isTrue);
    },
  );

  test('actual-anchor resume starts a fresh cadence at resumedOn', () {
    final LocalDate resumed = LocalDate(2028, 2, 29);
    expect(
      engine.resume(
        const OneTimeRecurrence(),
        lastScheduled: LocalDate(2020, 1, 1),
        resumedOn: resumed,
      ),
      isNull,
    );
    expect(
      engine.resume(
        FixedDayRecurrence(2, anchor: RecurrenceAnchor.actualCompletionDate),
        lastScheduled: LocalDate(2020, 1, 1),
        resumedOn: resumed,
      ),
      LocalDate(2028, 3, 2),
    );
    expect(
      engine.resume(
        WeeklyRecurrence(
          intervalWeeks: 2,
          anchor: RecurrenceAnchor.actualCompletionDate,
        ),
        lastScheduled: LocalDate(2020, 1, 1),
        resumedOn: resumed,
      ),
      LocalDate(2028, 3, 14),
    );
    expect(
      engine.resume(
        MonthlyRecurrence(anchor: RecurrenceAnchor.actualCompletionDate),
        lastScheduled: LocalDate(2020, 1, 1),
        resumedOn: LocalDate(2026, 1, 31),
      ),
      LocalDate(2026, 2, 28),
    );
    expect(
      engine.resume(
        YearlyRecurrence(anchor: RecurrenceAnchor.actualCompletionDate),
        lastScheduled: LocalDate(2020, 1, 1),
        resumedOn: resumed,
      ),
      LocalDate(2029, 2, 28),
    );
  });

  test('FakeClock stores local date independently from instant and travel', () {
    final FakeClock clock = FakeClock(
      DateTime.utc(2026, 3, 8, 4, 30),
      today: LocalDate(2026, 3, 7),
      timeZoneId: 'America/New_York',
    );
    expect(clock.today, LocalDate(2026, 3, 7));
    clock.set(
      nowUtc: DateTime.utc(2026, 3, 8, 15),
      today: LocalDate(2026, 3, 9),
      timeZoneId: 'Asia/Tokyo',
    );
    expect(clock.today, LocalDate(2026, 3, 9));
    expect(clock.timeZoneId, 'Asia/Tokyo');
    clock.set(
      nowUtc: DateTime.utc(2026, 11, 1, 5, 30),
      today: LocalDate(2026, 11, 1),
      timeZoneId: 'America/New_York',
    );
    clock.advance(const Duration(hours: 1));
    expect(clock.today, LocalDate(2026, 11, 1));
    expect(clock.nowUtc, DateTime.utc(2026, 11, 1, 6, 30));
    clock.advance(const Duration(days: 1), today: LocalDate(2026, 11, 2));
    expect(clock.today, LocalDate(2026, 11, 2));
  });
}
