PRAGMA foreign_keys = ON;
CREATE TABLE homes (id TEXT NOT NULL, name TEXT NOT NULL, address_label TEXT NULL, PRIMARY KEY(id));
CREATE TABLE rooms (id TEXT NOT NULL, home_id TEXT NOT NULL REFERENCES homes(id) ON DELETE CASCADE, name TEXT NOT NULL, PRIMARY KEY(id), UNIQUE(id, home_id));
CREATE TABLE assets (id TEXT NOT NULL, home_id TEXT NOT NULL REFERENCES homes(id) ON DELETE CASCADE, room_id TEXT NULL, name TEXT NOT NULL, PRIMARY KEY(id), UNIQUE(id, home_id), FOREIGN KEY(room_id, home_id) REFERENCES rooms(id, home_id) ON DELETE RESTRICT);
CREATE TABLE task_templates (
 id TEXT NOT NULL, home_id TEXT NOT NULL REFERENCES homes(id) ON DELETE CASCADE, room_id TEXT NULL, asset_id TEXT NULL, name TEXT NOT NULL,
 start_date TEXT NOT NULL, recurrence_kind TEXT NOT NULL, recurrence_interval INTEGER NOT NULL, recurrence_anchor TEXT NOT NULL,
 recurrence_anchor_day INTEGER NOT NULL, recurrence_anchor_month INTEGER NOT NULL,
 reminder_hour INTEGER NULL, reminder_minute INTEGER NULL, reminder_time_zone TEXT NULL, paused INTEGER NOT NULL DEFAULT 0 CHECK (paused IN (0, 1)), PRIMARY KEY(id),
 CHECK(length(start_date)=10 AND date(start_date)=start_date), CHECK(recurrence_kind IN ('oneTime','fixedDay','weekly','monthly','yearly')),
 CHECK(recurrence_interval > 0), CHECK(recurrence_anchor IN ('scheduledDate','actualCompletionDate')),
 CHECK(recurrence_anchor_day BETWEEN 1 AND 31), CHECK(recurrence_anchor_month BETWEEN 1 AND 12), CHECK(date(printf('2024-%02d-%02d', recurrence_anchor_month, recurrence_anchor_day)) = printf('2024-%02d-%02d', recurrence_anchor_month, recurrence_anchor_day)), CHECK(recurrence_kind != 'oneTime' OR (recurrence_interval = 1 AND recurrence_anchor = 'scheduledDate')),
 CHECK((reminder_hour IS NULL AND reminder_minute IS NULL AND reminder_time_zone IS NULL) OR (reminder_hour IS NOT NULL AND reminder_minute IS NOT NULL AND reminder_time_zone IS NOT NULL AND reminder_hour BETWEEN 0 AND 23 AND reminder_minute BETWEEN 0 AND 59 AND length(trim(reminder_time_zone)) > 0)),
 FOREIGN KEY(room_id, home_id) REFERENCES rooms(id, home_id) ON DELETE RESTRICT,
 FOREIGN KEY(asset_id, home_id) REFERENCES assets(id, home_id) ON DELETE RESTRICT);
CREATE TABLE task_occurrences (id TEXT NOT NULL, task_template_id TEXT NOT NULL REFERENCES task_templates(id) ON DELETE CASCADE, scheduled_date TEXT NOT NULL, snoozed_until TEXT NULL, state TEXT NOT NULL, PRIMARY KEY(id), CHECK(length(scheduled_date)=10 AND date(scheduled_date)=scheduled_date), CHECK(snoozed_until IS NULL OR (length(snoozed_until)=10 AND date(snoozed_until)=snoozed_until AND snoozed_until >= scheduled_date)), CHECK(state IN ('pending','completed')));
CREATE TABLE completions (id TEXT NOT NULL, occurrence_id TEXT NOT NULL UNIQUE REFERENCES task_occurrences(id) ON DELETE CASCADE, scheduled_date TEXT NOT NULL, PRIMARY KEY(id), CHECK(length(scheduled_date)=10 AND date(scheduled_date)=scheduled_date));
CREATE TABLE completion_revisions (completion_id TEXT NOT NULL REFERENCES completions(id) ON DELETE CASCADE, revision INTEGER NOT NULL, actual_date TEXT NOT NULL, notes TEXT NULL, cost_minor_units INTEGER NULL, cost_currency TEXT NULL, revised_at_utc INTEGER NOT NULL, PRIMARY KEY (completion_id, revision), CHECK(revision > 0), CHECK(length(actual_date)=10 AND date(actual_date)=actual_date), CHECK((cost_minor_units IS NULL AND cost_currency IS NULL) OR (cost_minor_units IS NOT NULL AND cost_currency IS NOT NULL AND cost_currency GLOB '[A-Z][A-Z][A-Z]' AND length(cost_currency)=3)));
CREATE TABLE attachment_metadata_rows (id TEXT NOT NULL, completion_id TEXT NOT NULL REFERENCES completions(id) ON DELETE CASCADE, relative_path TEXT NOT NULL, media_type TEXT NOT NULL, sha256 TEXT NOT NULL, caption TEXT NULL, PRIMARY KEY(id), CHECK(length(relative_path)>0 AND substr(relative_path,1,1) NOT IN ('/','\') AND relative_path NOT GLOB '[A-Za-z]:*' AND relative_path NOT LIKE '../%' AND relative_path NOT LIKE '%/../%' AND relative_path NOT LIKE '%/..' AND relative_path NOT LIKE '..\%' AND relative_path NOT LIKE '%\..\%' AND relative_path NOT LIKE '%\..'), CHECK(length(media_type)>0), CHECK(length(sha256)=64 AND sha256 NOT GLOB '*[^0-9a-f]*'));
CREATE TRIGGER completion_insert_guard BEFORE INSERT ON completions BEGIN SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM task_occurrences WHERE id=NEW.occurrence_id AND state='pending' AND scheduled_date=NEW.scheduled_date) THEN RAISE(ABORT, 'completion occurrence/date mismatch') END; END;
CREATE TRIGGER completion_marks_completed AFTER INSERT ON completions BEGIN UPDATE task_occurrences SET state='completed' WHERE id=NEW.occurrence_id; END;
CREATE TRIGGER completion_delete_marks_pending AFTER DELETE ON completions BEGIN UPDATE task_occurrences SET state='pending' WHERE id=OLD.occurrence_id; END;
CREATE TRIGGER occurrence_state_guard BEFORE UPDATE OF state ON task_occurrences BEGIN SELECT CASE WHEN NEW.state='completed' AND NOT EXISTS (SELECT 1 FROM completions WHERE occurrence_id=NEW.id) THEN RAISE(ABORT, 'completed occurrence requires completion') WHEN NEW.state='pending' AND EXISTS (SELECT 1 FROM completions WHERE occurrence_id=NEW.id) THEN RAISE(ABORT, 'pending occurrence cannot have completion') END; END;
CREATE TRIGGER occurrence_insert_state_guard BEFORE INSERT ON task_occurrences WHEN NEW.state != 'pending' BEGIN SELECT RAISE(ABORT, 'new occurrence must be pending'); END;
CREATE TRIGGER revision_time_guard BEFORE INSERT ON completion_revisions BEGIN SELECT CASE WHEN NEW.revision != COALESCE((SELECT MAX(revision)+1 FROM completion_revisions WHERE completion_id=NEW.completion_id),1) THEN RAISE(ABORT, 'revision must be sequential') WHEN EXISTS (SELECT 1 FROM completion_revisions WHERE completion_id=NEW.completion_id) AND NEW.revised_at_utc <= (SELECT MAX(revised_at_utc) FROM completion_revisions WHERE completion_id=NEW.completion_id) THEN RAISE(ABORT, 'revision timestamp must increase') END; END;
PRAGMA user_version = 1;
INSERT INTO homes VALUES ('fixture-home','Fixture Home','Fixture address');
INSERT INTO rooms VALUES ('fixture-room','fixture-home','Kitchen');
INSERT INTO assets VALUES ('fixture-asset','fixture-home','fixture-room','Boiler');
INSERT INTO task_templates VALUES ('fixture-task','fixture-home','fixture-room','fixture-asset','Service','2024-02-29','yearly',2,'actualCompletionDate',29,2,23,59,'America/New_York',0);
INSERT INTO task_occurrences VALUES ('fixture-occurrence','fixture-task','2026-02-28','2026-03-01','pending');
INSERT INTO completions VALUES ('fixture-completion','fixture-occurrence','2026-02-28');
INSERT INTO completion_revisions VALUES ('fixture-completion',1,'2026-03-01','notes',1234,'USD',1772359200000000);
INSERT INTO completion_revisions VALUES ('fixture-completion',2,'2026-03-02',NULL,NULL,NULL,1772445600000000);
INSERT INTO attachment_metadata_rows VALUES ('fixture-attachment','fixture-completion','attachments/r.jpg','image/jpeg','aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa','receipt');
