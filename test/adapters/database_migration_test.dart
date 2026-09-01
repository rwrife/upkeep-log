import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:upkeep_log/adapters/database/drift_upkeep_repository.dart';
import 'package:upkeep_log/adapters/database/upkeep_database.dart'
    hide Completion, Room, TaskOccurrence, TaskTemplate;
import 'package:upkeep_log/domain/domain.dart';

void main() {
  test(
    'migrates committed schema-v1 fixture and reads its typed seed',
    () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'upkeep-v1-',
      );
      addTearDown(() => temp.delete(recursive: true));
      final File file = File('${temp.path}/fixture.sqlite');
      final sqlite.Database raw = sqlite.sqlite3.open(file.path);
      raw.execute(await File('test/fixtures/schema_v1.sql').readAsString());
      raw.close();

      final UpkeepDatabase database = UpkeepDatabase(NativeDatabase(file));
      final DriftUpkeepRepository repository = DriftUpkeepRepository(database);
      expect(database.schemaVersion, 3);
      expect((await repository.homeById('fixture-home'))!.name, 'Fixture Home');
      expect((await repository.roomById('fixture-room'))!.name, 'Kitchen');
      expect(
        (await repository.assetById('fixture-asset'))!.roomId,
        'fixture-room',
      );
      final TaskTemplate task = (await repository.taskById('fixture-task'))!;
      expect(task.recurrence, isA<YearlyRecurrence>());
      expect(task.recurrenceAnchorDay, 29);
      expect(task.recurrenceAnchorMonth, 2);
      expect(task.reminder!.hour, 23);
      expect(task.reminder!.minute, 59);
      expect(task.reminder!.timeZoneId, 'America/New_York');
      expect(
        (await repository.occurrenceById('fixture-occurrence'))!.state,
        OccurrenceState.completed,
      );
      final List<Completion> history = await repository.completionHistory(
        'fixture-completion',
      );
      expect(history, hasLength(2));
      expect(history.first.cost!.minorUnits, 1234);
      expect(history.first.notes, 'notes');
      expect(
        history.first.revisedAtUtc,
        DateTime.fromMicrosecondsSinceEpoch(1772359200000000, isUtc: true),
      );
      expect(history.last.cost, isNull);
      expect(history.last.notes, isNull);
      expect(
        history.last.revisedAtUtc,
        DateTime.fromMicrosecondsSinceEpoch(1772445600000000, isUtc: true),
      );
      expect(
        (await repository.attachmentsForCompletion('fixture-completion'))
            .single
            .caption,
        'receipt',
      );
      expect(
        await database.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
      expect(
        (await database.customSelect('PRAGMA integrity_check').get())
            .single
            .data
            .values
            .single,
        'ok',
      );
      await database.close();

      final UpkeepDatabase reopened = UpkeepDatabase(NativeDatabase(file));
      final DriftUpkeepRepository reopenedRepository = DriftUpkeepRepository(
        reopened,
      );
      await reopenedRepository.saveHome(
        HomeProfile(id: 'after-reopen', name: 'Writable'),
      );
      expect(
        (await reopenedRepository.homeById('after-reopen'))!.name,
        'Writable',
      );
      await reopened.close();
    },
  );

  test(
    'migrated fixture has the same normalized v3 schema shape as fresh data',
    () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'upkeep-shape-',
      );
      addTearDown(() => temp.delete(recursive: true));
      final File fixtureFile = File('${temp.path}/fixture.sqlite');
      final sqlite.Database fixture = sqlite.sqlite3.open(fixtureFile.path)
        ..execute(await File('test/fixtures/schema_v1.sql').readAsString());
      final File freshFile = File('${temp.path}/fresh.sqlite');
      final UpkeepDatabase freshDrift = UpkeepDatabase(
        NativeDatabase(freshFile),
      );
      await freshDrift.customSelect('SELECT 1').get();
      await freshDrift.close();
      final UpkeepDatabase migratedDrift = UpkeepDatabase(
        NativeDatabase(fixtureFile),
      );
      await migratedDrift.customSelect('SELECT 1').get();
      await migratedDrift.close();
      final sqlite.Database fresh = sqlite.sqlite3.open(freshFile.path);
      final Map<String, Object> migratedShape = _shape(fixture);
      final Map<String, Object> freshShape = _shape(fresh);
      for (final String key in freshShape.keys) {
        if (key == 'completion_revisions.sql' ||
            key == 'completion_revisions.columns') {
          continue;
        }
        expect(migratedShape[key], freshShape[key], reason: key);
      }
      expect(
        (migratedShape['completion_revisions.columns']! as List<Object?>)
            .map((Object? row) => (row! as List<Object?>).first)
            .toSet(),
        (freshShape['completion_revisions.columns']! as List<Object?>)
            .map((Object? row) => (row! as List<Object?>).first)
            .toSet(),
      );
      fixture.close();
      fresh.close();
    },
  );

  test('temporary SQLite database survives close and reopen', () async {
    final Directory temp = await Directory.systemTemp.createTemp(
      'upkeep-reopen-',
    );
    addTearDown(() => temp.delete(recursive: true));
    final File file = File('${temp.path}/upkeep.sqlite');
    UpkeepDatabase database = UpkeepDatabase(NativeDatabase(file));
    DriftUpkeepRepository repository = DriftUpkeepRepository(database);
    await repository.saveHome(HomeProfile(id: 'h', name: 'Persistent Home'));
    await repository.saveRoom(Room(id: 'r', homeId: 'h', name: 'Loft'));
    await database.close();

    database = UpkeepDatabase(NativeDatabase(file));
    repository = DriftUpkeepRepository(database);
    expect((await repository.homeById('h'))!.name, 'Persistent Home');
    expect((await repository.roomById('r'))!.name, 'Loft');
    await database.close();
  });

  test(
    'raw schema triggers preserve completion state and cascade history',
    () async {
      final UpkeepDatabase database = UpkeepDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await database.customStatement(
        "INSERT INTO homes(id,name) VALUES ('h','Home')",
      );
      await database.customStatement(
        "INSERT INTO task_templates(id,home_id,name,start_date,recurrence_kind,recurrence_interval,recurrence_anchor,recurrence_anchor_day,recurrence_anchor_month,paused) VALUES ('t','h','Task','2026-01-01','oneTime',1,'scheduledDate',1,1,0)",
      );
      await database.customStatement(
        "INSERT INTO task_occurrences(id,task_template_id,scheduled_date,state) VALUES ('o','t','2026-01-01','pending')",
      );
      await database.customStatement(
        "INSERT INTO completions(id,occurrence_id,scheduled_date) VALUES ('c','o','2026-01-01')",
      );
      expect(
        (await database
                .customSelect("SELECT state FROM task_occurrences WHERE id='o'")
                .getSingle())
            .read<String>('state'),
        'completed',
      );
      await database.customStatement(
        "INSERT INTO completion_revisions(completion_id,revision,actual_date,revised_at_utc) VALUES ('c',1,'2026-01-01',100)",
      );
      await expectLater(
        database.customStatement(
          "INSERT INTO completion_revisions(completion_id,revision,actual_date,revised_at_utc) VALUES ('c',3,'2026-01-02',200)",
        ),
        throwsA(anything),
      );
      await expectLater(
        database.customStatement(
          "INSERT INTO completion_revisions(completion_id,revision,actual_date,revised_at_utc) VALUES ('c',2,'2026-01-02',100)",
        ),
        throwsA(anything),
      );
      await database.customStatement("DELETE FROM completions WHERE id='c'");
      expect(
        (await database
                .customSelect("SELECT state FROM task_occurrences WHERE id='o'")
                .getSingle())
            .read<String>('state'),
        'pending',
      );
      await database.customStatement("DELETE FROM homes WHERE id='h'");
      for (final String table in <String>[
        'task_templates',
        'task_occurrences',
        'completions',
        'completion_revisions',
      ]) {
        expect(
          (await database
                  .customSelect('SELECT count(*) AS n FROM $table')
                  .getSingle())
              .read<int>('n'),
          0,
        );
      }
    },
  );
}

Map<String, Object> _shape(sqlite.Database db) {
  final List<String> names = db
      .select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .map((r) => r['name'] as String)
      .toList();
  return <String, Object>{
    'tables': names,
    for (final String name in names) ...<String, Object>{
      '$name.sql': _normalizeSql(
        db.select(
              "SELECT sql FROM sqlite_master WHERE type='table' AND name=?",
              <Object?>[name],
            ).single['sql']
            as String,
      ),
      '$name.columns': db
          .select('PRAGMA table_info($name)')
          .map(
            (r) => <Object?>[
              r['name'],
              r['type'],
              r['notnull'],
              r['dflt_value'],
              r['pk'],
            ],
          )
          .toList(),
      '$name.fks': db
          .select('PRAGMA foreign_key_list($name)')
          .map((r) => <Object?>[r['from'], r['table'], r['to'], r['on_delete']])
          .toList(),
      '$name.indexes':
          db
              .select('PRAGMA index_list($name)')
              .map((r) => <Object?>[r['unique'], r['origin']])
              .toList()
            ..sort((a, b) => a.toString().compareTo(b.toString())),
    },
    'triggers': db
        .select(
          "SELECT name, sql FROM sqlite_master WHERE type='trigger' ORDER BY name",
        )
        .map((r) => <Object?>[r['name'], _normalizeSql(r['sql'] as String)])
        .toList(),
  };
}

String _normalizeSql(String value) => value
    .replaceAll(RegExp(r'\bIF\s+NOT\s+EXISTS\b', caseSensitive: false), '')
    .replaceAll(RegExp(r'["`]'), '')
    .replaceAll(RegExp(r'\s+'), '')
    .toLowerCase();
