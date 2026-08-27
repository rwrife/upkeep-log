import 'package:flutter_test/flutter_test.dart';
import 'package:upkeep_log/domain/domain.dart';

void main() {
  group('value objects', () {
    test('LocalDate is date-only, validated, ordered, and ISO formatted', () {
      final LocalDate leapDay = LocalDate(2024, 2, 29);

      expect(leapDay.toIso8601String(), '2024-02-29');
      expect(LocalDate.parse('2024-02-29'), leapDay);
      expect(leapDay.addDays(1), LocalDate(2024, 3, 1));
      expect(() => LocalDate(2023, 2, 29), throwsArgumentError);
      expect(() => LocalDate.parse('2024-2-29'), throwsFormatException);
    });

    test('money and reminder intent enforce storage invariants', () {
      expect(Money(minorUnits: 1299, currency: 'USD').minorUnits, 1299);
      expect(() => Money(minorUnits: 1, currency: 'usd'), throwsArgumentError);
      expect(
        ReminderIntent(
          hour: 9,
          minute: 30,
          timeZoneId: 'Europe/London',
        ).timeZoneId,
        'Europe/London',
      );
      expect(
        () => ReminderIntent(hour: 24, minute: 0, timeZoneId: 'UTC'),
        throwsArgumentError,
      );
    });
  });

  test(
    'entities validate identifiers, references, attachment metadata, and dates',
    () {
      final HomeProfile home = HomeProfile(id: 'home-1', name: 'Flat');
      final Room room = Room(id: 'room-1', homeId: home.id, name: 'Kitchen');
      final Asset asset = Asset(
        id: 'asset-1',
        homeId: home.id,
        roomId: room.id,
        name: 'Boiler',
      );
      final TaskTemplate task = TaskTemplate(
        id: 'task-1',
        homeId: home.id,
        roomId: room.id,
        assetId: asset.id,
        name: 'Inspect boiler',
        startDate: LocalDate(2026, 1, 31),
        recurrence: MonthlyRecurrence(),
      );
      expect(
        () => TaskTemplate(
          id: 'bad-anchor',
          homeId: home.id,
          name: 'Invalid yearly anchor',
          startDate: LocalDate(2026, 1, 1),
          recurrence: YearlyRecurrence(),
          recurrenceAnchorDay: 31,
          recurrenceAnchorMonth: 4,
        ),
        throwsArgumentError,
      );
      final TaskOccurrence occurrence = TaskOccurrence(
        id: 'occ-1',
        taskTemplateId: task.id,
        scheduledDate: LocalDate(2026, 1, 31),
        snoozedUntil: LocalDate(2026, 2, 2),
      );
      expect(
        () => TaskOccurrence(
          id: 'bad',
          taskTemplateId: task.id,
          scheduledDate: LocalDate(2026, 2, 2),
          snoozedUntil: LocalDate(2026, 2, 1),
        ),
        throwsArgumentError,
      );
      final Completion completion = Completion(
        id: 'completion-1',
        occurrenceId: occurrence.id,
        scheduledDate: occurrence.scheduledDate,
        actualDate: LocalDate(2026, 2, 1),
        cost: Money(minorUnits: 5000, currency: 'GBP'),
        revision: 1,
        revisedAtUtc: DateTime.utc(2026, 2, 1, 12),
      );
      final AttachmentMetadata attachment = AttachmentMetadata(
        id: 'attachment-1',
        completionId: completion.id,
        relativePath: 'attachments/receipt.jpg',
        mediaType: 'image/jpeg',
        sha256: 'a' * 64,
      );

      expect(attachment.relativePath, 'attachments/receipt.jpg');
      expect(() => HomeProfile(id: '', name: 'Home'), throwsArgumentError);
      expect(() => HomeProfile(id: 'id', name: '  '), throwsArgumentError);
      expect(
        () => AttachmentMetadata(
          id: 'a',
          completionId: 'c',
          relativePath: '../secret',
          mediaType: 'text/plain',
          sha256: 'bad',
        ),
        throwsArgumentError,
      );
      expect(
        () => AttachmentMetadata(
          id: 'windows-path',
          completionId: 'c',
          relativePath: r'C:\secret.txt',
          mediaType: 'text/plain',
          sha256: 'a' * 64,
        ),
        throwsArgumentError,
      );
      expect(
        () => Completion(
          id: 'c',
          occurrenceId: 'o',
          scheduledDate: LocalDate(2026, 1, 2),
          actualDate: LocalDate(2026, 1, 1),
          revision: 0,
          revisedAtUtc: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
    },
  );
}
