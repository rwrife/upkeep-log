# Development release checklist

This checklist separates automated evidence from checks that require an owner,
physical device, simulator accessibility service, signing identity, or store
account. **Unchecked manual items are release blockers, not implied passes.**
Upkeep Log reminders are convenience aids, not emergency or equipment-safety
monitoring.

## Automated gate — required for every development tag

- [ ] The commit is on `main` and the GitHub Actions **CI** run is green.
- [ ] `quality-reports` contains expanded Flutter test output, coverage,
      dependency notices, and the release-readiness audit.
- [ ] The schema-v1 migration fixture, restart persistence test, reminder
      denied/granted tests, attachment-denial test, simulated low-storage test,
      and backup/restore round trip are present in the expanded report.
- [ ] `android-debug-artifact` contains the debug-signed (not release/Play-signed)
      APK, toolchain log, build log, notices, and SHA-256 manifest.
- [ ] `ios-debug-nosign-artifact` contains the no-codesign app ZIP, toolchain
      log, build log, notices, and SHA-256 manifest.
- [ ] `development-release-manifest` combines hashes from both platform jobs.
- [ ] The permission/privacy audit passes and its declarations still match the
      platform-channel code.
- [ ] The development release notes name all verification gaps and do not claim
      signing, store publication, device testing, or retained share-sheet files.

Canonical CI commands:

```text
flutter pub get --enforce-lockfile
dart run build_runner build
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage --reporter expanded
flutter test test/integration test/adapters/database_migration_test.dart test/adapters/data_portability_service_test.dart test/adapters/attachment_service_test.dart test/application/reminder_coordinator_test.dart --reporter expanded
dart run tool/check_release_readiness.dart --output build/reports/release-readiness.md
dart run tool/check_dependency_licenses.dart --output build/reports/dependency-licenses.txt
flutter build apk --debug
flutter build ios --debug --no-codesign
```

## Manual accessibility gate — pending owner/device evidence

Any PR that closes release-hardening issue #7 must remain a draft while either
platform's evidence below is pending. Do not merge it, close the issue, or create
a development tag until an owner records both real runs and confirms the checked
items. Automated semantics/widget tests are supporting evidence only.

Record tester, date, device/simulator, OS version, text-size setting, and an
evidence link for each platform. A simulator is acceptable where the assistive
technology is fully available; at least one representative physical-device pass
is required before a public store release.

### Android / TalkBack

- [ ] First-run, Setup, Due, Upcoming, Completed, and Data screens are announced
      in a logical order with TalkBack enabled.
- [ ] Every icon-only action has a meaningful name; status is conveyed by text
      or icon as well as color.
- [ ] Create/edit, complete, snooze, attach, export, restore, delete, and reset
      flows can be completed without touch exploration traps.
- [ ] Camera, notifications, and file-picker denial return focus to useful app
      content and leave core due/history behavior available.
- [ ] 200% font size and Display size Large do not clip essential content.
- [ ] Interactive targets are at least 48 logical pixels and switch/keyboard
      focus order matches reading order.
- [ ] Remove animations is respected; no task depends on motion.

Evidence: **PENDING — do not mark complete without a real run.**

### iOS / VoiceOver

- [ ] The same primary and destructive flows have logical VoiceOver labels,
      values, hints, headings, and traversal order.
- [ ] Dynamic Type at an accessibility size preserves readable, operable
      layouts without clipped essential text.
- [ ] Camera/photo/file and notification denial return focus predictably and do
      not block the local due list.
- [ ] Button targets meet 44-by-44-point guidance and hardware-keyboard focus is
      visible and ordered.
- [ ] Reduce Motion is respected; status never relies on color alone.

Evidence: **PENDING — do not mark complete without a real run.**

## Permission and privacy audit

| Platform | Declared capability | Why | Trigger |
|---|---|---|---|
| Android | `CAMERA` | Capture an attachment | Explicit **Attach → Take photo** only |
| Android | `POST_NOTIFICATIONS` | Optional local reminders on Android 13+ | Explicit reminder enable only |
| Android | `RECEIVE_BOOT_COMPLETED` | Rebuild persisted local reminder intent | OS reboot/package/time events |
| Android | app-scoped `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | AndroidX signature guard for non-exported dynamic receivers; grants no user-data capability | Generated into the merged manifest |
| iOS | Camera usage description | Capture an attachment | Explicit **Attach → Take photo** only |
| iOS | Photo-library usage description | Select one image with PHPicker | Explicit **Attach → Choose photo** only |
| iOS | Local notification authorization | Optional local reminders | Explicit reminder enable only |

No Internet, tracking, analytics, advertising, account, push, contacts, location,
microphone, Bluetooth, or broad-storage capability is declared. The AndroidX
app-scoped signature guard is not a user permission or data capability. Document
and review any future change before adding a permission.

## Owner-managed Android signing and Play delivery

1. Keep the keystore and passwords outside the repository.
2. Supply the four `UPKEEP_ANDROID_*` environment variables documented in
   `android/app/build.gradle.kts` through an owner-controlled secret store.
3. Run `flutter build appbundle --release` on the reviewed tag.
4. Verify the AAB certificate with `jarsigner -verify -verbose -certs` and record
   its SHA-256 digest.
5. Upload manually to an internal Play track, complete Data safety from
   `docs/store-listing.md`, and test install/upgrade before wider rollout.

Never commit a keystore, `key.properties`, service-account JSON, or passwords.
The CI debug APK is signed only with the standard Android debug key; it is not a
Play/release-signed artifact.

## Owner-managed iOS signing and TestFlight

1. Configure the reviewed bundle identifier and owner-controlled Apple team in
   Xcode; keep certificates, profiles, and App Store Connect keys out of git.
2. Archive the reviewed tag with Xcode using the Release configuration.
3. Run Xcode validation, inspect the merged privacy report, and record the
   archive/export hashes.
4. Upload manually to TestFlight, complete App Privacy from
   `docs/store-listing.md`, and test install/upgrade before external testing.

The CI ZIP is a no-codesign development artifact and cannot be installed as a
store build.

## Tag and GitHub development release

After the automated gate is green on the exact `main` commit:

```text
git tag -s v0.1.0-dev.1 <verified-commit>
git push origin v0.1.0-dev.1
gh release create v0.1.0-dev.1 --prerelease --verify-tag --notes-file <completed-notes> <downloaded-CI-artifacts>
```

If a signing key for Git tags is unavailable, stop and have the owner create the
tag; do not silently substitute an unsigned tag. Attach only artifacts downloaded
from the green run for the tagged commit, plus their hash manifests.
