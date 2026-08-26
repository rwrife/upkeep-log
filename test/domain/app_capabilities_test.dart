import 'package:flutter_test/flutter_test.dart';
import 'package:upkeep_log/domain/app_capabilities.dart';

void main() {
  test('MVP capabilities preserve local-first product boundaries', () {
    expect(AppCapabilities.storesDataLocally, isTrue);
    expect(AppCapabilities.requiresAccount, isFalse);
    expect(AppCapabilities.requiresNetwork, isFalse);
    expect(AppCapabilities.includesTracking, isFalse);
  });
}
