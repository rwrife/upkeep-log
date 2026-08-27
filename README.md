# Upkeep Log

> Local-first mobile app for homeowners and renters to schedule household upkeep, record completed work and costs, and export a portable maintenance history without accounts.

## Overview

Upkeep Log is an offline-first household maintenance journal for Android and iOS. It keeps recurring tasks, appliance and fixture records, completion notes, costs, and optional photos together so a person can answer: **what needs attention, what was done, and when?**

The app is for routine ownership and tenancy workflows—not contractor dispatch, property-management billing, or safety monitoring.

## Motivation

Household upkeep is commonly scattered across calendar events, paper receipts, appliance manuals, and memory. Generic task apps can remind someone, but they rarely preserve a useful service history tied to the exact asset or room. Upkeep Log combines a lightweight schedule with an append-only completion journal and portable exports.

## Target users

- Homeowners maintaining appliances, fixtures, filters, finishes, and seasonal equipment
- Renters tracking work they performed or reported, without sharing data with a service
- Small households coordinating recurring upkeep on one device or through exported files
- People preparing a concise maintenance history for a repair visit, move, or sale

## Concrete use cases

- Add an HVAC filter task every 90 days and record the size and replacement date.
- Track descaling, cleaning, battery replacement, lubrication, inspection, and seasonal storage tasks.
- Open an appliance record to see prior work, notes, parts used, and costs.
- Mark a task complete early or late while retaining both the scheduled and actual dates.
- Export one asset's history as CSV or back up the full local database and attachments as a versioned ZIP.

## Intended workflow

1. Create a home profile and optional rooms.
2. Add an asset or a free-standing household task.
3. Choose a one-time or recurring cadence and an optional local reminder.
4. Review **Due**, **Upcoming**, and **Completed** lists.
5. Complete a task with notes, cost, parts, and optional photos or receipt images.
6. Browse immutable history; corrections create an auditable edit record rather than silently erasing work.
7. Export selected history or create a full backup whenever desired.

## MVP features

- One or more local home profiles, rooms, and assets
- One-time and recurring maintenance tasks with deterministic next-due calculations
- Due, overdue, upcoming, snoozed, and completed views
- Completion journal with notes, cost, parts, and optional attachments
- Asset-level timeline and simple local search/filtering
- Optional on-device notifications
- Versioned JSON/ZIP backup and restore; CSV history export
- Dark mode, scalable text, screen-reader labels, keyboard/switch-friendly focus order, and non-color-only status cues

## Non-goals

- Cloud accounts, hosted synchronization, advertising, or subscriptions
- Contractor marketplace, work-order dispatch, payments, or warranty adjudication
- Building-code compliance, emergency alerts, predictive failure detection, or claims that a task makes equipment safe
- Automatic access to contacts, location, calendars, email, or smart-home devices
- Shared real-time household editing in the MVP

## Privacy, permissions, and data ownership

- All structured data is stored in an app-private SQLite database on the device.
- Attachments remain in app-private storage and are never uploaded by Upkeep Log.
- No account, analytics SDK, ad SDK, or network connection is required for core use.
- Notification permission is requested only when the user enables reminders.
- Camera or photo-library access is requested only when the user chooses to attach an image; file import remains an alternative.
- Location, contacts, microphone, Bluetooth, and background sensor permissions are not used.
- Users can export a readable CSV history and a versioned ZIP backup containing JSON plus attachments. Restore validates the archive before modifying local data.
- Deleting a home profile requires explicit confirmation and offers a backup first.

Exports may contain addresses, notes, costs, serial numbers, and photos; the app warns users to review files before sharing.

## Platforms and technology

- **Framework:** Flutter (Dart) for a shared Android/iOS codebase
- **Targets:** Android 10+ and iOS 16+ for the initial release
- **Persistence:** Drift over SQLite with explicit schema migrations
- **State/navigation:** Riverpod and declarative routing, isolated behind domain interfaces
- **Notifications:** platform local-notification adapters; no push service
- **Files:** platform document picker/share sheet for user-directed import/export

## Local data model

The initial domain model is:

- `HomeProfile` → optional address label and settings
- `Room` → organizational grouping
- `Asset` → appliance, fixture, surface, or equipment record
- `TaskTemplate` → title, cadence, lead time, instructions, linked asset/room
- `TaskOccurrence` → calculated due date, state, snooze, and completion link
- `Completion` → actual date, notes, cost, parts, and revision metadata
- `Attachment` → app-private file reference, media type, checksum, and caption

Monetary values use integer minor units plus currency code. Dates and local-time reminder intent are stored separately so travel and daylight-saving changes do not corrupt due dates.

## Accessibility expectations

The MVP must work with TalkBack and VoiceOver, support dynamic text without clipping, meet platform touch-target guidance, expose logical traversal order, and pair every status color with text/iconography. Motion is minimal and respects reduced-motion settings. Destructive and bulk actions require clear confirmation.

## Current status

**Flutter foundation scaffold.** The repository now pins Flutter 3.47.1 and
contains Android/iOS projects, a truthful local-first empty state, strict
analysis, smoke/semantics tests, architecture import rules, vulnerability/license
inventory, and CI quality/platform build jobs. Domain scheduling, persistence,
and user workflows remain backlog work; no signed package or store release is
claimed.

### Milestones

1. Reproducible Flutter skeleton and CI — scaffolded; CI is the platform-build gate
2. Tested local domain and scheduling engine
3. Accessible due/completion workflow
4. Asset history, search, and attachments
5. Backup/restore, CSV export, and privacy controls
6. Platform builds and release-readiness checks

## Development quickstart

Use the pinned Flutter **3.47.1** stable SDK (Dart 3.13.1). Android development
requires Java 17 and an Android SDK; iOS builds require macOS and Xcode.

```bash
flutter --version
flutter doctor -v
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
dart run tool/check_dependency_licenses.dart --output build/reports/dependency-licenses.txt
flutter run
```

See [bootstrap and verification](docs/bootstrap.md) for platform build commands
and host limitations, and [architecture boundaries](docs/architecture.md) for
the enforced dependency rules.

## License

MIT. See [LICENSE](LICENSE).
