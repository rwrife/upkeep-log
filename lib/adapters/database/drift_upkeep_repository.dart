import 'package:drift/drift.dart';
import 'package:upkeep_log/application/portable_data.dart';
import 'package:upkeep_log/application/upkeep_repository.dart';
import 'package:upkeep_log/domain/domain.dart' as domain;

import 'upkeep_database.dart';

final class DriftUpkeepRepository implements UpkeepRepository {
  DriftUpkeepRepository(this.db);
  final UpkeepDatabase db;

  @override
  Future<List<domain.HomeProfile>> homes() async =>
      (await (db.select(db.homes)..orderBy(<OrderingTerm Function(Homes)>[
                (t) => OrderingTerm.asc(t.name),
              ]))
              .get())
          .map(
            (r) => domain.HomeProfile(
              id: r.id,
              name: r.name,
              addressLabel: r.addressLabel,
            ),
          )
          .toList(growable: false);

  @override
  Future<List<domain.Room>> rooms() async =>
      (await (db.select(db.rooms)..orderBy(<OrderingTerm Function(Rooms)>[
                (t) => OrderingTerm.asc(t.name),
              ]))
              .get())
          .map((r) => domain.Room(id: r.id, homeId: r.homeId, name: r.name))
          .toList(growable: false);

  @override
  Future<List<domain.Asset>> assets() async =>
      (await (db.select(db.assets)..orderBy(<OrderingTerm Function(Assets)>[
                (t) => OrderingTerm.asc(t.name),
              ]))
              .get())
          .map(
            (r) => domain.Asset(
              id: r.id,
              homeId: r.homeId,
              roomId: r.roomId,
              name: r.name,
            ),
          )
          .toList(growable: false);

  @override
  Future<List<domain.TaskTemplate>> tasks() async =>
      (await (db.select(db.taskTemplates)
                ..orderBy(<OrderingTerm Function(TaskTemplates)>[
                  (t) => OrderingTerm.asc(t.name),
                ]))
              .get())
          .map(_taskFromRow)
          .toList(growable: false);

  @override
  Future<List<domain.TaskOccurrence>> occurrences() async =>
      (await (db.select(db.taskOccurrences)
                ..orderBy(<OrderingTerm Function(TaskOccurrences)>[
                  (t) => OrderingTerm.asc(t.scheduledDate),
                ]))
              .get())
          .map(_occurrenceFromRow)
          .toList(growable: false);

  @override
  Future<List<domain.Completion>> completions() async {
    final List<Completion> bases = await db.select(db.completions).get();
    final List<domain.Completion> result = <domain.Completion>[];
    for (final Completion base in bases) {
      final domain.Completion? value = await latestCompletion(base.id);
      if (value != null) result.add(value);
    }
    return result;
  }

  @override
  Future<void> saveHome(domain.HomeProfile v) => db
      .into(db.homes)
      .insertOnConflictUpdate(
        HomesCompanion.insert(
          id: v.id,
          name: v.name,
          addressLabel: Value(v.addressLabel),
        ),
      );
  @override
  Future<domain.HomeProfile?> homeById(String id) async {
    final Home? r = await (db.select(
      db.homes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null
        ? null
        : domain.HomeProfile(
            id: r.id,
            name: r.name,
            addressLabel: r.addressLabel,
          );
  }

  @override
  Future<void> saveRoom(domain.Room v) => db
      .into(db.rooms)
      .insertOnConflictUpdate(
        RoomsCompanion.insert(id: v.id, homeId: v.homeId, name: v.name),
      );
  @override
  Future<domain.Room?> roomById(String id) async {
    final Room? r = await (db.select(
      db.rooms,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null
        ? null
        : domain.Room(id: r.id, homeId: r.homeId, name: r.name);
  }

  @override
  Future<void> saveAsset(domain.Asset v) async {
    if (v.roomId != null) {
      final Room? room = await (db.select(
        db.rooms,
      )..where((t) => t.id.equals(v.roomId!))).getSingleOrNull();
      if (room == null || room.homeId != v.homeId) {
        throw StateError('Asset room must belong to the same home');
      }
    }
    await db
        .into(db.assets)
        .insertOnConflictUpdate(
          AssetsCompanion.insert(
            id: v.id,
            homeId: v.homeId,
            roomId: Value(v.roomId),
            name: v.name,
          ),
        );
  }

  @override
  Future<domain.Asset?> assetById(String id) async {
    final Asset? r = await (db.select(
      db.assets,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null
        ? null
        : domain.Asset(
            id: r.id,
            homeId: r.homeId,
            roomId: r.roomId,
            name: r.name,
          );
  }

  @override
  Future<void> saveTask(domain.TaskTemplate v) async {
    final TaskTemplate? existing = await (db.select(
      db.taskTemplates,
    )..where((t) => t.id.equals(v.id))).getSingleOrNull();
    if (existing != null && existing.homeId != v.homeId) {
      throw StateError('An existing task cannot move to another home');
    }
    if (v.roomId != null) {
      final Room? room = await (db.select(
        db.rooms,
      )..where((t) => t.id.equals(v.roomId!))).getSingleOrNull();
      if (room == null || room.homeId != v.homeId) {
        throw StateError('Task room must belong to the same home');
      }
    }
    if (v.assetId != null) {
      final Asset? asset = await (db.select(
        db.assets,
      )..where((t) => t.id.equals(v.assetId!))).getSingleOrNull();
      if (asset == null || asset.homeId != v.homeId) {
        throw StateError('Task asset must belong to the same home');
      }
    }
    final (String, int) encoded = _encodeRecurrence(v.recurrence);
    await db
        .into(db.taskTemplates)
        .insertOnConflictUpdate(
          TaskTemplatesCompanion.insert(
            id: v.id,
            homeId: v.homeId,
            roomId: Value(v.roomId),
            assetId: Value(v.assetId),
            name: v.name,
            startDate: v.startDate.toIso8601String(),
            recurrenceKind: encoded.$1,
            recurrenceInterval: encoded.$2,
            recurrenceAnchor: v.recurrence.anchor.name,
            recurrenceAnchorDay: v.recurrenceAnchorDay,
            recurrenceAnchorMonth: v.recurrenceAnchorMonth,
            reminderHour: Value(v.reminder?.hour),
            reminderMinute: Value(v.reminder?.minute),
            reminderTimeZone: Value(v.reminder?.timeZoneId),
            paused: Value(v.paused),
          ),
        );
  }

  @override
  Future<domain.TaskTemplate?> taskById(String id) async {
    final TaskTemplate? r = await (db.select(
      db.taskTemplates,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _taskFromRow(r);
  }

  @override
  Future<void> saveOccurrence(domain.TaskOccurrence v) => db
      .into(db.taskOccurrences)
      .insertOnConflictUpdate(
        TaskOccurrencesCompanion.insert(
          id: v.id,
          taskTemplateId: v.taskTemplateId,
          scheduledDate: v.scheduledDate.toIso8601String(),
          snoozedUntil: Value(v.snoozedUntil?.toIso8601String()),
          state: v.state.name,
        ),
      );
  @override
  Future<domain.TaskOccurrence?> occurrenceById(String id) async {
    final TaskOccurrence? r = await (db.select(
      db.taskOccurrences,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _occurrenceFromRow(r);
  }

  @override
  Future<void> saveTaskWithOccurrence(
    domain.TaskTemplate task,
    domain.TaskOccurrence occurrence,
  ) => db.transaction(() async {
    await saveTask(task);
    await saveOccurrence(occurrence);
  });

  @override
  Future<void> saveCompletion(domain.Completion v) => completeOccurrence(v);

  @override
  Future<void> completeOccurrence(
    domain.Completion v, {
    domain.TaskOccurrence? nextOccurrence,
  }) => db.transaction(() async {
    if (v.revision != 1) {
      throw StateError('Initial completion revision must be 1');
    }
    final TaskOccurrence? occurrence = await (db.select(
      db.taskOccurrences,
    )..where((t) => t.id.equals(v.occurrenceId))).getSingleOrNull();
    if (occurrence == null ||
        occurrence.state != domain.OccurrenceState.pending.name ||
        occurrence.scheduledDate != v.scheduledDate.toIso8601String()) {
      throw StateError('Completion must match a pending occurrence date');
    }
    await db
        .into(db.completions)
        .insert(
          CompletionsCompanion.insert(
            id: v.id,
            occurrenceId: v.occurrenceId,
            scheduledDate: v.scheduledDate.toIso8601String(),
          ),
        );
    await _insertRevision(v);
    final int updated =
        await (db.update(db.taskOccurrences)
              ..where((t) => t.id.equals(v.occurrenceId)))
            .write(const TaskOccurrencesCompanion(state: Value('completed')));
    if (updated != 1) throw StateError('Occurrence completion update failed');
    if (nextOccurrence != null) {
      await db
          .into(db.taskOccurrences)
          .insert(
            TaskOccurrencesCompanion.insert(
              id: nextOccurrence.id,
              taskTemplateId: nextOccurrence.taskTemplateId,
              scheduledDate: nextOccurrence.scheduledDate.toIso8601String(),
              snoozedUntil: Value(
                nextOccurrence.snoozedUntil?.toIso8601String(),
              ),
              state: nextOccurrence.state.name,
            ),
          );
    }
  });

  @override
  Future<void> appendCompletionRevision(
    domain.Completion v,
  ) => db.transaction(() async {
    final Completion? base = await (db.select(
      db.completions,
    )..where((t) => t.id.equals(v.id))).getSingleOrNull();
    if (base == null ||
        base.occurrenceId != v.occurrenceId ||
        base.scheduledDate != v.scheduledDate.toIso8601String()) {
      throw StateError('Completion identity and scheduled date are immutable');
    }
    final Expression<int> maxRevision = db.completionRevisions.revision.max();
    final TypedResult row =
        await (db.selectOnly(db.completionRevisions)
              ..addColumns(<Expression<Object>>[maxRevision])
              ..where(db.completionRevisions.completionId.equals(v.id)))
            .getSingle();
    if (v.revision != (row.read(maxRevision) ?? 0) + 1) {
      throw StateError('Revision must append sequentially');
    }
    final CompletionRevision? previousRevision =
        await (db.select(db.completionRevisions)
              ..where((t) => t.completionId.equals(v.id))
              ..orderBy(<OrderingTerm Function(CompletionRevisions)>[
                (t) => OrderingTerm.desc(t.revision),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (previousRevision != null &&
        !v.revisedAtUtc.isAfter(previousRevision.revisedAtUtc)) {
      throw StateError('Revision timestamp must increase');
    }
    await _insertRevision(v);
  });

  Future<void> _insertRevision(domain.Completion v) => db
      .into(db.completionRevisions)
      .insert(
        CompletionRevisionsCompanion.insert(
          completionId: v.id,
          revision: v.revision,
          actualDate: v.actualDate.toIso8601String(),
          notes: Value(v.notes),
          partsText: Value(v.parts),
          costMinorUnits: Value(v.cost?.minorUnits),
          costCurrency: Value(v.cost?.currency),
          revisedAtUtc: v.revisedAtUtc,
        ),
      );

  @override
  Future<List<domain.Completion>> completionHistory(String completionId) async {
    final Completion? base = await (db.select(
      db.completions,
    )..where((t) => t.id.equals(completionId))).getSingleOrNull();
    if (base == null) return <domain.Completion>[];
    final List<CompletionRevision> revisions =
        await (db.select(db.completionRevisions)
              ..where((t) => t.completionId.equals(completionId))
              ..orderBy(<OrderingTerm Function(CompletionRevisions)>[
                (t) => OrderingTerm.asc(t.revision),
              ]))
            .get();
    return revisions
        .map(
          (r) => domain.Completion(
            id: base.id,
            occurrenceId: base.occurrenceId,
            scheduledDate: domain.LocalDate.parse(base.scheduledDate),
            actualDate: domain.LocalDate.parse(r.actualDate),
            notes: r.notes,
            parts: r.partsText,
            cost: r.costMinorUnits == null
                ? null
                : domain.Money(
                    minorUnits: r.costMinorUnits!,
                    currency: r.costCurrency!,
                  ),
            revision: r.revision,
            revisedAtUtc: r.revisedAtUtc,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<domain.Completion?> latestCompletion(String id) async {
    final List<domain.Completion> values = await completionHistory(id);
    return values.isEmpty ? null : values.last;
  }

  @override
  Future<void> saveAttachment(domain.AttachmentMetadata v) => db
      .into(db.attachmentMetadataRows)
      .insert(
        AttachmentMetadataRowsCompanion.insert(
          id: v.id,
          completionId: v.completionId,
          relativePath: v.relativePath,
          mediaType: v.mediaType,
          sha256: v.sha256,
          caption: Value(v.caption),
        ),
      );
  @override
  Future<List<domain.AttachmentMetadata>> attachmentsForCompletion(
    String id,
  ) async =>
      (await (db.select(db.attachmentMetadataRows)
                ..where((t) => t.completionId.equals(id))
                ..orderBy(<OrderingTerm Function(AttachmentMetadataRows)>[
                  (t) => OrderingTerm.asc(t.relativePath),
                  (t) => OrderingTerm.asc(t.id),
                ]))
              .get())
          .map(
            (r) => domain.AttachmentMetadata(
              id: r.id,
              completionId: r.completionId,
              relativePath: r.relativePath,
              mediaType: r.mediaType,
              sha256: r.sha256,
              caption: r.caption,
            ),
          )
          .toList();

  @override
  Future<List<domain.AttachmentMetadata>> attachments() async =>
      (await (db.select(db.attachmentMetadataRows)
                ..orderBy(<OrderingTerm Function(AttachmentMetadataRows)>[
                  (t) => OrderingTerm.asc(t.relativePath),
                  (t) => OrderingTerm.asc(t.id),
                ]))
              .get())
          .map(_attachmentFromRow)
          .toList(growable: false);

  @override
  Future<void> deleteAttachment(String id) => (db.delete(
    db.attachmentMetadataRows,
  )..where((t) => t.id.equals(id))).go();

  @override
  Future<void> deleteRoom(String id) =>
      (db.delete(db.rooms)..where((t) => t.id.equals(id))).go();
  @override
  Future<void> deleteTask(String id) => db.transaction(() async {
    final QueryRow? completion = await db
        .customSelect(
          '''SELECT 1 FROM completions c
             JOIN task_occurrences o ON o.id = c.occurrence_id
             WHERE o.task_template_id = ? LIMIT 1''',
          variables: <Variable<Object>>[Variable<String>(id)],
        )
        .getSingleOrNull();
    if (completion != null) {
      throw StateError('Cannot delete a task with completion history');
    }
    await (db.delete(db.taskTemplates)..where((t) => t.id.equals(id))).go();
  });
  @override
  Future<void> deleteHome(String id) => db.transaction(() async {
    final QueryRow? completion = await db
        .customSelect(
          '''SELECT 1 FROM completions c
             JOIN task_occurrences o ON o.id = c.occurrence_id
             JOIN task_templates t ON t.id = o.task_template_id
             WHERE t.home_id = ? LIMIT 1''',
          variables: <Variable<Object>>[Variable<String>(id)],
        )
        .getSingleOrNull();
    if (completion != null) {
      throw StateError('Cannot delete a home with completion history');
    }
    await (db.delete(db.homes)..where((t) => t.id.equals(id))).go();
  });

  @override
  Future<PortableData> portableData() => db.transaction(() async {
    // Keep every table read on one SQLite snapshot. Workflow writes do not use
    // the file-operation gate, so the database transaction is the consistency
    // boundary that prevents a backup from mixing pre- and post-write rows.
    final List<domain.Completion> revisions = <domain.Completion>[];
    final List<Completion> bases = await db.select(db.completions).get();
    for (final Completion base in bases) {
      revisions.addAll(await completionHistory(base.id));
    }
    revisions.sort((a, b) {
      final int id = a.id.compareTo(b.id);
      return id != 0 ? id : a.revision.compareTo(b.revision);
    });
    return PortableData(
      homes: await homes(),
      rooms: await rooms(),
      assets: await assets(),
      tasks: await tasks(),
      occurrences: await occurrences(),
      completionRevisions: revisions,
      attachments: await attachments(),
    );
  });

  @override
  Future<void> replacePortableData(
    PortableData value, {
    String? restoreToken,
  }) => db.transaction(() async {
    await db.delete(db.attachmentMetadataRows).go();
    await db.delete(db.completionRevisions).go();
    await db.delete(db.completions).go();
    await db.delete(db.taskOccurrences).go();
    await db.delete(db.taskTemplates).go();
    await db.delete(db.assets).go();
    await db.delete(db.rooms).go();
    await db.delete(db.homes).go();
    for (final domain.HomeProfile item in value.homes) {
      await saveHome(item);
    }
    for (final domain.Room item in value.rooms) {
      await saveRoom(item);
    }
    for (final domain.Asset item in value.assets) {
      await saveAsset(item);
    }
    for (final domain.TaskTemplate item in value.tasks) {
      await saveTask(item);
    }
    // Completed state is established by the completion trigger later.
    for (final domain.TaskOccurrence item in value.occurrences) {
      await saveOccurrence(
        domain.TaskOccurrence(
          id: item.id,
          taskTemplateId: item.taskTemplateId,
          scheduledDate: item.scheduledDate,
          snoozedUntil: item.snoozedUntil,
        ),
      );
    }
    final Map<String, List<domain.Completion>> grouped =
        <String, List<domain.Completion>>{};
    for (final domain.Completion item in value.completionRevisions) {
      grouped.putIfAbsent(item.id, () => <domain.Completion>[]).add(item);
    }
    for (final List<domain.Completion> history in grouped.values) {
      history.sort((a, b) => a.revision.compareTo(b.revision));
      await completeOccurrence(history.first);
      for (final domain.Completion revision in history.skip(1)) {
        await appendCompletionRevision(revision);
      }
    }
    for (final domain.AttachmentMetadata item in value.attachments) {
      await saveAttachment(item);
    }
    if (restoreToken != null) {
      await db
          .into(db.restoreMetadata)
          .insertOnConflictUpdate(
            RestoreMetadataCompanion.insert(
              singleton: const Value(1),
              token: restoreToken,
            ),
          );
    }
  });

  @override
  Future<String?> committedRestoreToken() async => (await (db.select(
    db.restoreMetadata,
  )..where((t) => t.singleton.equals(1))).getSingleOrNull())?.token;

  @override
  Future<void> clearCommittedRestoreToken(String token) async {
    await (db.delete(
      db.restoreMetadata,
    )..where((t) => t.singleton.equals(1) & t.token.equals(token))).go();
  }

  @override
  Future<List<String>> deleteHomeData(String id) => db.transaction(() async {
    final List<QueryRow> rows = await db
        .customSelect(
          '''SELECT a.relative_path FROM attachment_metadata_rows a
         JOIN completions c ON c.id = a.completion_id
         JOIN task_occurrences o ON o.id = c.occurrence_id
         JOIN task_templates t ON t.id = o.task_template_id
         WHERE t.home_id = ?''',
          variables: <Variable<Object>>[Variable<String>(id)],
        )
        .get();
    await (db.delete(db.homes)..where((t) => t.id.equals(id))).go();
    return rows.map((r) => r.read<String>('relative_path')).toList();
  });

  @override
  Future<List<String>> resetAllData() => db.transaction(() async {
    final List<String> paths = (await attachments())
        .map((value) => value.relativePath)
        .toList(growable: false);
    await db.delete(db.homes).go();
    return paths;
  });
}

domain.AttachmentMetadata _attachmentFromRow(AttachmentMetadataRow r) =>
    domain.AttachmentMetadata(
      id: r.id,
      completionId: r.completionId,
      relativePath: r.relativePath,
      mediaType: r.mediaType,
      sha256: r.sha256,
      caption: r.caption,
    );

domain.TaskTemplate _taskFromRow(TaskTemplate r) {
  final domain.ReminderIntent? reminder = r.reminderHour == null
      ? null
      : domain.ReminderIntent(
          hour: r.reminderHour!,
          minute: r.reminderMinute!,
          timeZoneId: r.reminderTimeZone!,
        );
  return domain.TaskTemplate(
    id: r.id,
    homeId: r.homeId,
    roomId: r.roomId,
    assetId: r.assetId,
    name: r.name,
    startDate: domain.LocalDate.parse(r.startDate),
    recurrence: _decodeRecurrence(
      r.recurrenceKind,
      r.recurrenceInterval,
      r.recurrenceAnchor,
    ),
    recurrenceAnchorDay: r.recurrenceAnchorDay,
    recurrenceAnchorMonth: r.recurrenceAnchorMonth,
    reminder: reminder,
    paused: r.paused,
  );
}

domain.TaskOccurrence _occurrenceFromRow(TaskOccurrence r) =>
    domain.TaskOccurrence(
      id: r.id,
      taskTemplateId: r.taskTemplateId,
      scheduledDate: domain.LocalDate.parse(r.scheduledDate),
      snoozedUntil: r.snoozedUntil == null
          ? null
          : domain.LocalDate.parse(r.snoozedUntil!),
      state: domain.OccurrenceState.values.byName(r.state),
    );

(String, int) _encodeRecurrence(
  domain.RecurrencePolicy value,
) => switch (value) {
  domain.OneTimeRecurrence() => ('oneTime', 1),
  domain.FixedDayRecurrence(:final days) => ('fixedDay', days),
  domain.WeeklyRecurrence(:final intervalWeeks) => ('weekly', intervalWeeks),
  domain.MonthlyRecurrence(:final intervalMonths) => (
    'monthly',
    intervalMonths,
  ),
  domain.YearlyRecurrence(:final intervalYears) => ('yearly', intervalYears),
};

domain.RecurrencePolicy _decodeRecurrence(
  String kind,
  int interval,
  String anchorName,
) {
  final domain.RecurrenceAnchor anchor = domain.RecurrenceAnchor.values.byName(
    anchorName,
  );
  return switch (kind) {
    'oneTime' => const domain.OneTimeRecurrence(),
    'fixedDay' => domain.FixedDayRecurrence(interval, anchor: anchor),
    'weekly' => domain.WeeklyRecurrence(
      intervalWeeks: interval,
      anchor: anchor,
    ),
    'monthly' => domain.MonthlyRecurrence(
      intervalMonths: interval,
      anchor: anchor,
    ),
    'yearly' => domain.YearlyRecurrence(
      intervalYears: interval,
      anchor: anchor,
    ),
    _ => throw StateError('Unknown recurrence kind: $kind'),
  };
}
