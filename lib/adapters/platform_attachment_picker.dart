import 'package:flutter/services.dart';
import 'package:upkeep_log/application/attachment_service.dart';

const MethodChannel _channel = MethodChannel('upkeep_log/attachments');

final class PlatformAttachmentPicker implements AttachmentPicker {
  const PlatformAttachmentPicker();

  @override
  Future<PickedAttachment?> pick(AttachmentSource source) async {
    try {
      final Map<Object?, Object?>? value = await _channel
          .invokeMapMethod<Object?, Object?>('pick', <String, String>{
            'source': source.name,
          });
      if (value == null) return null;
      final String? path = value['path'] as String?;
      final String? mediaType = value['mediaType'] as String?;
      final bool? ownedTemporary = value['ownedTemporary'] as bool?;
      if (path == null ||
          path.isEmpty ||
          mediaType == null ||
          mediaType.isEmpty ||
          ownedTemporary == null) {
        throw StateError('Picker returned incomplete attachment data');
      }
      return PickedAttachment(
        path: path,
        mediaType: mediaType,
        ownedTemporary: ownedTemporary,
      );
    } on PlatformException catch (error) {
      if (error.code == 'cancelled' || error.code == 'permission_denied') {
        return null;
      }
      rethrow;
    }
  }
}
