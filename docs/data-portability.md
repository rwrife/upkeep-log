# Data portability and compatibility

## Versioned formats

Backup schema `1` is a UTF-8 ZIP with exactly `manifest.json`, `data.json`, and
the attachment paths referenced by `data.json`. The manifest identifies
`upkeep-log-backup`, records `schemaVersion`, a UTC `generatedAtUtc`, entity
counts, and a lowercase SHA-256 for every entry except the manifest itself.
`data.json` contains every home, room, asset, task, occurrence, completion
revision, and attachment metadata row. IDs are stable opaque strings. Due,
scheduled, snoozed, start, and actual dates are `YYYY-MM-DD` date-only values.
Revision metadata is an ISO-8601 UTC instant ending in `Z`. Costs are signed
integer minor units paired with a three-letter uppercase currency code.
Reminder intent preserves local hour/minute and IANA time-zone ID.

CSV schema `1` has this deterministic header: `schema_version,home_id,home_name,
home_address,room_id,room_name,asset_id,asset_name,task_id,task_name,
occurrence_id,scheduled_date,snoozed_until,occurrence_state,completion_id,
actual_date,notes,parts,cost_minor_units,cost_currency,revision,revised_at_utc`.
It uses UTF-8, comma separators, CRLF records, and RFC 4180
double-quote escaping. Rows are deterministic and include stable home, room,
asset, task, occurrence, and completion IDs; scheduled/actual dates; occurrence
state and snooze; notes, parts, cost/currency; and correction revision/UTC
metadata. A selected home or asset is a filter, not a rewritten identity.

## Restore safety

Restore rejects unsupported future versions rather than guessing. Version 1 is
the current compatibility floor; a future reader may add explicit migrations
for older versions, while a current reader never interprets a newer schema.
Before import, the app creates and validates a local pre-restore recovery copy
and offers that file through the system share sheet. Restore verifies that the
offered archive still semantically matches the current database and attachment
snapshot; if data changed while the picker was open, restore rejects the stale
copy and asks the user to export a new one. iOS reports share-sheet
cancellation; Android can only report that the local source file was prepared
and that the share interaction returned, not that a receiving app retained it.
Users who want a copy outside Upkeep Log must explicitly save it. Restore rejects
invalid UTF-8/JSON, missing and cross-home references, duplicate IDs or archive
entries, unsafe absolute/drive/traversal paths, inconsistent completion history,
unreferenced files, checksum failures, more than 2,048 entries, entries over 64
MiB, archives over 256 MiB, or more than 512 MiB total uncompressed data.

Validated attachments are written to a private staging directory. The live
attachment directory is moved aside, staged files are installed, and structured
data is replaced in one database transaction. A database/import failure restores
the previous files; validation and staging failures never modify live data.
Conflicting home IDs are counted and reported because restore is an intentional
full replacement, not an inferred merge.

Exports may expose private addresses, serial numbers embedded in names or notes,
costs, notes, and photos. The app displays this warning before backup export.
File access is user-directed through the system share sheet/document picker and
does not request broad storage permission or use a network service.

CSV text comes from user-owned fields and is exported losslessly. Treat it as
untrusted data when opening it in spreadsheet software: a cell beginning with
`=`, `+`, `-`, or `@` may be interpreted as a formula by some spreadsheet apps.

## Concurrency boundary

The application composition root injects one `ApplicationMutationGate` into
both `AttachmentService` and `DataPortabilityService`. Attachment publication,
removal and cleanup therefore cannot interleave with backup/CSV snapshots,
restore, per-home deletion, reset, or storage measurement. Tests or alternate
composition roots that construct the services independently must inject the
same gate to retain this cross-service guarantee; the repository itself is not
a filesystem transaction coordinator.
