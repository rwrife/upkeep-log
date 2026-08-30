# Local reminder behavior

Upkeep Log reminders are optional, on-device convenience notifications. The persisted task and occurrence records—and the Due, Upcoming, and Completed views derived from them—remain the source of truth. A notification is never treated as proof that upkeep happened, was safe, or was delivered at an exact time.

## Opt-in and permissions

- A task starts with reminders off.
- The app asks for notification authorization only after the user turns on **Enable a local reminder** and saves the task.
- Denial does not block task creation, editing, completion, snooze, history, or any due view.
- The Setup screen reports the latest authorization/scheduling status and links to system notification settings after denial.
- No push service, account, network connection, location, background sensor, or exact-alarm permission is used.

Android declares only `POST_NOTIFICATIONS` for Android 13+ delivery and `RECEIVE_BOOT_COMPLETED` to rebuild user-enabled alarms after reboot. iOS uses `UNUserNotificationCenter`; notification authorization does not require a usage-description key.

## Durable intent and reconciliation

The database stores the requested wall-clock hour, minute, and time-zone identifier on the task. The currently pending occurrence supplies the date. Platform notifications are disposable projections of that local data.

The application replaces its pending notification set from persisted state:

- on app launch and resume;
- after task creation or editing;
- after snooze or completion;
- after task pause, reminder disablement, or deletion.

Only pending occurrences for non-paused tasks with reminder intent are scheduled. Snooze uses the snoozed date. Completion removes the completed occurrence and schedules the next recurring occurrence, if any. This also repairs pending notifications after an interrupted app session.

Android keeps a private copy of the projected schedule solely so `BOOT_COMPLETED`, app replacement, manual clock changes, and time-zone changes can recreate alarms before the next launch. iOS persists pending requests through the system notification center. Neither copy supersedes the SQLite records; the next app reconciliation replaces it.

## Calendar and delivery limits

The native adapters combine the saved local date, wall-clock time, and time-zone identifier. If a platform cannot recognize the stored identifier, it falls back to the device's current zone and reports only best-effort scheduling. During a daylight-saving gap or overlap, the operating system's calendar/time-zone rules choose the valid instant. Opening the app after a zone-rule or device-time change reconciles the schedule again; Android also listens for system time and time-zone broadcasts.

Android uses inexact `setAndAllowWhileIdle` alarms, so battery policy may delay delivery. iOS may delay or suppress notifications according to Focus, notification summary, power, and system policies. Past reminder dates are not newly scheduled; the task remains visible in the app's due list.

## Verification boundaries

Dart tests cover permission gating, denial, persisted-intent reconciliation, snooze, completion, pause, restart behavior, platform-channel payloads, and accessible settings recovery. Android and iOS CI builds compile the native adapters. Actual delivery timing, reboot behavior on specific OEM Android devices, and visual notification presentation require representative-device checks and belong in the release-readiness work tracked by issue #7.
