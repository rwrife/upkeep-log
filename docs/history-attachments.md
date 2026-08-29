# Asset history and private attachments

Completed work is shown newest-first with stable tie-breakers (actual date,
scheduled date, case-normalized task name, then completion ID). All searching
is on-device and can combine asset, room, task text, inclusive completion date
range, and correction status. Opening an asset from Setup shows the same records
as a chronological asset timeline, including scheduled and actual dates, notes,
parts, cost, and revision time.

Corrections append a completion revision. The completion and scheduled date
identity remain immutable, the current revision is labeled, and each field is
shown beside its previous value. The original revision is never updated or
deleted by correction.

## Attachment privacy and lifecycle

Camera, photo-library, and document selection starts only after **Attach** and a
source choice. Cancel and permission denial leave the completion unchanged.
Android captures full-resolution camera output through a temporary cache file
shared only with the chosen camera app and uses system document intents. iOS uses the camera,
privacy-preserving PHPicker, and system document picker. No broad storage
permission is requested.

Selections are copied into collision-safe paths under `attachments/<home-id>/`
below application-support storage after the completion's home ownership is
validated. Only this relative path, an asserted media type, optional caption, and
lowercase SHA-256 are retained. The external picker path is transient and is
never stored in SQLite. Opening attachment details rechecks existence and the
checksum, reporting available, missing, or corrupt.

Removing attachment metadata deletes its private file only when no other
metadata references that relative path. Explicit per-home cleanup scans only
that home's private attachment directory and removes only files absent from the
complete metadata reference set. Setup displays the bytes currently present for
each home.

The anticipated schema-v2 attachment and revision tables already express these
requirements, so this milestone does not increment the database schema.
