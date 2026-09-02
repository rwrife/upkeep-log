# Upkeep Log <version> — development release

Commit: `<full SHA>`

CI run: `<URL>`

Release date: `<YYYY-MM-DD>`

## What changed

- <user-visible change>

## Data compatibility

- Database schema: `<version>`
- Backup schema: `<version>`
- Migration fixtures exercised: `<list from CI>`
- Restore behavior: staged validation and pre-restore recovery copy verified by
  `<test/report link>`

## Verification evidence

- Quality report: `<artifact/link>`
- Android debug APK SHA-256: `<digest>`
- iOS no-codesign app ZIP SHA-256: `<digest>`
- Combined artifact manifest: `<artifact/link>`
- Dependency/license report: `<artifact/link>`

## Known limitations and incomplete manual gates

- Android artifact is a debug build and is not Play-signed.
- iOS artifact is built without code signing and is not a TestFlight/App Store
  package.
- TalkBack evidence: `<completed evidence or PENDING>`
- VoiceOver evidence: `<completed evidence or PENDING>`
- Physical device install/upgrade evidence: `<completed evidence or PENDING>`
- Screenshots: `<real capture links or PENDING; never call placeholders real>`
- Optional local reminders may be delayed or suppressed by the OS and are not
  safety monitoring.

## Open-source notices

See `THIRD_PARTY_NOTICES.md` and the dependency license inventory attached to the
CI run.
