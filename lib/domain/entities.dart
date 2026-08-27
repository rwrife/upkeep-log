import 'local_date.dart';
import 'recurrence.dart';
import 'value_objects.dart';

String _required(String value, String field) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, field, 'Must not be empty');
  }
  return value;
}

/// A local household data boundary.
final class HomeProfile {
  HomeProfile({required String id, required String name, this.addressLabel})
    : id = _required(id, 'id'),
      name = _required(name, 'name');
  final String id;
  final String name;
  final String? addressLabel;
}

/// An optional organizational area belonging to one home.
final class Room {
  Room({required String id, required String homeId, required String name})
    : id = _required(id, 'id'),
      homeId = _required(homeId, 'homeId'),
      name = _required(name, 'name');
  final String id;
  final String homeId;
  final String name;
}

/// A maintainable item belonging to a home and optionally a room.
final class Asset {
  Asset({
    required String id,
    required String homeId,
    required String name,
    this.roomId,
  }) : id = _required(id, 'id'),
       homeId = _required(homeId, 'homeId'),
       name = _required(name, 'name') {
    if (roomId != null) _required(roomId!, 'roomId');
  }
  final String id;
  final String homeId;
  final String? roomId;
  final String name;
}

/// Immutable scheduling definition; references are checked by repositories.
final class TaskTemplate {
  TaskTemplate({
    required String id,
    required String homeId,
    required String name,
    required this.startDate,
    required this.recurrence,
    this.roomId,
    this.assetId,
    this.reminder,
    this.paused = false,
    int? recurrenceAnchorDay,
    int? recurrenceAnchorMonth,
  }) : id = _required(id, 'id'),
       homeId = _required(homeId, 'homeId'),
       name = _required(name, 'name'),
       recurrenceAnchorDay = recurrenceAnchorDay ?? startDate.day,
       recurrenceAnchorMonth = recurrenceAnchorMonth ?? startDate.month {
    if (roomId != null) _required(roomId!, 'roomId');
    if (assetId != null) _required(assetId!, 'assetId');
    try {
      // A leap-year reference admits February 29 while rejecting impossible
      // month/day pairs such as April 31.
      LocalDate(2024, this.recurrenceAnchorMonth, this.recurrenceAnchorDay);
    } on ArgumentError {
      throw ArgumentError('Invalid recurrence calendar anchor');
    }
  }
  final String id;
  final String homeId;
  final String? roomId;
  final String? assetId;
  final String name;
  final LocalDate startDate;
  final RecurrencePolicy recurrence;
  final ReminderIntent? reminder;
  final bool paused;
  final int recurrenceAnchorDay;
  final int recurrenceAnchorMonth;
}

enum OccurrenceState { pending, completed }

/// A durable scheduled date. Snooze affects visibility, never recurrence math.
final class TaskOccurrence {
  TaskOccurrence({
    required String id,
    required String taskTemplateId,
    required this.scheduledDate,
    this.snoozedUntil,
    this.state = OccurrenceState.pending,
  }) : id = _required(id, 'id'),
       taskTemplateId = _required(taskTemplateId, 'taskTemplateId') {
    if (snoozedUntil != null && snoozedUntil! < scheduledDate) {
      throw ArgumentError.value(
        snoozedUntil,
        'snoozedUntil',
        'Must not precede scheduledDate',
      );
    }
  }
  final String id;
  final String taskTemplateId;
  final LocalDate scheduledDate;
  final LocalDate? snoozedUntil;
  final OccurrenceState state;
  LocalDate get visibleDate => snoozedUntil ?? scheduledDate;
}

/// A completion revision. Corrections append a larger [revision] row.
final class Completion {
  Completion({
    required String id,
    required String occurrenceId,
    required this.scheduledDate,
    required this.actualDate,
    required this.revision,
    required DateTime revisedAtUtc,
    this.notes,
    this.cost,
  }) : id = _required(id, 'id'),
       occurrenceId = _required(occurrenceId, 'occurrenceId'),
       revisedAtUtc = revisedAtUtc.toUtc() {
    if (revision < 1) {
      throw ArgumentError.value(revision, 'revision', 'Must be positive');
    }
  }
  final String id;
  final String occurrenceId;
  final LocalDate scheduledDate;
  final LocalDate actualDate;
  final String? notes;
  final Money? cost;
  final int revision;
  final DateTime revisedAtUtc;
}

/// Metadata for a file inside app-private storage; paths can never escape it.
final class AttachmentMetadata {
  AttachmentMetadata({
    required String id,
    required String completionId,
    required String relativePath,
    required String mediaType,
    required String sha256,
    this.caption,
  }) : id = _required(id, 'id'),
       completionId = _required(completionId, 'completionId'),
       relativePath = _path(relativePath),
       mediaType = _required(mediaType, 'mediaType'),
       sha256 = _hash(sha256);
  final String id;
  final String completionId;
  final String relativePath;
  final String mediaType;
  final String sha256;
  final String? caption;
  static String _path(String value) {
    if (value.startsWith('/') ||
        value.startsWith('\\') ||
        RegExp(r'^[A-Za-z]:[/\\]').hasMatch(value) ||
        value.split(RegExp(r'[/\\]')).contains('..')) {
      throw ArgumentError.value(value, 'relativePath', 'Must be app-relative');
    }
    return _required(value, 'relativePath');
  }

  static String _hash(String value) {
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
      throw ArgumentError.value(value, 'sha256', 'Expected lowercase SHA-256');
    }
    return value;
  }
}
