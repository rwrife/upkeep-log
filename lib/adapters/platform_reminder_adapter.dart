import 'package:flutter/services.dart';
import 'package:upkeep_log/application/reminder_coordinator.dart';

/// Android/iOS local-notification bridge implemented without network services.
final class PlatformReminderAdapter implements ReminderAdapter {
  const PlatformReminderAdapter();

  static const MethodChannel _channel = MethodChannel('upkeep_log/reminders');

  @override
  Future<String> currentTimeZoneId() async =>
      await _channel.invokeMethod<String>('getTimeZoneId') ?? 'UTC';

  @override
  Future<ReminderPermission> permissionStatus() async =>
      _permission(await _channel.invokeMethod<String>('getPermissionStatus'));

  @override
  Future<ReminderPermission> requestPermission() async =>
      _permission(await _channel.invokeMethod<String>('requestPermission'));

  @override
  Future<ReminderDeliveryReport> replaceAll(
    List<ReminderScheduleRequest> requests,
  ) async {
    final Map<Object?, Object?>? value = await _channel
        .invokeMapMethod<Object?, Object?>('replaceAll', <String, Object>{
          'reminders': requests
              .map(
                (ReminderScheduleRequest request) => <String, Object>{
                  'id': request.id,
                  'title': request.taskName,
                  'year': request.date.year,
                  'month': request.date.month,
                  'day': request.date.day,
                  'hour': request.intent.hour,
                  'minute': request.intent.minute,
                  'timeZoneId': request.intent.timeZoneId,
                },
              )
              .toList(growable: false),
        });
    if (value == null) {
      throw StateError('The operating system returned no scheduling result');
    }
    return ReminderDeliveryReport(
      scheduledCount: value['scheduledCount'] as int? ?? 0,
      limitation:
          value['limitation'] as String? ??
          'The operating system controls final delivery timing.',
    );
  }

  @override
  Future<void> openSettings() => _channel.invokeMethod<void>('openSettings');

  static ReminderPermission _permission(String? value) => switch (value) {
    'granted' => ReminderPermission.granted,
    'denied' => ReminderPermission.denied,
    'notDetermined' => ReminderPermission.notDetermined,
    _ => ReminderPermission.unsupported,
  };
}
