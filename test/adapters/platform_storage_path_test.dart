import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upkeep_log/adapters/platform_storage_path.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('upkeep_log/storage');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads the app-private support path from the platform', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          expect(call.method, 'getApplicationSupportPath');
          return '/private/upkeep';
        });

    expect(await applicationSupportPath(), '/private/upkeep');
  });

  test('fails closed when the platform returns no private path', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async => '');

    await expectLater(applicationSupportPath(), throwsStateError);
  });
}
