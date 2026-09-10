# Third-party notices

Upkeep Log is licensed under the repository's MIT license. It also uses Flutter,
Dart packages, Android libraries, and Apple system frameworks.

The authoritative dependency notice inventory for a build is generated from the
resolved, locked package roots rather than copied by hand:

```text
flutter pub get --enforce-lockfile
dart run tool/check_dependency_licenses.dart --output build/reports/dependency-licenses.txt
```

The command fails closed when a resolved package has no discoverable license or
uses a license family outside the repository's reviewed permissive set. GitHub
Actions attaches the resulting `dependency-licenses.txt` to every green quality
and platform artifact so recipients can review the notices that correspond to
the exact lockfile and Flutter SDK used for that build.

Direct Dart packages in the current application are `archive`, `crypto`,
`drift`, and `sqlite3`, plus the Flutter SDK. Transitive packages and native
build dependencies are enumerated by the generated reports and Gradle dependency
verification metadata. Do not treat this summary as a substitute for the full
artifact inventory.
