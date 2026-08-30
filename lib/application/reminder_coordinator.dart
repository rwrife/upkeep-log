import 'package:upkeep_log/domain/domain.dart';

import 'upkeep_repository.dart';

/// Current notification authorization reported by the operating system.
enum ReminderPermission { notDetermined, denied, granted, unsupported }

/// One pending occurrence translated from durable task intent for an OS adapter.
final class ReminderScheduleRequest {
  const ReminderScheduleRequest({
    required this.id,
    required this.taskName,
    required this.date,
    required this.intent,
  });

  final String id;
  final String taskName;
  final LocalDate date;
  final ReminderIntent intent;
}

/// Result of replacing the app's pending platform notifications.
final class ReminderDeliveryReport {
  const ReminderDeliveryReport({
    required this.scheduledCount,
    required this.limitation,
  });

  final int scheduledCount;
  final String limitation;
}

/// Narrow port for local notifications. Implementations must not use a network.
abstract interface class ReminderAdapter {
  Future<String> currentTimeZoneId();
  Future<ReminderPermission> permissionStatus();
  Future<ReminderPermission> requestPermission();
  Future<ReminderDeliveryReport> replaceAll(
    List<ReminderScheduleRequest> requests,
  );
  Future<void> openSettings();
}

/// User-visible status from the latest best-effort reconciliation.
final class ReminderStatus {
  const ReminderStatus({
    required this.permission,
    required this.scheduledCount,
    required this.message,
    required this.updatedAtUtc,
  });

  final ReminderPermission permission;
  final int scheduledCount;
  final String message;
  final DateTime updatedAtUtc;
}

/// Derives disposable OS notifications from the persisted task/occurrence truth.
///
/// Failures are reported through [status] and never roll back local task data.
final class ReminderCoordinator {
  ReminderCoordinator({
    required this.repository,
    required this.adapter,
    required this.clock,
  });

  final UpkeepRepository repository;
  final ReminderAdapter adapter;
  final Clock clock;
  ReminderStatus? _status;

  ReminderStatus? get status => _status;

  Future<ReminderStatus> reconcile({bool requestPermission = false}) async {
    ReminderPermission permission = ReminderPermission.notDetermined;
    try {
      permission = await adapter.permissionStatus();
      if (requestPermission && permission != ReminderPermission.granted) {
        permission = await adapter.requestPermission();
      }

      final List<ReminderScheduleRequest> desired =
          permission == ReminderPermission.granted
          ? await _desiredRequests()
          : const <ReminderScheduleRequest>[];
      final ReminderDeliveryReport report = await adapter.replaceAll(desired);
      final String message = switch (permission) {
        ReminderPermission.granted =>
          '${report.scheduledCount} local reminder${report.scheduledCount == 1 ? '' : 's'} scheduled. '
              '${report.limitation} Reminders are convenience aids, not safety alerts.',
        ReminderPermission.denied =>
          'Notifications are denied. Due lists still work without reminders; '
              'use system settings if you want to allow them later.',
        ReminderPermission.notDetermined => 'Reminders are off. Due lists still work; permission is requested only when you enable a reminder.',
        ReminderPermission.unsupported => 'Local notifications are unavailable on this platform. Due lists still work.',
      };
      return _status = ReminderStatus(
        permission: permission,
        scheduledCount: report.scheduledCount,
        message: message,
        updatedAtUtc: clock.nowUtc,
      );
    } catch (error) {
      return _status = ReminderStatus(
        permission: permission,
        scheduledCount: 0,
        message:
            'Local reminder scheduling failed: $error. Due lists and saved upkeep remain available.',
        updatedAtUtc: clock.nowUtc,
      );
    }
  }

  Future<void> openSettings() => adapter.openSettings();

  Future<String> currentTimeZoneId() async {
    try {
      final String value = (await adapter.currentTimeZoneId()).trim();
      return value.isEmpty ? clock.timeZoneId : value;
    } catch (_) {
      return clock.timeZoneId;
    }
  }

  Future<List<ReminderScheduleRequest>> _desiredRequests() async {
    final List<TaskTemplate> tasks = await repository.tasks();
    final Map<String, TaskTemplate> byId = <String, TaskTemplate>{
      for (final TaskTemplate task in tasks) task.id: task,
    };
    final List<ReminderScheduleRequest> result = <ReminderScheduleRequest>[];
    for (final TaskOccurrence occurrence in await repository.occurrences()) {
      final TaskTemplate? task = byId[occurrence.taskTemplateId];
      if (task == null ||
          task.paused ||
          task.reminder == null ||
          occurrence.state != OccurrenceState.pending) {
        continue;
      }
      result.add(
        ReminderScheduleRequest(
          id: occurrence.id,
          taskName: task.name,
          date: occurrence.visibleDate,
          intent: task.reminder!,
        ),
      );
    }
    result.sort((a, b) => a.id.compareTo(b.id));
    return result;
  }
}
