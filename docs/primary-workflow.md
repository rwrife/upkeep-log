# Accessible due-to-completion workflow

Upkeep Log's primary workflow is local and permissionless. The composition root
opens `upkeep-log.sqlite` in application-support storage, injects the Drift
repository into `UpkeepWorkflow`, and never requires an account or network
connection.

Android and iOS expose only their app-private support directory through the
`upkeep_log/storage` platform channel. This needs no broad file permission and
adds no third-party storage plugin or network behavior.

## User flow

1. Create or edit a local home profile.
2. Optionally add rooms and assets.
3. Create a one-time, day, week, month, or year recurrence. The first due
   occurrence is committed atomically with the task.
4. Review text-and-icon status in **Due** (including overdue and snoozed),
   **Upcoming**, and **Completed**.
5. Complete an occurrence with its actual date, notes, parts, and optional
   integer-minor-unit cost, or schedule a snooze with a four-second undo window.
6. Completion, state transition, and the next recurring occurrence commit in a
   single SQLite transaction. A failure leaves the prior local state unchanged.

The domain `classifyOccurrence` function owns status bucketing and
`ScheduleEngine` owns every next-date calculation. Presentation code does not
perform schedule arithmetic.

## Accessibility and failure behavior

- Status always includes text and an icon; color is not the only signal.
- Task cards expose a combined screen-reader label with name, status, scheduled
  date, and action-specific button labels.
- Material controls preserve platform touch targets and logical source-order
  focus. Lists and forms scroll at large text sizes and on narrow screens.
- Forms validate before dismissal. Edited single-field and home forms confirm
  before discarding changes.
- Failed saves retain the exact operation and entered values behind a visible
  **Retry save** action. The database transaction leaves durable data unchanged.
- Motion is limited to platform components, which honor the platform's disable-
  animations accessibility setting.

## Schema migration

Schema version 2 adds nullable `parts_text` to completion revisions. Opening a
version-1 database migrates in place; existing revision history remains valid
with a null parts value. Migration tests compare all unaffected schema objects
and the resulting column set with a fresh version-2 database.