# Flutter bootstrap and verification

## Pinned toolchain

- Flutter **3.47.1** stable, framework revision
  `6655482ec06e547f90abf8ae7590466f4415978d`
- Dart **3.13.1** (provided by Flutter)
- Official Linux x64 archive SHA-256:
  `a1d8166c0309267cb7dc99f1424eecf08b86946ad3b50723c6f59945964aea45`
- Android minimum SDK **29** (Android 10)
- iOS deployment target **16.0**

The version is recorded in `.flutter-version`, `.fvmrc`, `.metadata`, and CI.
Use the official Flutter SDK archive or FVM; do not substitute a newer channel
without updating all pins and the lockfile in a reviewed change.

## Local setup

```bash
flutter --version
flutter doctor -v
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
dart run tool/check_dependency_licenses.dart --output build/reports/dependency-licenses.txt
```

Run the app on a configured target with:

```bash
flutter run
```

Android development additionally requires a Java 17 toolchain and Android SDK.
Build the unsigned debug APK with:

```bash
flutter build apk --debug
```

The Gradle wrapper JAR, distribution checksum, and dependency verification
metadata are committed so CI verifies downloaded Gradle, plugin, and Maven
artifacts. When an intentional Android dependency change needs new checksums,
regenerate them on a supported host and review the complete XML diff before
committing:

```bash
flutter pub get --enforce-lockfile
cd android
./gradlew --write-verification-metadata sha256 assembleDebug
./gradlew --dependency-verification strict help
```

Do not regenerate verification metadata as part of a normal CI build; CI must
consume the reviewed committed checksums and fail closed on unknown artifacts.

iOS development and builds require macOS with Xcode. Build without signing with:

```bash
flutter build ios --debug --no-codesign
```

## Host limitations

Flutter 3.47.1's official Linux SDK archive is x64-only. Linux ARM64 hosts can
still edit the project, but the supported reproducible quality and platform
build evidence comes from the x64 Linux and macOS GitHub-hosted CI jobs unless a
matching official host toolchain is available. Linux cannot perform the Xcode
build, and a machine without the Android SDK cannot perform the APK build.

The app currently launches only the truthful local-first empty state. Home,
asset, task, persistence, notification, and export behavior belongs to later
issues and is not simulated by this foundation.
