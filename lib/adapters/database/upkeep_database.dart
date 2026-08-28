import 'package:drift/drift.dart';

part 'upkeep_database.g.dart';

/// Stores UTC revision instants exactly as signed Unix microseconds.
final class UtcMicrosecondsConverter extends TypeConverter<DateTime, int> {
  const UtcMicrosecondsConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMicrosecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int toSql(DateTime value) => value.toUtc().microsecondsSinceEpoch;
}

class Homes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get addressLabel => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Rooms extends Table {
  TextColumn get id => text()();
  TextColumn get homeId =>
      text().references(Homes, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
  @override
  List<String> get customConstraints => <String>['UNIQUE(id, home_id)'];
}

class Assets extends Table {
  TextColumn get id => text()();
  TextColumn get homeId =>
      text().references(Homes, #id, onDelete: KeyAction.cascade)();
  TextColumn get roomId => text().nullable()();
  TextColumn get name => text()();
  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
  @override
  List<String> get customConstraints => <String>[
    'UNIQUE(id, home_id)',
    'FOREIGN KEY(room_id, home_id) REFERENCES rooms(id, home_id) ON DELETE RESTRICT',
  ];
}

class TaskTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get homeId =>
      text().references(Homes, #id, onDelete: KeyAction.cascade)();
  TextColumn get roomId => text().nullable()();
  TextColumn get assetId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get startDate => text()();
  TextColumn get recurrenceKind => text()();
  IntColumn get recurrenceInterval => integer()();
  TextColumn get recurrenceAnchor => text()();
  IntColumn get recurrenceAnchorDay => integer()();
  IntColumn get recurrenceAnchorMonth => integer()();
  IntColumn get reminderHour => integer().nullable()();
  IntColumn get reminderMinute => integer().nullable()();
  TextColumn get reminderTimeZone => text().nullable()();
  BoolColumn get paused => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
  @override
  List<String> get customConstraints => <String>[
    "CHECK(length(start_date)=10 AND date(start_date)=start_date)",
    "CHECK(recurrence_kind IN ('oneTime','fixedDay','weekly','monthly','yearly'))",
    'CHECK(recurrence_interval > 0)',
    "CHECK(recurrence_anchor IN ('scheduledDate','actualCompletionDate'))",
    'CHECK(recurrence_anchor_day BETWEEN 1 AND 31)',
    'CHECK(recurrence_anchor_month BETWEEN 1 AND 12)',
    "CHECK(date(printf('2024-%02d-%02d', recurrence_anchor_month, recurrence_anchor_day)) = printf('2024-%02d-%02d', recurrence_anchor_month, recurrence_anchor_day))",
    "CHECK(recurrence_kind != 'oneTime' OR (recurrence_interval = 1 AND recurrence_anchor = 'scheduledDate'))",
    'CHECK((reminder_hour IS NULL AND reminder_minute IS NULL AND reminder_time_zone IS NULL) OR (reminder_hour IS NOT NULL AND reminder_minute IS NOT NULL AND reminder_time_zone IS NOT NULL AND reminder_hour BETWEEN 0 AND 23 AND reminder_minute BETWEEN 0 AND 59 AND length(trim(reminder_time_zone)) > 0))',
    'FOREIGN KEY(room_id, home_id) REFERENCES rooms(id, home_id) ON DELETE RESTRICT',
    'FOREIGN KEY(asset_id, home_id) REFERENCES assets(id, home_id) ON DELETE RESTRICT',
  ];
}

class TaskOccurrences extends Table {
  TextColumn get id => text()();
  TextColumn get taskTemplateId =>
      text().references(TaskTemplates, #id, onDelete: KeyAction.cascade)();
  TextColumn get scheduledDate => text()();
  TextColumn get snoozedUntil => text().nullable()();
  TextColumn get state => text()();
  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
  @override
  List<String> get customConstraints => <String>[
    "CHECK(length(scheduled_date)=10 AND date(scheduled_date)=scheduled_date)",
    "CHECK(snoozed_until IS NULL OR (length(snoozed_until)=10 AND date(snoozed_until)=snoozed_until AND snoozed_until >= scheduled_date))",
    "CHECK(state IN ('pending','completed'))",
  ];
}

class Completions extends Table {
  TextColumn get id => text()();
  TextColumn get occurrenceId => text().unique().references(
    TaskOccurrences,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get scheduledDate => text()();
  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
  @override
  List<String> get customConstraints => <String>[
    "CHECK(length(scheduled_date)=10 AND date(scheduled_date)=scheduled_date)",
  ];
}

class CompletionRevisions extends Table {
  TextColumn get completionId =>
      text().references(Completions, #id, onDelete: KeyAction.cascade)();
  IntColumn get revision => integer()();
  TextColumn get actualDate => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get partsText => text().nullable()();
  IntColumn get costMinorUnits => integer().nullable()();
  TextColumn get costCurrency => text().nullable()();
  IntColumn get revisedAtUtc =>
      integer().map(const UtcMicrosecondsConverter())();
  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{
    completionId,
    revision,
  };
  @override
  List<String> get customConstraints => <String>[
    'CHECK(revision > 0)',
    "CHECK(length(actual_date)=10 AND date(actual_date)=actual_date)",
    "CHECK((cost_minor_units IS NULL AND cost_currency IS NULL) OR (cost_minor_units IS NOT NULL AND cost_currency IS NOT NULL AND cost_currency GLOB '[A-Z][A-Z][A-Z]' AND length(cost_currency)=3))",
  ];
}

class AttachmentMetadataRows extends Table {
  TextColumn get id => text()();
  TextColumn get completionId =>
      text().references(Completions, #id, onDelete: KeyAction.cascade)();
  TextColumn get relativePath => text()();
  TextColumn get mediaType => text()();
  TextColumn get sha256 => text()();
  TextColumn get caption => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
  @override
  List<String> get customConstraints => <String>[
    "CHECK(length(relative_path)>0 AND substr(relative_path,1,1) NOT IN ('/','\\') AND relative_path NOT GLOB '[A-Za-z]:*' AND relative_path NOT LIKE '../%' AND relative_path NOT LIKE '%/../%' AND relative_path NOT LIKE '%/..' AND relative_path NOT LIKE '..\\%' AND relative_path NOT LIKE '%\\..\\%' AND relative_path NOT LIKE '%\\..')",
    'CHECK(length(media_type)>0)',
    "CHECK(length(sha256)=64 AND sha256 NOT GLOB '*[^0-9a-f]*')",
  ];
}

@DriftDatabase(
  tables: <Type>[
    Homes,
    Rooms,
    Assets,
    TaskTemplates,
    TaskOccurrences,
    Completions,
    CompletionRevisions,
    AttachmentMetadataRows,
  ],
)
class UpkeepDatabase extends _$UpkeepDatabase {
  UpkeepDatabase(super.executor);
  @override
  int get schemaVersion => 2;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createInvariantTriggers();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(completionRevisions, completionRevisions.partsText);
      }
    },
    beforeOpen: (OpeningDetails details) async =>
        customStatement('PRAGMA foreign_keys = ON'),
  );

  Future<void> _createInvariantTriggers() async {
    for (final String statement in _invariantTriggers) {
      await customStatement(statement);
    }
  }
}

const List<String> _invariantTriggers = <String>[
  '''CREATE TRIGGER completion_insert_guard BEFORE INSERT ON completions BEGIN
    SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM task_occurrences WHERE id=NEW.occurrence_id AND state='pending' AND scheduled_date=NEW.scheduled_date) THEN RAISE(ABORT, 'completion occurrence/date mismatch') END;
  END''',
  '''CREATE TRIGGER completion_marks_completed AFTER INSERT ON completions BEGIN
    UPDATE task_occurrences SET state='completed' WHERE id=NEW.occurrence_id;
  END''',
  '''CREATE TRIGGER completion_delete_marks_pending AFTER DELETE ON completions BEGIN
    UPDATE task_occurrences SET state='pending' WHERE id=OLD.occurrence_id;
  END''',
  '''CREATE TRIGGER occurrence_state_guard BEFORE UPDATE OF state ON task_occurrences BEGIN
    SELECT CASE WHEN NEW.state='completed' AND NOT EXISTS (SELECT 1 FROM completions WHERE occurrence_id=NEW.id) THEN RAISE(ABORT, 'completed occurrence requires completion') WHEN NEW.state='pending' AND EXISTS (SELECT 1 FROM completions WHERE occurrence_id=NEW.id) THEN RAISE(ABORT, 'pending occurrence cannot have completion') END;
  END''',
  '''CREATE TRIGGER occurrence_insert_state_guard BEFORE INSERT ON task_occurrences WHEN NEW.state != 'pending' BEGIN SELECT RAISE(ABORT, 'new occurrence must be pending'); END''',
  '''CREATE TRIGGER revision_time_guard BEFORE INSERT ON completion_revisions BEGIN
    SELECT CASE WHEN NEW.revision != COALESCE((SELECT MAX(revision)+1 FROM completion_revisions WHERE completion_id=NEW.completion_id),1) THEN RAISE(ABORT, 'revision must be sequential') WHEN EXISTS (SELECT 1 FROM completion_revisions WHERE completion_id=NEW.completion_id) AND NEW.revised_at_utc <= (SELECT MAX(revised_at_utc) FROM completion_revisions WHERE completion_id=NEW.completion_id) THEN RAISE(ABORT, 'revision timestamp must increase') END;
  END''',
];
