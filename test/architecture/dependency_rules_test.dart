import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('source imports and exports respect architecture boundaries', () {
    final List<String> violations = <String>[];

    for (final FileSystemEntity entity in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final String path = entity.path.replaceAll('\\', '/');
      final String source = entity.readAsStringSync();
      for (final String target in _directiveUris(source)) {
        if (path.startsWith('lib/domain/') &&
            (target.startsWith('package:flutter') ||
                _targetsLayer(path, target, 'application') ||
                _targetsLayer(path, target, 'adapters') ||
                _targetsLayer(path, target, 'presentation'))) {
          violations.add('$path must not target $target');
        }

        if (path.startsWith('lib/application/') &&
            (target.startsWith('package:flutter') ||
                target == 'dart:io' ||
                _targetsLayer(path, target, 'adapters') ||
                _targetsLayer(path, target, 'presentation'))) {
          violations.add('$path must not target $target');
        }

        if (path.startsWith('lib/adapters/') &&
            _targetsLayer(path, target, 'presentation')) {
          violations.add('$path must not target $target');
        }

        if (path.startsWith('lib/presentation/') &&
            _targetsLayer(path, target, 'adapters')) {
          violations.add('$path must not target $target');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('relative and package directives resolve to their target layers', () {
    expect(
      _targetsLayer(
        'lib/presentation/view.dart',
        '../adapters/database.dart',
        'adapters',
      ),
      isTrue,
    );
    expect(
      _targetsLayer(
        'lib/domain/task.dart',
        'package:upkeep_log/application/service.dart',
        'application',
      ),
      isTrue,
    );
    expect(
      _targetsLayer('lib/domain/task.dart', '../domain/date.dart', 'adapters'),
      isFalse,
    );
  });

  test('extracts exports and every conditional directive target', () {
    const String source = '''
export '../application/service.dart';
import 'stub.dart'
  if (dart.library.io) '../adapters/io.dart'
  if (dart.library.html) '../presentation/web.dart';
''';

    expect(_directiveUris(source), <String>[
      '../application/service.dart',
      'stub.dart',
      '../adapters/io.dart',
      '../presentation/web.dart',
    ]);
  });
}

List<String> _directiveUris(String source) {
  final RegExp directive = RegExp(
    r'^(?:import|export)\s+(.+?);',
    multiLine: true,
    dotAll: true,
  );
  final RegExp uri = RegExp("['\"]([^'\"]+)['\"]");
  return directive
      .allMatches(source)
      .expand(
        (RegExpMatch match) => uri
            .allMatches(match.group(1)!)
            .map((RegExpMatch uriMatch) => uriMatch.group(1)!),
      )
      .toList(growable: false);
}

bool _targetsLayer(String sourcePath, String target, String layer) {
  if (target.startsWith('package:upkeep_log/$layer/')) {
    return true;
  }
  if (target.startsWith('dart:') || target.startsWith('package:')) {
    return false;
  }

  final String targetPath = File(sourcePath).absolute.uri
      .resolve(target)
      .toFilePath()
      .replaceAll('\\', '/');
  return targetPath.contains('/lib/$layer/');
}
