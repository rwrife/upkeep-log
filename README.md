# Upkeep Log

Upkeep Log is a private, local-first household maintenance journal for iPhone.
It schedules recurring upkeep and records completed work without accounts,
analytics, advertising, or cloud services.

## Features

- Multiple home profiles, rooms, assets, and upkeep tasks
- One-time, daily, weekly, monthly, and yearly schedules
- Due, overdue, snoozed, upcoming, and completed views
- Append-only completion history with notes, parts, and cost
- Optional local notifications
- User-directed JSON backup and restore
- Light and dark mode, Dynamic Type, and VoiceOver-friendly controls

All app data is stored in the app's private Application Support directory.
Notification permission is requested only after a user enables a task reminder.

## Supported platform

- iPhone running iOS 16 or newer

iPad, Android, macOS, web, and Catalyst are not supported.

## Technology

The app is implemented entirely in native Swift and SwiftUI. It uses Foundation
for local JSON persistence and UserNotifications for optional reminders. It has
no third-party runtime dependencies.

## Development

Open `ios/UpkeepLog.xcodeproj` in Xcode 16 or newer, select the `UpkeepLog` scheme and
an iPhone simulator, then build or test.

From a macOS command line:

```sh
xcodebuild \
  -project ios/UpkeepLog.xcodeproj \
  -scheme UpkeepLog \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  clean test
```

If `xcodebuild` reports that only Command Line Tools are selected, prefix the
command with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
Choose an installed simulator name from `xcrun simctl list devices available`.

The shared `UpkeepLog` scheme includes the app and its XCTest target. App sources
and resources live in `ios/UpkeepLog`; there is no Flutter, CocoaPods, or package
installation step.

## 6.5-inch screenshots

Six native simulator captures are committed in
[`screenshots/iphone-6.5`](screenshots/iphone-6.5): welcome, due, upcoming,
completed, setup, and privacy/data. Each PNG is **1242 × 2688** pixels, captured
at native resolution on iPhone 11 Pro Max in portrait orientation.

Regenerate them on a Mac with Xcode and an installed iOS simulator runtime:

```sh
./scripts/capture-screenshots.sh
```

The script builds Debug, creates a disposable simulator, seeds fictional home
maintenance data, captures the screens, checks pixel dimensions, and removes
that simulator. It requires Python 3. Set `UPKEEP_SIM_RUNTIME` to select a
specific installed runtime identifier. The tab-selection environment hook is
compiled only into Debug builds; sample data is supplied by the capture script,
not bundled in the production app.

Release signing and App Store publication require owner-managed Apple
credentials.

## License

MIT. See [LICENSE](LICENSE).
