import 'dart:convert';
import 'dart:io';

const Set<String> _licenseNames = <String>{
  'COPYING',
  'LICENSE',
  'LICENSE.md',
  'LICENSE.txt',
  'NOTICE',
  'NOTICE.txt',
};

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2 || arguments.first != '--output') {
    stderr.writeln(
      'Usage: dart run tool/check_dependency_licenses.dart '
      '--output <report-path>',
    );
    exitCode = 64;
    return;
  }

  final File packageConfig = File('.dart_tool/package_config.json');
  if (!packageConfig.existsSync()) {
    stderr.writeln('Run flutter pub get before checking dependency licenses.');
    exitCode = 66;
    return;
  }

  final Object? decoded = jsonDecode(await packageConfig.readAsString());
  final Map<String, Object?> root = (decoded as Map<Object?, Object?>).map(
    (Object? key, Object? value) =>
        MapEntry<String, Object?>(key! as String, value),
  );
  final List<Object?> packages = root['packages']! as List<Object?>;
  final List<String> report = <String>[];
  final List<String> failures = <String>[];

  for (final Object? packageValue in packages) {
    final Map<String, Object?> package =
        (packageValue! as Map<Object?, Object?>).map(
          (Object? key, Object? value) =>
              MapEntry<String, Object?>(key! as String, value),
        );
    final String name = package['name']! as String;
    if (name == 'upkeep_log') {
      continue;
    }

    final Uri rootUri = packageConfig.uri.resolve(
      package['rootUri']! as String,
    );
    final List<File> licenses = _findLicenses(Directory.fromUri(rootUri));
    if (licenses.isEmpty) {
      failures.add('$name: no license or notice file in package/SDK roots');
      continue;
    }

    final File license = licenses.first;
    final String text = await license.readAsString();
    final String normalized = text.toUpperCase();
    if (normalized.contains('GNU AFFERO GENERAL PUBLIC LICENSE') ||
        normalized.contains('GNU GENERAL PUBLIC LICENSE')) {
      failures.add('$name: copyleft license requires owner review');
      continue;
    }

    final String summary = text
        .split(RegExp(r'\r?\n'))
        .map((String line) => line.trim())
        .firstWhere(
          (String line) => line.isNotEmpty,
          orElse: () => 'license text',
        );
    report.add('$name\t${_basename(license.path)}\t$summary');
  }

  report.sort();
  final File output = File(arguments.last);
  output.parent.createSync(recursive: true);
  await output.writeAsString(
    <String>[
      'Upkeep Log dependency license inventory',
      'Generated from .dart_tool/package_config.json',
      '',
      ...report,
      '',
    ].join('\n'),
  );

  stdout.writeln(
    'Reviewed ${report.length + failures.length} dependency package licenses; '
    '${failures.length} require attention.',
  );
  for (final String failure in failures) {
    stderr.writeln(failure);
  }
  if (failures.isNotEmpty) {
    exitCode = 1;
  }
}

List<File> _findLicenses(Directory packageRoot) {
  Directory current = packageRoot;
  for (int depth = 0; depth <= 3; depth += 1) {
    if (current.existsSync()) {
      final List<File> licenses =
          current
              .listSync()
              .whereType<File>()
              .where(
                (File file) => _licenseNames.contains(_basename(file.path)),
              )
              .toList()
            ..sort((File left, File right) => left.path.compareTo(right.path));
      if (licenses.isNotEmpty) {
        return licenses;
      }
    }

    final Directory parent = current.parent;
    if (parent.path == current.path) {
      break;
    }
    current = parent;
  }
  return <File>[];
}

String _basename(String path) {
  return path.replaceAll('\\', '/').split('/').last;
}
