import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_dependency_licenses.dart';

void main() {
  test('accepts the approved permissive license families', () {
    expect(
      approvedLicenseId('example', 'Apache License\nVersion 2.0, January 2004'),
      'Apache-2.0',
    );
    expect(
      approvedLicenseId(
        'example',
        'Permission is hereby granted, free of charge, to any person',
      ),
      'MIT',
    );
    expect(
      approvedLicenseId(
        'example',
        'Redistribution and use in source and binary forms are permitted',
      ),
      'BSD',
    );
  });

  test('rejects every denied copyleft family and unknown text', () {
    const List<String> denied = <String>[
      'GNU AFFERO GENERAL PUBLIC LICENSE',
      'GNU GENERAL PUBLIC LICENSE',
      'GNU LESSER GENERAL PUBLIC LICENSE',
      'MOZILLA PUBLIC LICENSE',
      'COMMON DEVELOPMENT AND DISTRIBUTION LICENSE',
      'ECLIPSE PUBLIC LICENSE',
      'EUROPEAN UNION PUBLIC LICENCE',
    ];

    for (final String marker in denied) {
      expect(
        approvedLicenseId('example', marker),
        isNull,
        reason: '$marker must require owner review',
      );
    }
    expect(approvedLicenseId('example', 'Third-party notices only'), isNull);
  });

  test('rejects mixed permissive and denied content', () {
    expect(
      approvedLicenseId(
        'example',
        'Apache License Version 2.0\nGNU LESSER GENERAL PUBLIC LICENSE',
      ),
      isNull,
    );
    expect(
      approvedLicenseId(
        'example',
        'Permission is hereby granted, free of charge\nMOZILLA PUBLIC LICENSE',
      ),
      isNull,
    );
  });

  test('evaluates every discovered license file', () {
    expect(
      approvedLicenseIds('example', <String>[
        'Apache License Version 2.0',
        'Permission is hereby granted, free of charge',
      ]),
      <String>{'Apache-2.0', 'MIT'},
    );
    expect(
      approvedLicenseIds('example', <String>[
        'Apache License Version 2.0',
        'GNU GENERAL PUBLIC LICENSE Version 3',
      ]),
      isNull,
    );
    expect(approvedLicenseIds('example', const <String>[]), isNull);
  });

  test(
    'allows the audited Flutter engine composite license only by package',
    () {
      const String composite = 'vulkan-validation-layers\nthird party licenses';
      expect(
        approvedLicenseId('sky_engine', composite),
        'Flutter-SDK-composite',
      );
      expect(approvedLicenseId('other_package', composite), isNull);
      expect(
        approvedLicenseId(
          'sky_engine',
          '$composite\nGNU GENERAL PUBLIC LICENSE',
        ),
        isNull,
      );
    },
  );
}
