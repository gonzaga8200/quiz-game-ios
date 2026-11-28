#!/usr/bin/env bash
# Renders the app icon (light, dark and tinted) from the app's PocketWatch into the asset catalog.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
source "$here/../scripts/env.sh"
out="$REPO_ROOT/App/Resources/Assets.xcassets/AppIcon.appiconset"
TEST_RUNNER_RENDER_APP_ICON="$out" xcodebuild test -quiet \
  -project "$REPO_ROOT/Contrarreloj.xcodeproj" -scheme Contrarreloj \
  -destination "$(destination "$IPHONE")" -derivedDataPath "$DERIVED" \
  -only-testing:ContrarrelojTests/RenderAppIcon
ls -la "$out"/icon-*.png
