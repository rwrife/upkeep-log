# Architecture boundaries

Upkeep Log uses inward-pointing dependencies so household schedule and history
rules remain testable without widgets, plugins, devices, or network access.

```text
presentation  ---> application ---> domain
                         ^             ^
                         |             |
                     adapters ---------+
```

`lib/main.dart` is the composition root. It may construct adapters and inject
them into application services before starting presentation code.

`UpkeepWorkflow` is the application facade for setup, snooze, completion, and
snapshot loading. Completion delegates one atomic unit of work to the repository
so the completion revision, occurrence state, and next occurrence cannot split.
`AttachmentService` validates ownership and coordinates metadata through an
`AttachmentStore` port. The concrete private-file adapter owns copying,
checksums, inspection, storage totals, and reference-safe cleanup. Native picker
paths cross these boundaries only long enough to copy the selected bytes and
are never persisted.

## Layer rules

- **Domain** is pure Dart. It owns entities, value objects, invariants,
  recurrence policies, and date-only calculations. It receives explicit clocks
  and time-zone context and never imports Flutter or plugins.
- **Application** owns use cases and ports. It may import domain code, but never
  concrete adapters or presentation code.
- **Adapters** implement application ports for Drift/SQLite, app-private files,
  local notifications, and user-directed document APIs. They never import
  presentation code.
- **Presentation** renders application state and collects user intent. It does
  not import concrete adapters and must not calculate schedules or mutate the
  database directly.

`test/architecture/dependency_rules_test.dart` enforces these import directions.
The currently empty application and adapter directories contain boundary notes;
real implementations will be added only with the issues that define their
behavior.

## Privacy and platform constraints

Core behavior is local and permissionless. Network, accounts, analytics, ads,
contacts, location, microphone, Bluetooth, and background sensors are outside
the MVP. Notification, camera, photo, and file permissions may be requested only
following an explicit user action and must degrade gracefully when denied.
