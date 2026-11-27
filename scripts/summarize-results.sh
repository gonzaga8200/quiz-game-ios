#!/usr/bin/env bash
# Prints the totals and the failing tests of an .xcresult bundle.
set -euo pipefail
source "$(dirname "$0")/env.sh"
bundle=$1
[ -d "$bundle" ] || { echo "no result bundle at $bundle"; exit 0; }
xcrun xcresulttool get test-results summary --path "$bundle" --compact | python3 -c '
import json, sys
d = json.load(sys.stdin)
print("result: %s, total %s, passed %s, failed %s, skipped %s" % (
    d.get("result"), d.get("totalTestCount"), d.get("passedTests"), d.get("failedTests"), d.get("skippedTests")))
for f in d.get("testFailures", []):
    print("FAILED: %s — %s" % (f.get("testIdentifierString") or f.get("testName"), (f.get("failureText") or "").strip()[:300]))
'
