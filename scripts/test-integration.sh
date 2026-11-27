#!/usr/bin/env bash
# Integration tests: the app's ranking and account deletion code against the Firebase emulators
# running the web's security rules (see scripts/emulators.sh). Optional arguments narrow the run:
#   scripts/test-integration.sh ContrarrelojIntegrationTests/EmulatorTests
set -euo pipefail
source "$(dirname "$0")/env.sh"
only=()
for t in "$@"; do only+=("-only-testing:$t"); done
bundle="$DERIVED/results/integration-$(date +%Y%m%d-%H%M%S).xcresult"
mkdir -p "$DERIVED/results"
set +e
"$REPO_ROOT/scripts/emulators.sh" xcodebuild test -quiet \
  -resultBundlePath "$bundle" \
  -project "$REPO_ROOT/Contrarreloj.xcodeproj" -scheme ContrarrelojIntegrationTests \
  -destination "$(destination "$IPHONE")" -derivedDataPath "$DERIVED" \
  ${only[@]+"${only[@]}"}
rc=$?
set -e
summary=$("$REPO_ROOT/scripts/summarize-results.sh" "$bundle")
echo "$summary"
if [ "$rc" -eq 0 ] && echo "$summary" | grep -q "total 0,"; then
  echo "no test ran" >&2
  rc=1
fi
exit $rc
