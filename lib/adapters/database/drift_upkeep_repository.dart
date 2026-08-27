import 'package:drift/drift.dart';
import 'package:upkeep_log/application/upkeep_repository.dart';
import 'package:upkeep_log/domain/domain.dart' as domain;

import 'upkeep_database.dart';

final class DriftUpkeepRepository implements UpkeepRepository {
  DriftUpkeepRepository(this.db);
  final UpkeepDatabase db;

  @override
  Future<void> saveHome(domain.HomeProfile v) => db
      .into(db.homes)
      .insert(
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
      .insert(RoomsCompanion.insert(id: v.id, homeId: v.homeId, name: v.name));
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
        .insert(
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
        .insert(
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
    if (r == null) return null;
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

  @override
  Future<void> saveOccurrence(domain.TaskOccurrence v) => db
      .into(db.taskOccurrences)
      .insert(
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
    return r == null
        ? null
        : domain.TaskOccurrence(
            id: r.id,
            taskTemplateId: r.taskTemplateId,
            scheduledDate: domain.LocalDate.parse(r.scheduledDate),
            snoozedUntil: r.snoozedUntil == null
                ? null
                : domain.LocalDate.parse(r.snoozedUntil!),
            state: domain.OccurrenceState.values.byName(r.state),
          );
  }

  @override
  Future<void> saveCompletion(domain.Completion v) => db.transaction(() async {
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
      (await (db.select(
            db.attachmentMetadataRows,
          )..where((t) => t.completionId.equals(id))).get())
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
  Future<void> deleteRoom(String id) =>
      (db.delete(db.rooms)..where((t) => t.id.equals(id))).go();
  @override
  Future<void> deleteHome(String id) =>
      (db.delete(db.homes)..where((t) => t.id.equals(id))).go();
}

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
