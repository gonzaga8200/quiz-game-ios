#!/usr/bin/env bash
# Screenshots of every flow on iPhone and iPad, light and dark, plus the game at the largest
# accessibility text size, into docs/verification/screenshots (UITests/Verification/ScreenshotTour),
# as half-size JPEGs.
#   scripts/screenshots.sh [iphone|ipad …]      default: both
set -euo pipefail
source "$(dirname "$0")/env.sh"
out="$REPO_ROOT/docs/verification/screenshots"
mkdir -p "$out"
devices=("$@")
[ ${#devices[@]} -gt 0 ] || devices=(iphone ipad)
for kind in "${devices[@]}"; do
  case "$kind" in
    iphone) name="$IPHONE" ;;
    ipad) name="$IPAD" ;;
    *) echo "unknown device $kind" >&2; exit 2 ;;
  esac
  udid=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
d = json.load(sys.stdin)['devices']
print(next(x['udid'] for rt, xs in d.items() if rt.endswith('iOS-${IOS_VERSION//./-}') for x in xs if x['name'] == '''$name'''))")
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
  # Fixed status bar, like App Store screenshots.
  xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
  for appearance in light dark; do
    xcrun simctl ui "$udid" appearance "$appearance"
    tests=(-only-testing:ContrarrelojUITests/ScreenshotTour/testTour)
    [ "$appearance" = light ] && tests+=(-only-testing:ContrarrelojUITests/ScreenshotTour/testGameAtLargestText)
    TEST_RUNNER_SCREENSHOTS_DIR="$out" TEST_RUNNER_SCREENSHOTS_PREFIX="$kind-$appearance-" \
      xcodebuild test -quiet -project "$REPO_ROOT/Contrarreloj.xcodeproj" -scheme Contrarreloj \
      -destination "id=$udid" -derivedDataPath "$DERIVED" "${tests[@]}"
  done
  xcrun simctl ui "$udid" appearance light
  xcrun simctl status_bar "$udid" clear
done
# Half resolution, JPEG: enough to review text and colours without bloating the repository.
for f in "$out"/*.png; do
  [ -e "$f" ] || continue
  w=$(sips -g pixelWidth "$f" | awk '/pixelWidth/{print $2}')
  h=$(sips -g pixelHeight "$f" | awk '/pixelHeight/{print $2}')
  sips -Z $(( (w > h ? w : h) / 2 )) "$f" >/dev/null
  sips -s format jpeg -s formatOptions 80 "$f" --out "${f%.png}.jpg" >/dev/null && rm "$f"
done
ls "$out" | wc -l | xargs echo "screenshots:"
