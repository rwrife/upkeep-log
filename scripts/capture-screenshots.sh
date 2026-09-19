#!/bin/bash
# Capture unscaled 1242 × 2688 PNGs on a disposable iPhone 11 Pro Max.
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
runtime="${UPKEEP_SIM_RUNTIME:-$(xcrun simctl list runtimes -j | python3 -c 'import json,sys; print(next(r["identifier"] for r in reversed(json.load(sys.stdin)["runtimes"]) if r["isAvailable"] and r["name"].startswith("iOS")))')}"
output="$PWD/screenshots/iphone-6.5"
work="$(mktemp -d /tmp/upkeep-screenshots.XXXXXX)"
device="$(xcrun simctl create 'Upkeep Log Screenshot Capture' com.apple.CoreSimulator.SimDeviceType.iPhone-11-Pro-Max "$runtime")"
cleanup() {
  xcrun simctl shutdown "$device" >/dev/null 2>&1 || true
  xcrun simctl delete "$device" >/dev/null 2>&1 || true
  rm -rf "$work"
}
trap cleanup EXIT
mkdir -p "$output"
xcodebuild -project ios/UpkeepLog.xcodeproj -scheme UpkeepLog -configuration Debug \
  -destination "platform=iOS Simulator,id=$device" -derivedDataPath "$work/build" \
  CODE_SIGNING_ALLOWED=NO build > "$work/build.log" 2>&1 || { cat "$work/build.log"; exit 1; }
xcrun simctl boot "$device"
xcrun simctl bootstatus "$device" -b
xcrun simctl ui "$device" appearance light
xcrun simctl status_bar "$device" override --time '9:41' --dataNetwork wifi \
  --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100
xcrun simctl install "$device" "$work/build/Build/Products/Debug-iphonesimulator/UpkeepLog.app"
bundle=com.rwrife.upkeeplog
capture() {
  SIMCTL_CHILD_UPKEEP_SCREENSHOT_TAB="$1" xcrun simctl launch "$device" "$bundle" -AppleLanguages '(en)' -AppleLocale en_US
  # Allow launch animation and first-boot notification banners to settle.
  sleep 12
  xcrun simctl io "$device" screenshot "$output/$2.png"
  xcrun simctl terminate "$device" "$bundle"
}
container="$(xcrun simctl get_app_container "$device" "$bundle" data)"
python3 scripts/screenshot-fixture.py "$container"
capture 0 02-due
capture 1 03-upcoming
capture 2 04-completed
capture 3 05-setup
capture 4 06-privacy-data
# Capture onboarding last so first-boot system banners have time to disappear.
rm "$container/Library/Application Support/upkeep-log.json"
capture 0 01-welcome
python3 - "$output" <<'PY'
import pathlib, struct, sys
for path in sorted(pathlib.Path(sys.argv[1]).glob('*.png')):
    width, height = struct.unpack('>II', path.read_bytes()[16:24])
    assert (width, height) == (1242, 2688), (path, width, height)
    print(f'{path.name}: {width} x {height}')
PY
