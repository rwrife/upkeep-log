import 'package:flutter/services.dart';
import 'package:upkeep_log/application/data_portability.dart';

const MethodChannel _channel = MethodChannel('upkeep_log/data_transfer');

final class PlatformDataTransfer implements DataTransfer {
  const PlatformDataTransfer();

  @override
  Future<TransferResult> exportFile({
    required String suggestedName,
    required String mediaType,
    required Uint8List bytes,
  }) async {
    final String? path = await _channel.invokeMethod<String>('export', {
      'suggestedName': suggestedName,
      'mediaType': mediaType,
      'bytes': bytes,
    });
    return path == null
        ? const TransferResult(TransferStatus.cancelled)
        : TransferResult(TransferStatus.completed, path: path);
  }

  @override
  Future<TransferResult> importBackup() async {
    final String? path = await _channel.invokeMethod<String>('import');
    return path == null
        ? const TransferResult(TransferStatus.cancelled)
        : TransferResult(TransferStatus.completed, path: path);
  }
}
