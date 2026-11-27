#!/usr/bin/env bash
# App unit tests on the iPhone simulator. Optional arguments narrow the run:
#   scripts/test-app.sh ContrarrelojTests/QuestionBankTests
set -euo pipefail
source "$(dirname "$0")/env.sh"
only=()
if [ $# -eq 0 ]; then only=(-only-testing:ContrarrelojTests); else for t in "$@"; do only+=("-only-testing:$t"); done; fi
bundle="$DERIVED/results/app-$(date +%Y%m%d-%H%M%S).xcresult"
mkdir -p "$DERIVED/results"
set +e
xcodebuild test -quiet \
  -resultBundlePath "$bundle" \
  -project "$REPO_ROOT/Contrarreloj.xcodeproj" -scheme Contrarreloj \
  -destination "$(destination "$IPHONE")" -derivedDataPath "$DERIVED" \
  "${only[@]}"
rc=$?
set -e
"$REPO_ROOT/scripts/summarize-results.sh" "$bundle"
exit $rc
