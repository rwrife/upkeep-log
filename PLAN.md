# Upkeep Log — Implementation Plan

## Scope

The MVP is a local-first Android/iOS app for recurring household maintenance schedules and durable completion history. It supports multiple local home profiles but deliberately excludes accounts, cloud sync, contractor dispatch, predictive maintenance, and safety-critical monitoring.

## Architecture

```text
Flutter presentation
  ├─ Due / Upcoming / Completed
  ├─ Home, room, asset, and task editors
  ├─ Completion and attachment flow
  └─ History, export, restore, privacy settings
          │
Application services
  ├─ ScheduleEngine
  ├─ CompletionService
  ├─ SearchService
  ├─ BackupService
  └─ ReminderCoordinator
          │
Domain model (pure Dart)
          │
Ports / adapters
  ├─ Drift/SQLite repositories
  ├─ app-private attachment store
  ├─ Android/iOS local notifications
  └─ document picker + share sheet
```

The scheduling engine is pure Dart and receives an explicit clock/time-zone context. Presentation code never performs date arithmetic directly. Storage, notifications, and file access are behind interfaces so domain tests run without devices.

## Technology choices

- **Flutter/Dart:** one accessible mobile UI codebase while retaining native notification and file integrations.
- **Drift + SQLite:** typed queries, transactions, migrations, and inspectable local storage.
- **Riverpod:** explicit dependency injection and testable state; avoid global singletons.
- **Freezed/json_serializable (candidate):** immutable versioned transfer models; adoption depends on generated-code maintenance cost during issue #1.
- **JUnit/XCTest-backed Flutter integration tests:** exercise platform adapters where host tooling is available.
- **GitHub Actions:** formatting, static analysis, unit/widget tests, and unsigned debug builds. iOS builds run on macOS workers.

## Data and migration rules

- Internal IDs are UUIDs generated on device.
- Calendar due dates are date-only values; reminder wall-clock time and time-zone behavior are explicit fields.
- Money is stored as minor integer units with ISO currency code; unknown cost stays null.
- Completion records retain scheduled and actual dates. Editing creates revision metadata.
- Attachments use content checksums and app-relative paths, never unrestricted filesystem paths.
- Every database and backup schema has an integer version and tested forward migration.
- Restore imports into staging, validates references/checksums, then swaps in one transaction or leaves existing data untouched.

## Milestones and dependency order

### M1 — Foundation

- Bootstrap Flutter project, lint policy, CI, and architecture boundaries.
- Define domain entities, repositories, migration test harness, and deterministic clock.

### M2 — Scheduling core

- Implement one-time and interval/calendar recurrence policies.
- Persist homes, rooms, assets, tasks, occurrences, and completions.
- Cover early/late completion, snooze, month-end, leap-year, and daylight-saving cases.

### M3 — Primary workflow

- Build accessible Due, Upcoming, and Completed screens.
- Add task/asset editors and transactional completion flow.
- Add permissionless operation before notification or photo features are enabled.

Local reminders are implemented in issue #5 as a disposable projection of persisted
intent. Authorization is requested only after explicit enablement; denial never
blocks the due workflow. See `docs/reminders.md` for lifecycle and platform limits.

### M4 — History and attachments

- Build asset timeline, search, filters, completion corrections, and cost/parts fields.
- Add user-initiated camera/photo/file attachment adapters with app-private copies.

Implemented in issue #4 using the anticipated schema-v2 revision and attachment
tables; see `docs/history-attachments.md` for sorting, privacy, integrity, and
cleanup behavior.

### M5 — Portability and privacy

- Implement CSV history export and versioned ZIP backup/restore.
- Add data deletion, export warnings, permission explanations, and privacy screen.

### M6 — Packaging

- Run Android/iOS build matrix, integration tests, migration fixtures, accessibility checks, and release checklist.
- Produce unsigned development artifacts first; signing and store publication require owner-managed credentials and review.

## Testing strategy

### Unit tests

- Recurrence calculations including end-of-month, leap years, DST boundaries, time-zone changes, early completion, overdue carry-forward, and snooze
- Domain validation and state transitions
- Currency serialization and nullable cost handling
- Backup schema parsing, reference validation, and checksum verification
- Repository behavior against temporary SQLite databases

### Widget tests

- Create/edit task and asset forms
- Due-list grouping and non-color-only state presentation
- Complete/snooze/undo-confirmation flows
- Large text, narrow screens, empty/error states, semantic labels, and focus order

### Integration tests

- Database migrations from committed fixture versions
- App restart persistence
- Notification schedule/cancel adapters on supported emulators or devices
- Attachment import/copy/delete behavior
- Backup → fresh install → restore → semantic equality
- CSV export with escaping, locale-independent dates, and integer money conversion

### Quality gates

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --debug --no-codesign
```

Actual results must be reported from real runs; unavailable host builds are documented rather than inferred.

## Packaging and distribution

- Android: debug APK in CI, then owner-reviewed signed AAB for Play Store or direct distribution.
- iOS: no-code-sign debug build in CI, then owner-managed signing, TestFlight, and App Store review.
- Releases include schema/migration notes, checksums for distributable files, privacy disclosure, export compatibility notes, and a tested restore fixture.
- No telemetry or crash-report SDK is bundled by default.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Recurrence drift after early/late completion | Specify anchor semantics per cadence and test boundary cases with a fake clock. |
| OS notification throttling or permission denial | Core due list remains complete without notifications; show delivery limitations. |
| Data loss during restore or migration | Validate in staging, transact atomically, preserve pre-restore backup, and test fixtures. |
| Attachment storage growth | Show per-home size, optional compression policy, and explicit cleanup with references checked. |
| Platform accessibility regressions | Add semantic widget tests and manual TalkBack/VoiceOver checklist per release. |
| Scope creep into property management | Keep one-device household journal boundaries and reject accounts, payments, and dispatch. |
| Users treat reminders as safety guarantees | State that reminders are convenience aids and not code-compliance, emergency, or equipment-safety monitoring. |

## Explicit non-goals

- Hosted sync, accounts, subscriptions, ads, or analytics
- Contractor marketplace, tenant/landlord case management, payments, inventory purchasing, or warranty decisions
- Smart-home device control or automatic equipment diagnosis
- Emergency, fire, gas, flooding, structural, or life-safety monitoring
- Desktop/web clients and real-time collaboration in the MVP
- OCR, AI-generated schedules, or manufacturer-database scraping in the MVP
