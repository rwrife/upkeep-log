import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_release_readiness.dart';

void main() {
  test(
    'repository release declarations and metadata pass the fail-closed audit',
    () async {
      final List<String> failures = await auditReleaseReadiness(
        Directory.current,
      );
      expect(failures, isEmpty, reason: failures.join('\n'));
      expect(releaseReadinessCheckCount(), greaterThanOrEqualTo(17));
    },
  );

  test(
    'audit fails closed when platform and release inputs are missing',
    () async {
      final Directory empty = await Directory.systemTemp.createTemp(
        'upkeep-release-audit-',
      );
      addTearDown(() => empty.delete(recursive: true));

      final List<String> failures = await auditReleaseReadiness(empty);

      expect(failures, isNotEmpty);
      expect(
        failures,
        contains('android/app/src/main/AndroidManifest.xml is missing'),
      );
      expect(failures, contains('ios/Runner/PrivacyInfo.xcprivacy is missing'));
    },
  );
}
