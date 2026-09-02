import 'dart:io';

const Set<String> _allowedAndroidPermissions = <String>{
  'android.permission.CAMERA',
  'android.permission.POST_NOTIFICATIONS',
  'android.permission.RECEIVE_BOOT_COMPLETED',
};

const List<String> _forbiddenDependencyMarkers = <String>[
  'firebase_',
  'amplitude_',
  'appsflyer_',
  'facebook_app_events',
  'google_mobile_ads',
  'sentry_flutter',
  'segment_analytics',
];

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2 || arguments.first != '--output') {
    stderr.writeln(
      'Usage: dart run tool/check_release_readiness.dart '
      '--output <report-path>',
    );
    exitCode = 64;
    return;
  }

  final List<String> failures = await auditReleaseReadiness(Directory.current);
  final File output = File(arguments.last);
  await output.parent.create(recursive: true);
  await output.writeAsString(
    <String>[
      '# Upkeep Log release-readiness audit',
      '',
      'Scope: static platform declarations, privacy boundaries, store metadata, '
          'and release documentation.',
      '',
      failures.isEmpty ? 'Result: PASS' : 'Result: FAIL',
      '',
      if (failures.isEmpty)
        'All ${releaseReadinessCheckCount()} checks passed.'
      else ...<String>[
        'Failures:',
        ...failures.map((String failure) => '- $failure'),
      ],
      '',
      'Manual TalkBack, VoiceOver, signing, and store-upload checks remain '
          'explicit human gates in docs/release-checklist.md.',
      '',
    ].join('\n'),
  );

  stdout.writeln(
    'Release-readiness audit: ${failures.isEmpty ? 'PASS' : 'FAIL'} '
    '(${releaseReadinessCheckCount()} checks, ${failures.length} failures).',
  );
  for (final String failure in failures) {
    stderr.writeln(failure);
  }
  if (failures.isNotEmpty) exitCode = 1;
}

int releaseReadinessCheckCount() => 17;

Future<List<String>> auditReleaseReadiness(Directory root) async {
  final List<String> failures = <String>[];

  String read(String relativePath) {
    final File file = File('${root.path}/$relativePath');
    if (!file.existsSync()) {
      failures.add('$relativePath is missing');
      return '';
    }
    return file.readAsStringSync();
  }

  void requireContains(String value, String marker, String description) {
    if (!value.contains(marker)) failures.add(description);
  }

  final String androidManifest = read(
    'android/app/src/main/AndroidManifest.xml',
  );
  final String androidDebugManifest = read(
    'android/app/src/debug/AndroidManifest.xml',
  );
  final String androidProfileManifest = read(
    'android/app/src/profile/AndroidManifest.xml',
  );
  final Set<String> permissions = RegExp(
    r'<uses-permission\s+android:name="([^"]+)"\s*/>',
  ).allMatches(androidManifest).map((Match match) => match.group(1)!).toSet();
  if (permissions.length != _allowedAndroidPermissions.length ||
      !permissions.containsAll(_allowedAndroidPermissions)) {
    failures.add(
      'Android permissions must be exactly '
      '${(_allowedAndroidPermissions.toList()..sort()).join(', ')}; found '
      '${(permissions.toList()..sort()).join(', ')}',
    );
  }
  for (final MapEntry<String, String> manifest in <String, String>{
    'main': androidManifest,
    'debug': androidDebugManifest,
    'profile': androidProfileManifest,
  }.entries) {
    if (manifest.value.contains('android.permission.INTERNET')) {
      failures.add(
        'Android ${manifest.key} manifest must not request Internet access',
      );
    }
  }
  requireContains(
    androidManifest,
    'android:label="Upkeep Log"',
    'Android application label must be Upkeep Log',
  );

  final String androidBuild = read('android/app/build.gradle.kts');
  requireContains(
    androidBuild,
    'minSdk = 29',
    'Android minimum SDK must remain 29 (Android 10)',
  );
  if (androidBuild.contains(
    'signingConfig = signingConfigs.getByName("debug")',
  )) {
    failures.add('Android release builds must not use the debug signing key');
  }

  final String infoPlist = read('ios/Runner/Info.plist');
  requireContains(
    infoPlist,
    '<key>NSCameraUsageDescription</key>',
    'iOS camera usage description is missing',
  );
  requireContains(
    infoPlist,
    '<key>NSPhotoLibraryUsageDescription</key>',
    'iOS photo-library usage description is missing',
  );
  for (final String forbiddenKey in <String>[
    'NSLocation',
    'NSMicrophone',
    'NSContacts',
    'NSUserTrackingUsageDescription',
  ]) {
    if (infoPlist.contains(forbiddenKey)) {
      failures.add('iOS declares forbidden capability $forbiddenKey');
    }
  }

  final String xcodeProject = read('ios/Runner.xcodeproj/project.pbxproj');
  requireContains(
    xcodeProject,
    'IPHONEOS_DEPLOYMENT_TARGET = 16.0;',
    'iOS deployment target must remain 16.0',
  );
  requireContains(
    xcodeProject,
    'PrivacyInfo.xcprivacy in Resources',
    'PrivacyInfo.xcprivacy must be bundled in the iOS target',
  );

  final String privacyManifest = read('ios/Runner/PrivacyInfo.xcprivacy');
  for (final String marker in <String>[
    '<key>NSPrivacyTracking</key>',
    '<false/>',
    '<key>NSPrivacyTrackingDomains</key>',
    '<key>NSPrivacyCollectedDataTypes</key>',
    '<key>NSPrivacyAccessedAPITypes</key>',
  ]) {
    requireContains(
      privacyManifest,
      marker,
      'iOS privacy manifest is missing $marker',
    );
  }

  final String pubspec = read('pubspec.yaml').toLowerCase();
  for (final String marker in _forbiddenDependencyMarkers) {
    if (pubspec.contains(marker)) {
      failures.add(
        'Forbidden analytics/advertising dependency marker: $marker',
      );
    }
  }

  final List<String> requiredDocuments = <String>[
    'THIRD_PARTY_NOTICES.md',
    'docs/release-checklist.md',
    'docs/release-notes-template.md',
    'docs/store-listing.md',
    'docs/store-assets/README.md',
    'assets/branding/upkeep-log-icon.svg',
  ];
  for (final String path in requiredDocuments) {
    read(path);
  }

  for (final String placeholder in <String>[
    'docs/store-assets/android-phone-placeholder.svg',
    'docs/store-assets/ios-phone-placeholder.svg',
  ]) {
    final String contents = read(placeholder);
    requireContains(
      contents,
      'PLACEHOLDER — NOT A PRODUCT SCREENSHOT',
      '$placeholder must be visibly marked as a non-product placeholder',
    );
  }

  final List<String> launcherIcons = <String>[
    for (final String density in <String>[
      'mdpi',
      'hdpi',
      'xhdpi',
      'xxhdpi',
      'xxxhdpi',
    ])
      'android/app/src/main/res/mipmap-$density/ic_launcher.png',
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
        'Icon-App-1024x1024@1x.png',
  ];
  for (final String path in launcherIcons) {
    final File file = File('${root.path}/$path');
    if (!file.existsSync() || file.lengthSync() < 256) {
      failures.add('$path is missing or not a usable launcher icon');
    }
  }

  return failures;
}
