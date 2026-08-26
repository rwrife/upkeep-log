import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('source imports respect architecture boundaries', () {
    final List<String> violations = <String>[];

    for (final FileSystemEntity entity in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final String path = entity.path.replaceAll('\\', '/');
      final String source = entity.readAsStringSync();
      final Iterable<String> imports = RegExp(
        "^import ['\"]([^'\"]+)['\"]",
        multiLine: true,
      ).allMatches(source).map((RegExpMatch match) => match.group(1)!);

      for (final String import in imports) {
        if (path.startsWith('lib/domain/') &&
            (import.startsWith('package:flutter') ||
                _importsLayer(import, 'application') ||
                _importsLayer(import, 'adapters') ||
                _importsLayer(import, 'presentation'))) {
          violations.add('$path must not import $import');
        }

        if (path.startsWith('lib/application/') &&
            (import.startsWith('package:flutter') ||
                _importsLayer(import, 'adapters') ||
                _importsLayer(import, 'presentation'))) {
          violations.add('$path must not import $import');
        }

        if (path.startsWith('lib/adapters/') &&
            _importsLayer(import, 'presentation')) {
          violations.add('$path must not import $import');
        }

        if (path.startsWith('lib/presentation/') &&
            _importsLayer(import, 'adapters')) {
          violations.add('$path must not import $import');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}

bool _importsLayer(String import, String layer) {
  return import.startsWith('package:upkeep_log/$layer/');
}
