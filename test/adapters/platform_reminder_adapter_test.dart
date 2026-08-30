import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upkeep_log/adapters/platform_reminder_adapter.dart';
import 'package:upkeep_log/application/reminder_coordinator.dart';
import 'package:upkeep_log/domain/domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('upkeep_log/reminders');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'permission is queried and requested only through explicit methods',
    () async {
      final List<String> calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            calls.add(call.method);
            return call.method == 'getPermissionStatus'
                ? 'notDetermined'
                : 'denied';
          });
      const PlatformReminderAdapter adapter = PlatformReminderAdapter();

      expect(
        await adapter.permissionStatus(),
        ReminderPermission.notDetermined,
      );
      expect(calls, <String>['getPermissionStatus']);
      expect(await adapter.requestPermission(), ReminderPermission.denied);
      expect(calls, <String>['getPermissionStatus', 'requestPermission']);
    },
  );

  test(
    'replaceAll sends date and timezone intent and decodes limitations',
    () async {
      MethodCall? received;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            received = call;
            return <String, Object>{
              'scheduledCount': 1,
              'limitation': 'Delivery may be delayed by battery policy.',
            };
          });
      const PlatformReminderAdapter adapter = PlatformReminderAdapter();

      final ReminderDeliveryReport result = await adapter.replaceAll(
        <ReminderScheduleRequest>[
          ReminderScheduleRequest(
            id: 'occurrence-1',
            taskName: 'Replace filter',
            date: LocalDate(2026, 11, 1),
            intent: ReminderIntent(
              hour: 1,
              minute: 30,
              timeZoneId: 'America/New_York',
            ),
          ),
        ],
      );

      expect(received!.method, 'replaceAll');
      expect(received!.arguments, <String, Object>{
        'reminders': <Map<String, Object>>[
          <String, Object>{
            'id': 'occurrence-1',
            'title': 'Replace filter',
            'year': 2026,
            'month': 11,
            'day': 1,
            'hour': 1,
            'minute': 30,
            'timeZoneId': 'America/New_York',
          },
        ],
      });
      expect(result.scheduledCount, 1);
      expect(result.limitation, contains('battery policy'));
    },
  );

  test(
    'reads the native IANA time-zone identifier without permission',
    () async {
      final List<String> calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            calls.add(call.method);
            return 'America/New_York';
          });

      expect(
        await const PlatformReminderAdapter().currentTimeZoneId(),
        'America/New_York',
      );
      expect(calls, <String>['getTimeZoneId']);
    },
  );

  test('opens the operating-system notification settings', () async {
    final List<String> calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call.method);
          return null;
        });

    await const PlatformReminderAdapter().openSettings();

    expect(calls, <String>['openSettings']);
  });
}
