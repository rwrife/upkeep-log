import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upkeep_log/adapters/platform_attachment_picker.dart';
import 'package:upkeep_log/application/attachment_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('upkeep_log/attachments');
  const PlatformAttachmentPicker picker = PlatformAttachmentPicker();

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  for (final String code in <String>['permission_denied', 'cancelled']) {
    test('$code returns no picked record', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => throw PlatformException(code: code),
          );
      expect(await picker.pick(AttachmentSource.camera), isNull);
    });
  }

  test('successful payload carries explicit temporary ownership', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => <String, Object>{
            'path': '/tmp/pick.jpg',
            'mediaType': 'image/jpeg',
            'ownedTemporary': true,
          },
        );
    final PickedAttachment value = (await picker.pick(
      AttachmentSource.camera,
    ))!;
    expect(value.ownedTemporary, isTrue);
  });

  test('other platform failures propagate', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(code: 'picker_busy'),
        );
    await expectLater(
      picker.pick(AttachmentSource.document),
      throwsA(
        isA<PlatformException>().having((e) => e.code, 'code', 'picker_busy'),
      ),
    );
  });
}
