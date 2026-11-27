#!/usr/bin/env bash
# UI tests on a simulator: scripts/test-ui.sh iphone|ipad [ContrarrelojUITests/SomeTests ...]
set -euo pipefail
source "$(dirname "$0")/env.sh"
case "${1:-iphone}" in
  iphone) device=$IPHONE ;;
  ipad) device=$IPAD ;;
  *) echo "usage: test-ui.sh iphone|ipad [tests...]" >&2; exit 2 ;;
esac
shift || true
only=()
if [ $# -eq 0 ]; then only=(-only-testing:ContrarrelojUITests); else for t in "$@"; do only+=("-only-testing:$t"); done; fi
bundle="$DERIVED/results/ui-$(date +%Y%m%d-%H%M%S).xcresult"
mkdir -p "$DERIVED/results"
set +e
xcodebuild test -quiet \
  -resultBundlePath "$bundle" \
  -project "$REPO_ROOT/Contrarreloj.xcodeproj" -scheme Contrarreloj \
  -destination "$(destination "$device")" -derivedDataPath "$DERIVED" \
  "${only[@]}"
rc=$?
set -e
"$REPO_ROOT/scripts/summarize-results.sh" "$bundle"
exit $rc
