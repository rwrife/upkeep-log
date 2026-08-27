# Recurrence and date rules

Scheduling is pure Dart and uses `LocalDate`, a Gregorian `YYYY-MM-DD` value
without a time or UTC offset. Widgets must ask application/domain services for
dates; they must not perform date arithmetic.

## Policies and anchors

- One-time has no successor.
- Fixed-day adds an exact positive number of calendar days.
- Weekly adds a positive number of seven-day weeks.
- Monthly advances by calendar months. The original intended day is retained:
  a task starting January 31 is due February 28/29, then March 31.
- Yearly advances by calendar years. February 29 clamps to February 28 in a
  non-leap year and returns to February 29 in the next leap year.

The task template persists that intended calendar day and month explicitly.
Saving and reloading an occurrence therefore cannot turn January 31 → February
28 into a permanent day-28 cadence, and multi-interval rules retain the anchor.
Callers pass `recurrenceAnchorDay` and `recurrenceAnchorMonth` from the template
through the task-aware `ScheduleEngine`; application code does not call the
lower-level recurrence cursor directly. This makes anchor use non-optional
after a database reload.
Actual-completion rules intentionally reset their calendar anchor to the actual
completion (or resume) date and ignore the stored scheduled-date anchor.

Every recurring policy declares one anchor:

- `scheduledDate` (default) calculates from the prior scheduled date. Completing
  early or late does not shift the cadence. If multiple dates were missed,
  carry-forward returns the first scheduled date strictly after today.
- `actualCompletionDate` calculates from the actual completion date. Completing
  early or late shifts the next date, and calculating without an actual date is
  an error.

The completion journal stores both dates. Corrections append sequential,
timestamped revisions; the scheduled date and completion identity cannot be
rewritten. Revision instants are stored as signed Unix microseconds so ordering
and round trips remain exact within a second and on either side of 1970.

## Snooze, pause, reminders, and time zones

Snooze changes an occurrence's visible date only. It never changes its stored
scheduled date or recurrence anchor. While paused, callers create no
occurrences. Resume skips scheduled-anchor dates during the pause and returns
the first date after the resume date. For an `actualCompletionDate` policy,
`resumedOn` becomes a fresh actual/calendar anchor and the next date is one
complete interval after it.

`ReminderIntent` stores a wall-clock hour/minute and IANA-style time-zone
identifier separately. The recurrence engine never converts instants or reads
the device zone, so daylight-saving transitions and travel cannot change a due
date. A later notification adapter is responsible for resolving reminder intent
against platform time-zone rules.

`Clock.today` is likewise supplied as a local `LocalDate`, independently of the
UTC instant. `FakeClock` never guesses a local date without a time-zone database:
tests explicitly update `today` when advancing across a local date boundary.

## Current limitations

- Gregorian calendar only; no business-day, holiday, or locale-specific rules.
- Monthly/yearly policies use clamp-to-month-end, not “last weekday” semantics.
- A pause does not preserve missed occurrences; resume deliberately skips them.
- Time-zone identifier validity and notification delivery are platform-adapter
  concerns. The domain only requires a nonempty identifier.
- Schema version 1 is the baseline. Future versions must add explicit forward
  migration steps and fixtures; downgrade migration is unsupported.
