import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upkeep_log/adapters/platform_data_transfer.dart';
import 'package:upkeep_log/application/data_portability.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('upkeep_log/data_transfer');

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('export and import cancellation are explicit and graceful', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
    const transfer = PlatformDataTransfer();
    expect(
      (await transfer.exportFile(
        suggestedName: 'x.csv',
        mediaType: 'text/csv',
        bytes: Uint8List(0),
      )).status,
      TransferStatus.cancelled,
    );
    expect((await transfer.importBackup()).status, TransferStatus.cancelled);
  });

  test('platform low-storage failures remain failures', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => throw PlatformException(
            code: 'low_storage',
            message: 'Not enough space',
          ),
        );
    await expectLater(
      const PlatformDataTransfer().exportFile(
        suggestedName: 'x.zip',
        mediaType: 'application/zip',
        bytes: Uint8List(16),
      ),
      throwsA(isA<PlatformException>()),
    );
  });
}
