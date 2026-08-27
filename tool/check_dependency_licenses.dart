import 'dart:convert';
import 'dart:io';

const Set<String> _licenseNames = <String>{
  'COPYING',
  'LICENSE',
  'LICENSE.md',
  'LICENSE.txt',
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
      failures.add('$name: no license file in package/SDK roots');
      continue;
    }

    final List<String> licenseTexts = <String>[];
    for (final File license in licenses) {
      licenseTexts.add(await license.readAsString());
    }
    final Set<String>? approvedLicenses = approvedLicenseIds(
      name,
      licenseTexts,
    );
    if (approvedLicenses == null) {
      failures.add(
        '$name: one or more license files are outside the approved set',
      );
      continue;
    }

    final List<String> sortedLicenses = approvedLicenses.toList()..sort();
    final List<String> licenseFiles = licenses
        .map((File license) => _basename(license.path))
        .toList()
      ..sort();
    final String summary = licenseTexts
        .expand((String text) => text.split(RegExp(r'\r?\n')))
        .map((String line) => line.trim())
        .firstWhere(
          (String line) => line.isNotEmpty,
          orElse: () => 'license text',
        );
    report.add(
      '$name\t${sortedLicenses.join('+')}\t${licenseFiles.join('+')}\t$summary',
    );
  }

  report.sort();
  final File output = File(arguments.last);
  output.parent.createSync(recursive: true);
  await output.writeAsString(
    <String>[
      'Upkeep Log dependency license inventory',
      'Approved set: Apache-2.0, BSD, MIT, Flutter SDK composite',
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

/// Returns all approved identifiers, or null when any license is denied/unknown.
Set<String>? approvedLicenseIds(
  String packageName,
  Iterable<String> licenseTexts,
) {
  final Set<String> approved = <String>{};
  for (final String text in licenseTexts) {
    final String? identifier = approvedLicenseId(packageName, text);
    if (identifier == null) {
      return null;
    }
    approved.add(identifier);
  }
  return approved.isEmpty ? null : approved;
}

/// Returns the approved license identifier, or null for denied/unknown text.
String? approvedLicenseId(String packageName, String text) {
  final String normalized = text.toUpperCase();
  const List<String> deniedMarkers = <String>[
    'GNU AFFERO GENERAL PUBLIC LICENSE',
    'GNU GENERAL PUBLIC LICENSE',
    'GNU LESSER GENERAL PUBLIC LICENSE',
    'MOZILLA PUBLIC LICENSE',
    'COMMON DEVELOPMENT AND DISTRIBUTION LICENSE',
    'ECLIPSE PUBLIC LICENSE',
    'EUROPEAN UNION PUBLIC LICENCE',
  ];
  if (deniedMarkers.any(normalized.contains)) {
    return null;
  }
  if (normalized.contains('APACHE LICENSE') &&
      normalized.contains('VERSION 2.0')) {
    return 'Apache-2.0';
  }
  if (normalized.contains('PERMISSION IS HEREBY GRANTED, FREE OF CHARGE')) {
    return 'MIT';
  }
  if (normalized.contains(
    'REDISTRIBUTION AND USE IN SOURCE AND BINARY FORMS',
  )) {
    return 'BSD';
  }
  if (packageName == 'sky_engine' &&
      normalized.contains('VULKAN-VALIDATION-LAYERS')) {
    return 'Flutter-SDK-composite';
  }
  return null;
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
