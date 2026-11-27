#!/usr/bin/env bash
# Writes Config/Secrets.xcconfig (git-ignored) from Config/GoogleService-Info.plist.
set -euo pipefail
source "$(dirname "$0")/env.sh"
plist="$REPO_ROOT/Config/GoogleService-Info.plist"
[ -f "$plist" ] || { echo "missing $plist (see README > Firebase)" >&2; exit 1; }
reversed=$(/usr/libexec/PlistBuddy -c "Print :REVERSED_CLIENT_ID" "$plist")
existing="$REPO_ROOT/Config/Secrets.xcconfig"
apple_line=""
if [ -f "$existing" ]; then apple_line=$(grep -E '^ENABLE_APPLE_SIGN_IN' "$existing" || true); fi
{
  echo "// Written by scripts/make-secrets.sh. Git-ignored."
  echo "GOOGLE_REVERSED_CLIENT_ID = $reversed"
  if [ -n "$apple_line" ]; then echo "$apple_line"; fi
} > "$existing"
echo "wrote $existing"
