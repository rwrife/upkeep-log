import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upkeep_log/adapters/database/drift_upkeep_repository.dart';
import 'package:upkeep_log/adapters/database/upkeep_database.dart'
    hide Completion, TaskTemplate;
import 'package:upkeep_log/application/upkeep_workflow.dart';
import 'package:upkeep_log/domain/domain.dart';

void main() {
  test(
    'completed record and next due occurrence survive app restart',
    () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'upkeep-restart-',
      );
      addTearDown(() => temp.delete(recursive: true));
      final File file = File('${temp.path}/upkeep.sqlite');
      final FakeClock clock = FakeClock(
        DateTime.utc(2026, 3, 8, 7),
        today: LocalDate(2026, 3, 8),
        timeZoneId: 'America/New_York',
      );
      var sequence = 0;

      UpkeepDatabase database = UpkeepDatabase(NativeDatabase(file));
      UpkeepWorkflow workflow = UpkeepWorkflow(
        DriftUpkeepRepository(database),
        clock: clock,
        idFactory: (String kind) => '$kind-${sequence++}',
      );
      await workflow.saveHome(HomeProfile(id: 'h', name: 'Home'));
      await workflow.createTask(
        TaskTemplate(
          id: 't',
          homeId: 'h',
          name: 'DST-safe filter',
          startDate: LocalDate(2026, 3, 8),
          recurrence: WeeklyRecurrence(),
        ),
      );
      await workflow.complete(
        occurrence: (await workflow.load()).occurrences.single,
        actualDate: LocalDate(2026, 3, 8),
        notes: 'Done after clock change',
        parts: 'Filter',
      );
      final Completion original = (await workflow.load()).completions.single;
      await workflow.reviseCompletion(
        current: original,
        actualDate: LocalDate(2026, 3, 9),
        notes: 'Corrected after checking receipt',
        parts: 'Filter and gasket',
      );
      await workflow.repository.saveAttachment(
        AttachmentMetadata(
          id: 'attachment',
          completionId: original.id,
          relativePath: 'attachments/h/receipt.pdf',
          mediaType: 'application/pdf',
          sha256: 'a' * 64,
          caption: 'Receipt',
        ),
      );
      await database.close();

      database = UpkeepDatabase(NativeDatabase(file));
      workflow = UpkeepWorkflow(DriftUpkeepRepository(database), clock: clock);
      final WorkflowSnapshot restored = await workflow.load();
      expect(restored.inBucket(OccurrenceBucket.completed), hasLength(1));
      expect(
        restored.completions.single.notes,
        'Corrected after checking receipt',
      );
      expect(restored.completions.single.parts, 'Filter and gasket');
      expect(restored.completions.single.revision, 2);
      expect(
        await workflow.completionRevisions(restored.completions.single.id),
        hasLength(2),
      );
      expect(
        (await workflow.repository.attachments()).single.caption,
        'Receipt',
      );
      expect(
        restored.inBucket(OccurrenceBucket.upcoming).single.scheduledDate,
        LocalDate(2026, 3, 15),
      );
      await database.close();
    },
  );
}
