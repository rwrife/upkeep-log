import 'package:flutter/services.dart';

const MethodChannel _storageChannel = MethodChannel('upkeep_log/storage');

/// Returns an app-private, durable directory without requesting file access.
Future<String> applicationSupportPath() async {
  final String? value = await _storageChannel.invokeMethod<String>(
    'getApplicationSupportPath',
  );
  if (value == null || value.trim().isEmpty) {
    throw StateError('Platform did not provide app-private storage');
  }
  return value;
}
