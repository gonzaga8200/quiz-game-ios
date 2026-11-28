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
run_once() {
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
  summary=$("$REPO_ROOT/scripts/summarize-results.sh" "$bundle")
}
run_once
# The simulator sometimes refuses to launch the UI test runner right after another run
# ("Busy", "failed preflight checks"). Retry once for that error only; real failures stay red.
if [ "$rc" -ne 0 ] && echo "$summary" | grep -q "Failed to install or launch the test runner"; then
  echo "test runner could not launch (simulator busy); retrying once" >&2
  sleep 10
  run_once
fi
echo "$summary"
if [ "$rc" -eq 0 ] && echo "$summary" | grep -q "total 0,"; then
  echo "no test ran: check the -only-testing names (suites are Swift types)" >&2
  rc=1
fi
exit $rc
