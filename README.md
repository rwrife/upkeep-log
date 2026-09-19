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

Open `ios/Runner.xcodeproj` in Xcode 16 or newer, select the `Runner` scheme and
an iPhone simulator, then build or test.

From a macOS command line:

```sh
xcodebuild \
  -project ios/Runner.xcodeproj \
  -scheme Runner \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  clean test
```

Release signing and App Store publication require owner-managed Apple
credentials.

## License

MIT. See [LICENSE](LICENSE).
