import 'package:flutter_test/flutter_test.dart';
import 'package:upkeep_log/application/history.dart';
import 'package:upkeep_log/domain/domain.dart';

void main() {
  test('history filters locally and sorts deterministically', () {
    final HomeProfile home = HomeProfile(id: 'h', name: 'Home');
    final Room room = Room(id: 'r', homeId: 'h', name: 'Kitchen');
    final Asset asset = Asset(id: 'a', homeId: 'h', roomId: 'r', name: 'Oven');
    HistoryEntry entry(String id, String name, LocalDate date, int revision) {
      final TaskTemplate task = TaskTemplate(
        id: 't$id',
        homeId: 'h',
        assetId: 'a',
        name: name,
        startDate: date,
        recurrence: const OneTimeRecurrence(),
      );
      final TaskOccurrence occurrence = TaskOccurrence(
        id: 'o$id',
        taskTemplateId: task.id,
        scheduledDate: date,
        state: OccurrenceState.completed,
      );
      return HistoryEntry(
        home: home,
        task: task,
        occurrence: occurrence,
        completion: Completion(
          id: id,
          occurrenceId: occurrence.id,
          scheduledDate: date,
          actualDate: date,
          revision: revision,
          revisedAtUtc: DateTime.utc(2026),
        ),
        asset: asset,
        room: room,
      );
    }

    final List<HistoryEntry> result = filterHistory(
      <HistoryEntry>[
        entry('b', 'Clean oven', LocalDate(2026, 1, 2), 1),
        entry('a', 'Check oven', LocalDate(2026, 1, 2), 2),
        entry('c', 'Inspect', LocalDate(2025, 1, 1), 2),
      ],
      HistoryFilter(
        assetId: 'a',
        roomId: 'r',
        taskText: 'oven',
        completedFrom: LocalDate(2026, 1, 1),
      ),
    );
    expect(result.map((HistoryEntry value) => value.completion.id), <String>[
      'a',
      'b',
    ]);
    expect(
      filterHistory(
        result,
        const HistoryFilter(status: HistoryStatus.corrected),
      ).single.completion.id,
      'a',
    );
    expect(
      filterHistory(
        result,
        const HistoryFilter(status: HistoryStatus.completed),
      ).single.completion.id,
      'b',
    );
  });
}
