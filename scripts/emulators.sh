#!/usr/bin/env bash
# Firebase Auth and Firestore emulators with the web's own firebase.json and security rules, taken
# from the web repository (../quiz-game, or WEB_REPO) at WEB_RULES_REF (default origin/main).
#
#   scripts/emulators.sh                 start them and leave them running (Ctrl-C to stop)
#   scripts/emulators.sh <command…>      start them, run the command, stop them (its exit code)
#
# Needs the web repository's npm dependencies (firebase-tools) and Java 21.
set -euo pipefail
source "$(dirname "$0")/env.sh"
WEB="${WEB_REPO:-$REPO_ROOT/../quiz-game}"
REF="${WEB_RULES_REF:-origin/main}"
FIREBASE="$WEB/node_modules/firebase-tools/lib/bin/firebase.js"
[ -f "$FIREBASE" ] || { echo "firebase-tools not found: run npm install in $WEB" >&2; exit 1; }
# firebase-tools needs Java 21 or newer; JAVA21_HOME overrides the Homebrew one.
export JAVA_HOME="${JAVA21_HOME:-/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home}"
export PATH="$JAVA_HOME/bin:$PATH"

dir="$(mktemp -d)"
trap 'rm -rf "$dir"' EXIT
if [ "$REF" = "origin/main" ]; then git -C "$WEB" fetch -q origin main; fi
for f in firebase.json firestore.rules firestore.indexes.json; do
  git -C "$WEB" show "$REF:$f" > "$dir/$f"
done
echo "emulators with the rules of $REF ($(git -C "$WEB" rev-parse --short "$REF"))" >&2
cd "$dir"
if [ $# -eq 0 ]; then
  node "$FIREBASE" emulators:start --only auth,firestore --project demo-contrarreloj
else
  node "$FIREBASE" emulators:exec --only auth,firestore --project demo-contrarreloj "$(printf '%q ' "$@")"
fi
